// current_player_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/auth_controller.dart';

final currentPlayerProvider = Provider<AsyncValue<String?>>((ref) {
  return ref.watch(authControllerProvider);
});
