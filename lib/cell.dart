class Cell {
  String? playerId;
  int atomCount;
  final int x;
  final int y;

  Cell({
    this.playerId,
    required this.atomCount,
    required this.x,
    required this.y,
  });

  Cell copyWith({
    String? playerId,
    int? atomCount,
    int? x,
    int? y,
  }) {
    return Cell(
      playerId: playerId ?? this.playerId,
      atomCount: atomCount ?? this.atomCount,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'atomCount': atomCount,
      'x': x,
      'y': y,
    };
  }

  static Cell fromJson(Map<String, dynamic> json) {
    return Cell(
      playerId: json['playerId'],
      atomCount: json['atomCount'],
      x: json['x'],
      y: json['y'],
    );
  }

  int get maxAmount {
    int maxAmount = 4;
    if (x == 0) maxAmount--;
    if (x == 7) maxAmount--;
    if (y == 0) maxAmount--;
    if (y == 7) maxAmount--;
    return maxAmount;
  }

  bool get isExploding => atomCount > maxAmount;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Cell &&
        other.playerId == playerId &&
        other.atomCount == atomCount &&
        other.x == x &&
        other.y == y;
  }

  @override
  int get hashCode {
    return playerId.hashCode ^ atomCount.hashCode ^ x.hashCode ^ y.hashCode;
  }
}
