import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/cell.dart';
import 'package:rnd_game/shared_preferences_repository.dart';

class CellView extends ConsumerStatefulWidget {
  const CellView({
    required this.cell,
    required this.onTap,
    required this.lastPlayerId,
    super.key,
  });

  final Cell cell;
  final VoidCallback onTap;
  final String lastPlayerId;

  @override
  ConsumerState<CellView> createState() => _CellViewState();
}

class _CellViewState extends ConsumerState<CellView> {
  String? currentPlayerId;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(CellView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Vérifie si les props pertinentes ont changé
    if (oldWidget.cell != widget.cell ||
        oldWidget.lastPlayerId != widget.lastPlayerId) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    final playerId = await SharedPreferencesRepository.getUid();
    if (!mounted) return;

    setState(() {
      currentPlayerId = playerId;
    });
  }

  bool get isCurrentPlayer => widget.cell.playerId == currentPlayerId;

  bool get canPlay {
    if (currentPlayerId == null) return false;

    // Si c'est le premier coup (lastPlayerId vide)
    if (widget.lastPlayerId.isEmpty) return true;

    // Si ce n'est pas notre tour (le dernier joueur est nous)
    if (widget.lastPlayerId == currentPlayerId) return false;

    // Si la cellule est vide, on peut jouer
    if (widget.cell.atomCount == 0) return true;

    // Si la cellule appartient au joueur courant
    return widget.cell.playerId == currentPlayerId;
  }

  void _showCellInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cell Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Player ID: ${widget.cell.playerId}'),
            Text('Last Player ID: ${widget.lastPlayerId}'),
            Text('Current Player ID: $currentPlayerId'),
            Text('Atom Count: ${widget.cell.atomCount}'),
            Text('Position: (${widget.cell.x}, ${widget.cell.y})'),
            Text('Can Play: $canPlay'),
            Text('Is Current Player: $isCurrentPlayer'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAtoms() {
    switch (widget.cell.atomCount) {
      case 0:
        return const SizedBox.shrink();
      case 1:
        return Center(child: _buildDot());
      case 2:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(),
            const SizedBox(width: 4),
            _buildDot(),
          ],
        );
      case 3:
        return Stack(
          children: [
            Positioned(
              left: 8,
              top: 8,
              child: _buildDot(),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: _buildDot(),
            ),
            Positioned(
              left: 16,
              bottom: 8,
              child: _buildDot(),
            ),
          ],
        );
      default:
        return Stack(
          children: [
            Positioned(
              left: 8,
              top: 8,
              child: _buildDot(),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: _buildDot(),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: _buildDot(),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: _buildDot(),
            ),
          ],
        );
    }
  }

  Widget _buildDot() {
    final color = isCurrentPlayer ? Colors.black : Colors.red;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canPlay ? widget.onTap : null,
      onLongPress: _showCellInfo,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          border: Border.all(
            color: canPlay ? Colors.black : Colors.grey,
            width: 1,
          ),
        ),
        width: 48,
        height: 48,
        child: _buildAtoms(),
      ),
    );
  }
}
