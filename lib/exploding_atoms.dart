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

  // Méthode pour créer une copie avec des modifications
  ExplodingAtoms copyWith({
    String? id,
    List<Cell>? grid,
    int? rows,
    int? cols,
    String? lastPlayerId,
  }) {
    return ExplodingAtoms(
      id: id ?? this.id,
      grid: grid != null ? List<Cell>.from(grid) : List<Cell>.from(this.grid),
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      lastPlayerId: lastPlayerId ?? this.lastPlayerId,
    );
  }

  // Méthode pour mettre à jour une cellule spécifique
  ExplodingAtoms updateCell(int x, int y, Cell Function(Cell) update) {
    final newGrid = List<Cell>.from(grid);
    final index = x * cols + y;
    newGrid[index] = update(newGrid[index]);
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

  static ExplodingAtoms fromDocument(Map<String, dynamic> doc) {
    return ExplodingAtoms(
      id: doc['id'],
      grid: (doc['grid'] as List).map((cell) => Cell.fromJson(cell)).toList(),
      rows: doc['rows'],
      cols: doc['cols'],
      lastPlayerId: doc['lastPlayerId'],
    );
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
          playerId: null,
        ),
      ),
      rows: rows,
      cols: cols,
      lastPlayerId: '',
    );
  }

  // Récupère l'ID du joueur courant
  Future<String> get currentPlayerId async =>
      await AuthRepository.getUid() ?? 'Empty';

  // Calcule le nombre maximum d'atomes pour une position donnée
  int getMaxAtoms(int x, int y) {
    if ((x == 0 || x == rows - 1) && (y == 0 || y == cols - 1)) {
      return 2; // Coins
    }
    if (x == 0 || x == rows - 1 || y == 0 || y == cols - 1) {
      return 3; // Bords
    }
    return 4; // Centre
  }

  // Récupère les positions des cellules voisines valides
  List<({int x, int y})> getNeighborPositions(int x, int y) {
    final positions = <({int x, int y})>[];
    final directions = [(-1, 0), (1, 0), (0, -1), (0, 1)];

    for (final (dx, dy) in directions) {
      final newX = x + dx;
      final newY = y + dy;
      if (newX >= 0 && newX < rows && newY >= 0 && newY < cols) {
        positions.add((x: newX, y: newY));
      }
    }

    return positions;
  }

  // Processus d'explosion récursif avec accumulation des états
  Future<ExplodingAtoms> processExplosions(int x, int y, String playerId,
      {Set<String>? visited}) async {
    visited ??= {};
    final cellKey = '$x,$y';

    // if (visited.contains(cellKey)) {
    //   return this;
    // }

    var game = this;
    final cell = grid[x * cols + y];

    if (cell.atomCount >= getMaxAtoms(x, y)) {
      visited.add(cellKey);

      // Réinitialise la cellule qui explose
      game = game.updateCell(
          x,
          y,
          (cell) => Cell(
                atomCount: 0,
                x: x,
                y: y,
                playerId: null,
              ));

      // Traite les voisins
      final neighbors = getNeighborPositions(x, y);
      for (final neighbor in neighbors) {
        game = game.updateCell(
          neighbor.x,
          neighbor.y,
          (cell) => Cell(
            atomCount: cell.atomCount + 1,
            x: neighbor.x,
            y: neighbor.y,
            playerId: playerId,
          ),
        );

        // Vérifie récursivement les explosions des voisins
        if (game.grid[neighbor.x * game.cols + neighbor.y].atomCount >=
            game.getMaxAtoms(neighbor.x, neighbor.y)) {
          game = await game.processExplosions(
            neighbor.x,
            neighbor.y,
            playerId,
            visited: visited,
          );
        }
      }
    }

    return game.copyWith(lastPlayerId: playerId);
  }

  // Ajoute un atome à une position donnée
  Future<ExplodingAtoms> addAtom(int x, int y) async {
    final playerId = await currentPlayerId;
    final cell = grid[x * cols + y];

    // Vérifie si le joueur peut jouer sur cette cellule
    if (cell.atomCount > 0 && cell.playerId != playerId) {
      return this;
    }

    // Ajoute l'atome à la cellule
    var game = updateCell(
        x,
        y,
        (cell) => Cell(
              atomCount: cell.atomCount + 1,
              x: x,
              y: y,
              playerId: playerId,
            ));

    // Vérifie et traite les explosions si nécessaire
    if (game.grid[x * cols + y].atomCount >= game.getMaxAtoms(x, y)) {
      game = await game.processExplosions(x, y, playerId);
    }

    return game.copyWith(lastPlayerId: playerId);
  }

  // Vérifie si un joueur a gagné
  bool hasPlayerWon(String playerId) {
    return grid
        .every((cell) => cell.atomCount == 0 || cell.playerId == playerId);
  }
}
