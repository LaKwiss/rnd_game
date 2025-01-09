import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:rnd_game/auth_repository.dart';
import 'package:rnd_game/cached_user_repository.dart';
import 'package:rnd_game/current_player_provider.dart';
import 'package:rnd_game/exploding_atoms.dart';
import 'package:rnd_game/exploding_atoms_stream_provider.dart';
import 'package:rnd_game/lobby_controller.dart';
import 'package:rnd_game/main.dart';

// Le widget principal du lobby qui gère l'orchestration des différents états
class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final String? username = await AuthRepository.getCurrentUsername();
      if (username == null || username.isEmpty) {
        context.navigateToDisplayNameCreation();
      } else {
        final uid = await AuthRepository.getUid();
        if (uid != null) {
          CachedUserRepository.updateDisplayName(uid, username);
        }
      }
      log('Username: $username');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // On observe les trois providers principaux
    final playerAsync = ref.watch(currentPlayerProvider);
    final gamesAsync = ref.watch(explodingAtomsStreamProvider);
    final lobbyState = ref.watch(lobbyControllerProvider);

    // Gestion des états du joueur
    return playerAsync.when(
      loading: () => const _LoadingScreen(),
      error: (error, stack) {
        // Si l'erreur est liée à l'authentification, on redirige vers la connexion
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/');
        });
        return const _LoadingScreen();
      },
      data: (playerId) {
        // Si pas de playerId, on redirige vers la connexion
        if (playerId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/');
          });
          return const _LoadingScreen();
        }

        // Gestion des états des parties
        return gamesAsync.when(
          loading: () => const _LoadingScreen(),
          error: (error, stack) {
            log('Error: $error \n $stack');
            return _ErrorScreen(error: error);
          },
          data: (games) {
            // On filtre les parties actives
            final activeGames = games
                .where((game) => game.status != GameStatus.finished)
                .toList();

            // On affiche le contenu principal
            return _LobbyContent(
              games: activeGames,
              playerId: playerId,
              isLoading: lobbyState is AsyncLoading,
            );
          },
        );
      },
    );
  }
}

// Écran de chargement générique
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement...'),
          ],
        ),
      ),
    );
  }
}

// Écran d'erreur avec possibilité de retour
class _ErrorScreen extends StatefulWidget {
  final Object error;

  const _ErrorScreen({required this.error});

  @override
  State<_ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<_ErrorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue:\n${widget.error}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}

// Contenu principal du lobby
class _LobbyContent extends ConsumerWidget {
  final List<ExplodingAtoms> games;
  final String playerId;
  final bool isLoading;

  const _LobbyContent({
    required this.games,
    required this.playerId,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exploding Atoms - Lobby'),
        automaticallyImplyLeading: false,
        actions: [
          // Bouton de déconnexion
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
          IconButton(
            onPressed: () async {
              CachedUserRepository.clearCache();
            },
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedClean,
              color: Colors.black,
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Affichage conditionnel selon qu'il y a des parties ou non
          if (games.isEmpty)
            _EmptyLobby(playerId: playerId)
          else
            _GamesList(
              games: games,
              playerId: playerId,
              onRefresh: () => ref.invalidate(explodingAtomsStreamProvider),
            ),

          // Overlay de chargement
          if (isLoading) const _LoadingOverlay(),
        ],
      ),
      // FAB pour créer une partie
      floatingActionButton: games.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: isLoading
                  ? null
                  : () => ref
                      .read(lobbyControllerProvider.notifier)
                      .createGame(playerId),
              child: const Icon(Icons.add),
            ),
    );
  }
}

// Widget pour l'état vide du lobby
class _EmptyLobby extends StatelessWidget {
  final String playerId;

  const _EmptyLobby({required this.playerId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Aucune partie en cours',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _CreateGameButton(playerId: playerId),
        ],
      ),
    );
  }
}

// Liste des parties
class _GamesList extends StatelessWidget {
  final List<ExplodingAtoms> games;
  final String playerId;
  final VoidCallback onRefresh;

  const _GamesList({
    required this.games,
    required this.playerId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        itemCount: games.length,
        itemBuilder: (context, index) => _GameCard(
          game: games[index],
          playerId: playerId,
        ),
      ),
    );
  }
}

