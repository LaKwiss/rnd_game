import 'package:flutter/material.dart';
import 'package:rnd_game/exploding_atoms.dart';

class StatusChip extends StatelessWidget {
  final GameStatus status;

  const StatusChip({super.key, required this.status});

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
