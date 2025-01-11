import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/app_theme.dart';
import 'package:rnd_game/lobby/lobby_controller.dart';

class CreateGameButton extends ConsumerWidget {
  final String playerId;

  const CreateGameButton({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () =>
          ref.read(lobbyControllerProvider.notifier).createGame(playerId),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
      ),
      icon: const Icon(Icons.add),
      label: Text(
        'Créer une partie',
        style: AppTheme.buttonTextStyle.copyWith(
          color: AppTheme.white,
        ),
      ),
    );
  }
}
