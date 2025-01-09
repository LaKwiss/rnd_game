import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/cached_user_repository.dart';
import 'package:rnd_game/cell_view.dart';
import 'package:rnd_game/exploding_atoms.dart';
import 'package:rnd_game/exploding_atoms_repository.dart';
import 'package:rnd_game/exploding_atoms_stream_provider.dart';
import 'package:rnd_game/main.dart';
import 'package:rnd_game/shared_preferences_repository.dart';

class ExplodingAtomsView extends ConsumerStatefulWidget {
  final String gameId;

  const ExplodingAtomsView({
    required this.gameId,
    super.key,
  });

  @override
  ConsumerState<ExplodingAtomsView> createState() => _ExplodingAtomsViewState();
}

class _ExplodingAtomsViewState extends ConsumerState<ExplodingAtomsView> {
  String? currentPlayerId;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final playerId = await SharedPreferencesRepository.getUid();
    if (!mounted) return;

    setState(() {
      currentPlayerId = playerId;
    });
  }

  Widget _buildGameStatus(ExplodingAtoms game) {
    final currentPlayerTurn = game.nextPlayerId == currentPlayerId;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status du jeu
          Text(
            switch (game.status) {
              GameStatus.waitingForPlayers => 'En attente de joueurs...',
              GameStatus.ready => 'Prêt à démarrer',
              GameStatus.inProgress => currentPlayerTurn
                  ? '🎯 C\'est à vous de jouer !'
                  : '⏳ Tour de l\'adversaire',
              GameStatus.finished => '🏆 Partie terminée',
            },
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          // Liste des joueurs
          Wrap(
            spacing: 8,
            children: game.playersIds.map((playerId) {
              final isCurrentPlayer = playerId == currentPlayerId;
              final isNextPlayer = playerId == game.nextPlayerId;

              return Chip(
                label: FutureBuilder<String>(
                  future: CachedUserRepository.getDisplayName(playerId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Chargement...');
                    } else if (snapshot.hasError) {
                      return const Text('Erreur');
                    } else {
                      return Text(
                        isCurrentPlayer ? 'Vous' : snapshot.data ?? 'Inconnu',
                      );
                    }
                  },
                ),
                backgroundColor: isNextPlayer ? Colors.blue.shade100 : null,
                side: isCurrentPlayer
                    ? BorderSide(color: Colors.blue.shade300)
                    : null,
              );
            }).toList(),
          ),

          // Actions disponibles
          if (game.status == GameStatus.finished) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/lobby'),
              child: const Text('Retourner au lobby'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final explodingAtomsAsync = ref.watch(explodingAtomsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigateToLobby(),
        ),
        title: const Text('Exploding Atoms'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Règles du jeu'),
                    content: const Text(
                      '1. Chaque joueur place des atomes dans les cellules.\n'
                      '2. Lorsqu\'une cellule atteint une masse critique, elle explose et envoie des atomes dans les cellules adjacentes.\n'
                      '3. Les explosions peuvent déclencher des réactions en chaîne.\n'
                      '4. Le but est de contrôler toutes les cellules de la grille.\n'
                      '5. Le jeu se termine lorsqu\'un joueur contrôle toutes les cellules ou qu\'il ne reste plus de mouvements possibles.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fermer'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: explodingAtomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
        data: (games) {
          final game = games.firstWhereOrNull((g) => g.id == widget.gameId);

          // Si le jeu n'existe pas, on affiche un message et on propose de retourner au lobby
          if (game == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Cette partie n\'existe plus'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/lobby'),
                    child: const Text('Retour au lobby'),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGameStatus(game),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.1 * 255).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < game.rows; i++)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int j = 0; j < game.cols; j++)
                              Padding(
                                padding: const EdgeInsets.all(1),
                                child: CellView(
                                  cell: game.grid[i * game.cols + j],
                                  game: game,
                                  onTap: () async {
                                    if (game.isInProgress &&
                                        currentPlayerId == game.nextPlayerId) {
                                      final updatedGame =
                                          await game.addAtom(i, j);
                                      await ExplodingAtomsRepository
                                          .sendExplodingAtoms(updatedGame);
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
