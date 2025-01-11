import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/app_theme.dart';
import 'package:rnd_game/cached_user_repository.dart';
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

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isCreator),
          const SizedBox(height: 16),
          _buildPlayerList(context),
          const SizedBox(height: 16),
          _buildActionButtons(context, ref, isCreator, hasJoined),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isCreator) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (isCreator)
              const Icon(
                Icons.star,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            if (isCreator) const SizedBox(width: 8),
            Text(
              isCreator ? 'Votre partie' : 'Partie #${game.id.substring(0, 6)}',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        StatusChip(status: game.status),
      ],
    );
  }

  Widget _buildPlayerList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Joueurs (${game.playersIds.length}/${game.isInProgress ? game.playersIds.length : game.maxPlayers})',
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...game.playersIds.map((id) => _buildPlayerChip(id)),
            if (!game.isInProgress)
              ...List.generate(
                game.maxPlayers - game.playersIds.length,
                (index) => _buildEmptySlot(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerChip(String id) {
    final isCurrentPlayer = id == playerId;
    final isNext = id == game.nextPlayerId;

    return FutureBuilder<String?>(
      future: CachedUserRepository.getDisplayName(id),
      builder: (context, snapshot) {
        final displayName = snapshot.data ?? 'Chargement...';

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isNext
                ? AppTheme.primaryColor.withAlpha((255 * 0.1).toInt())
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrentPlayer
                  ? AppTheme.primaryColor
                  : Colors.grey.shade300,
              width: isCurrentPlayer ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isNext)
                const Icon(
                  Icons.play_arrow,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
              if (isNext) const SizedBox(width: 4),
              Text(
                isCurrentPlayer ? 'Vous' : displayName,
                style: TextStyle(
                  color: isNext ? AppTheme.primaryColor : Colors.grey[800],
                  fontWeight: isCurrentPlayer || isNext
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[300]!,
        ),
      ),
      child: Text(
        'Libre',
        style: TextStyle(
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    bool isCreator,
    bool hasJoined,
  ) {
    if (game.isInProgress) {
      return _buildInProgressButton(context, hasJoined, isCreator, ref);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isCreator && game.status == GameStatus.ready)
          _buildButton(
            label: 'Démarrer',
            icon: Icons.play_arrow,
            color: Colors.green,
            onPressed: () async {
              await ref.read(lobbyControllerProvider.notifier).startGame(game);
              if (context.mounted) {
                context.navigateToGame(game.id);
              }
            },
          ),
        if (!hasJoined && game.canJoin)
          _buildButton(
            label: 'Rejoindre',
            icon: Icons.person_add,
            onPressed: () => ref
                .read(lobbyControllerProvider.notifier)
                .joinGame(game.id, playerId),
          ),
        if (hasJoined && !isCreator) ...[
          const SizedBox(width: 8),
          _buildButton(
            label: 'Quitter',
            icon: Icons.exit_to_app,
            color: Colors.red,
            outlined: true,
            onPressed: () => ref
                .read(lobbyControllerProvider.notifier)
                .leaveGame(game.id, playerId),
          ),
        ],
        if (isCreator) ...[
          const SizedBox(width: 8),
          _buildButton(
            label: 'Supprimer',
            icon: Icons.delete,
            color: Colors.red,
            small: true,
            onPressed: () => _showDeleteDialog(context, ref),
          ),
        ],
      ],
    );
  }

  Widget _buildInProgressButton(
      BuildContext context, bool hasJoined, bool isCreator, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildButton(
          label: hasJoined ? 'Reprendre' : 'Observer',
          icon: hasJoined ? Icons.play_arrow : Icons.visibility,
          onPressed: () => context.navigateToGame(game.id),
        ),
        if (isCreator) const SizedBox(width: 8),
        if (isCreator)
          _buildButton(
            label: 'Terminer',
            small: true,
            icon: Icons.delete_outline,
            color: Colors.red,
            outlined: true,
            onPressed: () => _showDeleteDialog(context, ref),
          ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Terminer la partie',
                    style: AppTheme.titleStyle.copyWith(
                      color: AppTheme.primaryColor,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Êtes-vous sûr de vouloir terminer cette partie ?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadius),
                        ),
                      ),
                      child: Text(
                        'Annuler',
                        style: AppTheme.buttonTextStyle.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          Navigator.of(context).pop();
                          await ref
                              .read(lobbyControllerProvider.notifier)
                              .deleteGame(game.id);
                        } finally {
                          if (context.mounted) {
                            context.navigateToLobby();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadius),
                        ),
                      ),
                      child: Text(
                        'Terminer',
                        style: AppTheme.buttonTextStyle.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    bool outlined = false,
    bool small = false,
  }) {
    final buttonColor = color ?? AppTheme.primaryColor;

    if (small) {
      return Center(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: IconButton(
            icon: Icon(icon),
            onPressed: onPressed,
            color: buttonColor,
            iconSize: 24,
          ),
        ),
      );
    }

    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          side: BorderSide(color: buttonColor),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
