import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
class Position extends Equatable {
  final int x;
  final int y;

  const Position({required this.x, required this.y});

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => '($x, $y)';
}
