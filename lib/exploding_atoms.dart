import 'package:equatable/equatable.dart';
import 'package:rnd_game/auth_repository.dart';
import 'package:rnd_game/cell.dart';

enum GameStatus {
  waitingForPlayers, // Lobby ouvert, en attente de joueurs
  ready, // Prêt à démarrer (assez de joueurs)
  inProgress, // Partie en cours
  finished // Partie terminée
}

class ExplodingAtoms extends Equatable {
  final String id;
  final List<Cell> grid;
  final int rows;
  final int cols;
  final String lastPlayerId;
  final String nextPlayerId;
  final List<String> playersIds;
  final GameStatus status;
  final int minPlayers;
  final int maxPlayers;

  const ExplodingAtoms({
    required this.id,
    required this.grid,
    required this.rows,
    required this.cols,
    required this.lastPlayerId,
    required this.nextPlayerId,
    required this.playersIds,
    required this.status,
    this.minPlayers = 2,
    this.maxPlayers = 4,
  });

  @override
  List<Object?> get props => [
        id,
        grid,
        rows,
        cols,
        lastPlayerId,
        nextPlayerId,
        playersIds,
        status,
        minPlayers,
        maxPlayers,
      ];

  ExplodingAtoms copyWith({
    String? id,
    List<Cell>? grid,
    int? rows,
    int? cols,
    String? lastPlayerId,
    String? nextPlayerId,
    List<String>? playersIds,
    GameStatus? status,
    int? minPlayers,
    int? maxPlayers,
  }) {
    return ExplodingAtoms(
      id: id ?? this.id,
      grid: grid != null ? List<Cell>.from(grid) : List<Cell>.from(this.grid),
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      lastPlayerId: lastPlayerId ?? this.lastPlayerId,
      nextPlayerId: nextPlayerId ?? this.nextPlayerId,
      playersIds: playersIds != null
          ? List<String>.from(playersIds)
          : List<String>.from(this.playersIds),
      status: status ?? this.status,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grid': grid.map((cell) => cell.toJson()).toList(),
      'rows': rows,
      'cols': cols,
      'lastPlayerId': lastPlayerId,
      'nextPlayerId': nextPlayerId,
      'playersIds': playersIds,
      'status': status.name,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
    };
  }

  static ExplodingAtoms fromDocument(Map<String, dynamic> doc) {
    // Vérifions que tous les champs requis sont présents et valides
    return ExplodingAtoms(
      id: doc['id'] as String? ?? '', // Valeur par défaut si null
      grid: (doc['grid'] as List?)
              ?.map((cell) => Cell.fromJson(cell as Map<String, dynamic>))
              .toList() ??
          [], // Liste vide si null
      rows: doc['rows'] as int? ?? 8, // Valeur par défaut si null
      cols: doc['cols'] as int? ?? 8, // Valeur par défaut si null
      lastPlayerId:
          doc['lastPlayerId'] as String? ?? '', // Valeur par défaut si null
      nextPlayerId:
          doc['nextPlayerId'] as String? ?? '', // Valeur par défaut si null
      playersIds:
          (doc['playersIds'] as List?)?.map((e) => e as String).toList() ??
              [], // Liste vide si null
      status: GameStatus.values.firstWhere(
        (e) => e.name == (doc['status'] as String?),
        orElse: () => GameStatus.waitingForPlayers, // Valeur par défaut
      ),
      minPlayers: doc['minPlayers'] as int? ?? 2, // Valeur par défaut si null
      maxPlayers: doc['maxPlayers'] as int? ?? 4, // Valeur par défaut si null
    );
  }

  static ExplodingAtoms createEmpty({
    required String creatorId,
    int rows = 8,
    int cols = 8,
    int minPlayers = 2,
    int maxPlayers = 4,
  }) {
    return ExplodingAtoms(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
      nextPlayerId: creatorId,
      playersIds: [creatorId],
      status: GameStatus.waitingForPlayers,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
    );
  }

  // Getters utiles pour le lobby
  bool get canStart =>
      status == GameStatus.waitingForPlayers && playersIds.length >= minPlayers;

  bool get canJoin =>
      status == GameStatus.waitingForPlayers && playersIds.length < maxPlayers;

  bool get isInProgress => status == GameStatus.inProgress;

  // Actions de lobby
  ExplodingAtoms addPlayer(String playerId) {
    if (!canJoin || playersIds.contains(playerId)) return this;

    final updatedPlayers = List<String>.from(playersIds)..add(playerId);
    final newStatus = updatedPlayers.length >= minPlayers
        ? GameStatus.ready
        : GameStatus.waitingForPlayers;

    return copyWith(
      playersIds: updatedPlayers,
      status: newStatus,
    );
  }

  ExplodingAtoms startGame() {
    if (!canStart) return this;

    return copyWith(
      status: GameStatus.inProgress,
      nextPlayerId: playersIds.first,
    );
  }

  // ... Le reste de tes méthodes (getMaxAtoms, getNeighborPositions, etc) ...

  ExplodingAtoms updateCell(int x, int y, Cell Function(Cell) update) {
    final newGrid = List<Cell>.from(grid);
    final index = x * cols + y;
    newGrid[index] = update(newGrid[index]);
    return copyWith(grid: newGrid);
  }

  // Modifions addAtom pour prendre en compte les tours
  Future<ExplodingAtoms> addAtom(int x, int y) async {
    final playerId = await currentPlayerId;

    // On vérifie si c'est bien le tour du joueur
    if (playerId != nextPlayerId || !isInProgress) {
      return this;
    }

    final cell = grid[x * cols + y];
    if (cell.atomCount > 0 && cell.playerId != playerId) {
      return this;
    }

    var game = updateCell(
      x,
      y,
      (cell) => Cell(
        atomCount: cell.atomCount + 1,
        x: x,
        y: y,
        playerId: playerId,
      ),
    );

    if (game.grid[x * cols + y].atomCount >= game.getMaxAtoms(x, y)) {
      game = await game.processExplosions(x, y, playerId);
    }

    // Détermine le prochain joueur
    final currentPlayerIndex = playersIds.indexOf(playerId);
    final nextIndex = (currentPlayerIndex + 1) % playersIds.length;
    final nextPlayer = playersIds[nextIndex];

    // Vérifie si le jeu est terminé
    if (game.hasPlayerWon(playerId)) {
      return game.copyWith(
        lastPlayerId: playerId,
        status: GameStatus.finished,
      );
    }

    return game.copyWith(
      lastPlayerId: playerId,
      nextPlayerId: nextPlayer,
    );
  }

  bool hasPlayerWon(String playerId) {
    return grid
        .every((cell) => cell.atomCount == 0 || cell.playerId == playerId);
  }

  // Processus d'explosion récursif avec accumulation des états
  Future<ExplodingAtoms> processExplosions(
    int x,
    int y,
    String playerId, {
    Set<String>? visited,
  }) async {
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

    return game;
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
}
