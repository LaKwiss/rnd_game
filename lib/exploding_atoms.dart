import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:rnd_game/auth_repository.dart';
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

  Future<String> get currentPlayerId async {
    return await AuthRepository.getUid() ?? 'Empty';
  }

  Future<ExplodingAtoms> addAtom(int x, int y) async {
    final index = x * cols + y;
    final cell = grid[index];

    cell.atomCount++;

    cell.playerId = await currentPlayerId;

    if (cell.atomCount == getMaxValue(x, y)) {
      cell.playerId = null;
      final newBoard = await explode(x, y);
      return newBoard;
    }

    // Sinon on l’incrémente
    return copyWithCell(x, y, cell);
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

  Future<ExplodingAtoms> explode(int x, int y) async {
    Cell cell = grid[x * cols + y];
    cell.atomCount = 0;

    List<Cell> neighbors = getNeighbor(x, y);

    for (Cell neighbor in neighbors) {
      neighbor.atomCount++;
      neighbor.playerId = await currentPlayerId;

      if (neighbor.atomCount == getMaxValue(neighbor.x, neighbor.y)) {
        explode(neighbor.x, neighbor.y);
      }
    }

    return this;
  }

  int getMaxValue(int x, int y) {
    if (isCorner(x, y)) {
      return 2;
    } else if (isEdge(x, y)) {
      return 3;
    } else {
      return 4;
    }
  }

  List<Cell> getNeighbor(int x, int y) {
    List<Cell> neighbors = [];
    if (y > 0) neighbors.add(grid[x * cols + y - 1]);
    if (x > 0) neighbors.add(grid[(x - 1) * cols + y]);
    if (y < 7) neighbors.add(grid[x * cols + y + 1]);
    if (x < 7) neighbors.add(grid[(x + 1) * cols + y]);

    return neighbors;
  }

  static ExplodingAtoms createEmpty({
    required String id,
    int rows = 8,
    int cols = 8,
  }) {
    return ExplodingAtoms(
      id: id,
      grid: List.generate(
        rows * cols,
        (index) => Cell(
          atomCount: 0,
          x: index ~/ cols,
          y: index % cols,
        ),
      ),
      rows: rows,
      cols: cols,
      lastPlayerId: '',
    );
  }
}
