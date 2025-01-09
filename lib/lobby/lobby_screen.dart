import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:rnd_game/auth/auth_repository.dart';
import 'package:rnd_game/cached_user_repository.dart';
import 'package:rnd_game/current_player_provider.dart';
import 'package:rnd_game/exploding_atoms.dart';
import 'package:rnd_game/exploding_atoms_stream_provider.dart';
import 'package:rnd_game/lobby/lobby_controller.dart';
import 'package:rnd_game/lobby/lobby_game_card.dart';
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
        itemBuilder: (context, index) => GameCard(
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
