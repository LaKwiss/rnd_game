import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/cell.dart';
import 'package:rnd_game/exploding_atoms.dart';
import 'package:rnd_game/shared_preferences_repository.dart';

class CellView extends ConsumerStatefulWidget {
  const CellView({
    required this.cell,
    required this.onTap,
    required this.game,
    super.key,
  });

  final Cell cell;
  final VoidCallback onTap;
  final ExplodingAtoms game;

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

  Future<void> _initializePlayer() async {
    final playerId = await SharedPreferencesRepository.getUid();
    if (!mounted) return;

    setState(() {
      currentPlayerId = playerId;
    });
  }

  bool _canPlayerPlay() {
    // Si le jeu n'est pas en cours, personne ne peut jouer
    if (!widget.game.isInProgress) return false;

    // Si ce n'est pas le tour du joueur, il ne peut pas jouer
    if (currentPlayerId != widget.game.nextPlayerId) return false;

    // Si la cellule est vide, le joueur peut jouer
    if (widget.cell.atomCount == 0) return true;

    // Sinon, il faut que la cellule appartienne au joueur
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
            Text('Current Player ID: $currentPlayerId'),
            Text('Next Player ID: ${widget.game.nextPlayerId}'),
            Text('Game Status: ${widget.game.status}'),
            Text('Atom Count: ${widget.cell.atomCount}'),
            Text('Position: (${widget.cell.x}, ${widget.cell.y})'),
            Text('Can Play: ${_canPlayerPlay()}'),
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

  Color _getCellColor() {
    if (!widget.game.isInProgress) {
      return Colors.grey.shade300;
    }

    if (_canPlayerPlay()) {
      return Colors.blue.shade400;
    }

    return Colors.grey.shade400;
  }

  Color _getAtomColor() {
    // Si la cellule n'appartient à personne, gris
    if (widget.cell.playerId == null) {
      return Colors.grey.shade600;
    }

    // Si la cellule appartient au joueur courant, noir
    if (widget.cell.playerId == currentPlayerId) {
      return Colors.black;
    }

    // Assigner une couleur unique par joueur
    final playerIndex = widget.game.playersIds.indexOf(widget.cell.playerId!);
    switch (playerIndex) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.yellow;
      default:
        return Colors.purple;
    }
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
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: _getAtomColor(),
        shape: BoxShape.circle,
        // Ajoute un effet de brillance si c'est le tour du joueur
        boxShadow: widget.game.nextPlayerId == widget.cell.playerId
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPlay = _canPlayerPlay();

    return GestureDetector(
      onTap: canPlay ? widget.onTap : null,
      onLongPress: _showCellInfo,
      child: Container(
        decoration: BoxDecoration(
          color: _getCellColor(),
          border: Border.all(
            color: canPlay ? Colors.black : Colors.grey.shade500,
            width: 1,
          ),
          // Ajoute un effet de surbrillance si c'est jouable
          boxShadow: canPlay
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        width: 48,
        height: 48,
        child: _buildAtoms(),
      ),
    );
  }
}
