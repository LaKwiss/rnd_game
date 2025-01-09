import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/exploding_atoms.dart';
import 'package:rnd_game/lobby/lobby_controller.dart';
import 'package:rnd_game/lobby/lobby_statuschip.dart';
import 'package:rnd_game/main.dart';

class GameCard extends ConsumerWidget {
  final ExplodingAtoms game;
  final String playerId;

  const GameCard({
    super.key,
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
        StatusChip(status: game.status),
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
