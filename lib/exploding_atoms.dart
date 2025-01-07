import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:rnd_game/cell.dart';

class ExplodingAtoms extends Equatable {
  final String id;
  final List<Cell> grid;
  final int rows;
  final int cols;
  final String lastPlayerId;

  const ExplodingAtoms({
    required this.id,
    required this.grid,
    required this.rows,
    required this.cols,
    required this.lastPlayerId,
  });

  @override
  List<Object?> get props => [id, grid, rows, cols, lastPlayerId];

  ExplodingAtoms copyWith({
    String? id,
    List<Cell>? grid,
    int? rows,
    int? cols,
    String? lastPlayerId,
  }) {
    return ExplodingAtoms(
      id: id ?? this.id,
      grid: grid ?? this.grid,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      lastPlayerId: lastPlayerId ?? this.lastPlayerId,
    );
  }

  ExplodingAtoms copyWithCell(int row, int col, Cell cell) {
    final newGrid = List<Cell>.from(grid);
    newGrid[row * cols + col] = cell;
    return copyWith(grid: newGrid);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grid': grid.map((cell) => cell.toJson()).toList(),
      'rows': rows,
      'cols': cols,
      'lastPlayerId': lastPlayerId,
    };
  }

  static const ExplodingAtoms initial = ExplodingAtoms(
    id: '',
    grid: [],
    rows: 0,
    cols: 0,
    lastPlayerId: '',
  );

  static ExplodingAtoms fromDocument(Map<String, dynamic> doc) {
    return ExplodingAtoms(
      id: doc['id'],
      grid: (doc['grid'] as List).map((cell) => Cell.fromJson(cell)).toList(),
      rows: doc['rows'],
      cols: doc['cols'],
      lastPlayerId: doc['lastPlayerId'],
    );
  }

  static final ExplodingAtoms random = ExplodingAtoms(
    id: 'random',
    grid: List.generate(64, (index) {
      int x = index ~/ 8;
      int y = index % 8;
      return Cell(atomCount: Random().nextInt(4), x: x, y: y);
    }),
    rows: 8,
    cols: 8,
    lastPlayerId: 'player1',
  );

  ExplodingAtoms addAtom(int x, int y) {
    final index = x * cols + y;
    final cell = grid[index];

    if (cell.atomCount == cell.maxAmount) {
      explode(x, y);
      return this;
    }
    if (isCorner(x, y) && cell.atomCount == 2) return this;
    if (isEdge(x, y) && cell.atomCount == 3) return this;

    return copyWithCell(x, y, cell.copyWith(atomCount: cell.atomCount + 1));
  }

  bool isCorner(int x, int y) {
    return (x == 0 && y == 0) ||
        (x == 0 && y == cols - 1) ||
        (x == rows - 1 && y == 0) ||
        (x == rows - 1 && y == cols - 1);
  }

  bool isEdge(int x, int y) {
    return x == 0 || y == 0 || x == rows - 1 || y == cols - 1;
  }

  ExplodingAtoms explode(int x, int y) {
    Cell cell = grid[x * cols + y];
    if (cell.isExploding) {
      cell.atomCount = 0;
      cell.playerId = null;

      List<Cell> neighbors = getNeighbor(x, y);

      for (Cell neighbor in neighbors) {
        neighbor.atomCount++;
        neighbor.playerId = cell.playerId;

        if (neighbor.isExploding) {
          explode(neighbor.x, neighbor.y);
        }
      }
    }
    return this;
  }

  List<Cell> getNeighbor(int x, int y) {
    final neighbors = <Cell>[];
    if (x > 0 && x - 1 < rows) neighbors.add(grid[(x - 1) * cols + y]);
    if (x < rows - 1 && x + 1 < rows) neighbors.add(grid[(x + 1) * cols + y]);
    if (y > 0 && y - 1 < cols) neighbors.add(grid[x * cols + y - 1]);
    if (y < cols - 1 && y + 1 < cols) neighbors.add(grid[x * cols + y + 1]);
    return neighbors;
  }

  static final empty = ExplodingAtoms(
    id: 'empty',
    grid: List.generate(64, (index) {
      int x = index ~/ 8;
      int y = index % 8;
      return Cell(atomCount: 0, x: x, y: y);
    }),
    rows: 8,
    cols: 8,
    lastPlayerId: 'player1',
  );
}