// Overlay de chargement semi-transparent
class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _CreateGameButton extends ConsumerWidget {
  final String playerId;

  const _CreateGameButton({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () =>
          ref.read(lobbyControllerProvider.notifier).createGame(playerId),
      icon: const Icon(Icons.add),
      label: const Text('Créer une partie'),
    );
  }
}

class _GameCard extends ConsumerWidget {
  final ExplodingAtoms game;
  final String playerId;

  const _GameCard({
    required this.game,
    required this.playerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCreator =
        game.playersIds.isNotEmpty && game.playersIds.first == playerId;
    final hasJoined = game.playersIds.contains(playerId);

    final playerStatus = switch ((isCreator, hasJoined)) {
      (true, _) => 'Votre partie',
      (false, true) => 'Partie #${game.id.substring(0, 6)} (Rejoint)',
      _ => 'Partie #${game.id.substring(0, 6)}'
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, playerStatus),
            const SizedBox(height: 12),
            _buildPlayerCount(),
            const SizedBox(height: 16),
            _buildActionButtons(context, ref, isCreator, hasJoined),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String playerStatus) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          playerStatus,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        _StatusChip(status: game.status),
      ],
    );
  }

  Widget _buildPlayerCount() {
    return Row(
      children: [
        Icon(Icons.people, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '${game.playersIds.length}/${game.maxPlayers} joueurs',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, bool isCreator, bool hasJoined) {
    if (game.isInProgress) {
      return _buildInProgressButton(context);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isCreator && game.status == GameStatus.ready)
          _buildStartButton(context, ref),
        if (!hasJoined && game.canJoin) _buildJoinButton(ref),
        if (hasJoined && !isCreator) ...[
          const SizedBox(width: 8),
          _buildLeaveButton(ref),
        ],
        if (isCreator) ...[
          const SizedBox(width: 8),
          _buildDeleteButton(ref),
        ],
      ],
    );
  }

  Widget _buildStartButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        await ref.read(lobbyControllerProvider.notifier).startGame(game);
        if (context.mounted) {
          context.navigateToGame(game.id);
        }
      },
      child: const Text('Démarrer'),
    );
  }

  Widget _buildJoinButton(WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => ref
          .read(lobbyControllerProvider.notifier)
          .joinGame(game.id, playerId),
      child: const Text('Rejoindre'),
    );
  }

  Widget _buildLeaveButton(WidgetRef ref) {
    return OutlinedButton(
      onPressed: () => ref
          .read(lobbyControllerProvider.notifier)
          .leaveGame(game.id, playerId),
      child: const Text('Quitter'),
    );
  }

  Widget _buildDeleteButton(WidgetRef ref) {
    return IconButton(
      onPressed: () =>
          ref.read(lobbyControllerProvider.notifier).deleteGame(game.id),
      icon: const Icon(Icons.delete),
      color: Colors.red,
    );
  }

  Widget _buildInProgressButton(BuildContext context) {
    final hasJoined = game.playersIds.contains(playerId);
    final buttonText = hasJoined ? 'Reprendre' : 'Observer';

    return ElevatedButton.icon(
      onPressed: () => context.navigateToGame(game.id),
      icon: const Icon(Icons.play_arrow),
      label: Text(buttonText),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final GameStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: switch (status) {
          GameStatus.waitingForPlayers => Colors.orange[100],
          GameStatus.ready => Colors.green[100],
          GameStatus.inProgress => Colors.blue[100],
          GameStatus.finished => Colors.grey[100],
        },
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        switch (status) {
          GameStatus.waitingForPlayers => 'En attente',
          GameStatus.ready => 'Prêt',
          GameStatus.inProgress => 'En cours',
          GameStatus.finished => 'Terminée',
        },
        style: TextStyle(
          color: switch (status) {
            GameStatus.waitingForPlayers => Colors.orange[900],
            GameStatus.ready => Colors.green[900],
            GameStatus.inProgress => Colors.blue[900],
            GameStatus.finished => Colors.grey[900],
          },
          fontSize: 12,
        ),
      ),
    );
  }
}
