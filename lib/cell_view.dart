import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/cell.dart';
import 'package:rnd_game/shared_preferences_repository.dart';

class CellView extends ConsumerStatefulWidget {
  const CellView(this.cell, this.onTap, {super.key});

  final Cell cell;
  final VoidCallback onTap;

  //git test

  @override
  ConsumerState<CellView> createState() => _CellViewState();
}

class _CellViewState extends ConsumerState<CellView> {
  late bool isCurrentPlayer;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final playerId = await SharedPreferencesRepository.getUid();
      isCurrentPlayer = true;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cell = widget.cell;

    return GestureDetector(
      onTap: () {
        widget.onTap();
      },
      onLongPress: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cell Info'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Player ID: ${cell.playerId}'),
              Text('Atom Count: ${cell.atomCount}'),
              Text('X: ${cell.x}'),
              Text('Y: ${cell.y}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              border: Border.all(
                color: Colors.black,
              ),
            ),
            width: 48,
            height: 48,
            child: switch (cell.atomCount) {
              0 => const SizedBox.shrink(),
              1 => Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Dot(isCurrentPlayer),
                      ],
                    ),
                  ],
                ),
              2 => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Dot(isCurrentPlayer),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Dot(isCurrentPlayer),
                      ],
                    ),
                  ],
                ),
              3 => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Dot(isCurrentPlayer),
                        Dot(isCurrentPlayer),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Dot(isCurrentPlayer),
                      ],
                    ),
                  ],
                ),
              _ => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Dot(isCurrentPlayer),
                        Dot(isCurrentPlayer),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Dot(isCurrentPlayer),
                        Dot(isCurrentPlayer),
                      ],
                    ),
                  ],
                ),
            },
          ),
        ),
      ),
    );
  }
}

class Dot extends StatelessWidget {
  const Dot(this.isCurrentPlayer, {super.key});

  final bool isCurrentPlayer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0).copyWith(top: 2.5),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: isCurrentPlayer ? Colors.black : Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
