import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/auth_repository.dart';

final authStreamProvider = StreamProvider((ref) {
  return AuthRepository.userChanges;
});
