import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/cell.dart';

class CellView extends ConsumerStatefulWidget {
  const CellView(this.cell, this.onTap, {super.key});

  final Cell cell;
  final VoidCallback onTap;

  @override
  ConsumerState<CellView> createState() => _CellViewState();
}

class _CellViewState extends ConsumerState<CellView> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
      },
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
          child: Center(
            child: Text(
              widget.cell.atomCount.toString(),
            ),
          ),
        ),
      ),
    );
  }
}
