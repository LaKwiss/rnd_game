import 'package:flutter/material.dart';
import 'package:rnd_game/app_theme.dart';
import 'package:rnd_game/exploding_atoms.dart';

class StatusChip extends StatelessWidget {
  final GameStatus status;

  const StatusChip({
    super.key,
    required this.status,
  });

  // Obtenir la configuration pour chaque status
  StatusConfig get config => StatusConfig.fromStatus(status);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config.backgroundColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: 16,
            color: config.foregroundColor,
          ),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: TextStyle(
              color: config.foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusConfig {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const StatusConfig({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  factory StatusConfig.fromStatus(GameStatus status) {
    switch (status) {
      case GameStatus.waitingForPlayers:
        return StatusConfig(
          label: 'En attente',
          icon: Icons.hourglass_empty,
          backgroundColor: Colors.orange,
          foregroundColor: Colors.orange.shade900,
        );

      case GameStatus.ready:
        return StatusConfig(
          label: 'Prêt',
          icon: Icons.check_circle,
          backgroundColor: Colors.green,
          foregroundColor: Colors.green.shade900,
        );

      case GameStatus.inProgress:
        return StatusConfig(
          label: 'En cours',
          icon: Icons.play_circle,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.blue.shade900,
        );

      case GameStatus.finished:
        return StatusConfig(
          label: 'Terminée',
          icon: Icons.flag,
          backgroundColor: Colors.grey,
          foregroundColor: Colors.grey.shade900,
        );
    }
  }
}
