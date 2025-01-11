import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/exploding_atoms.dart';
import 'package:rnd_game/exploding_atoms_repository.dart';

class LobbyController extends StateNotifier<AsyncValue<void>> {
  LobbyController() : super(const AsyncValue.data(null));

  Future<void> createGame(String playerId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ExplodingAtomsRepository.createLobby(playerId));
  }

  Future<String> deleteGame(String gameId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ExplodingAtomsRepository.deleteGame(gameId));
    return gameId;
  }

  Future<void> joinGame(String gameId, String playerId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ExplodingAtomsRepository.joinGame(gameId, playerId));
  }

  Future<void> leaveGame(String gameId, String playerId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ExplodingAtomsRepository.leaveGame(gameId, playerId));
  }

  Future<void> startGame(ExplodingAtoms game) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final startedGame = game.startGame();
      await ExplodingAtomsRepository.updateGame(startedGame);
    });
  }
}

final lobbyControllerProvider =
    StateNotifierProvider<LobbyController, AsyncValue<void>>((ref) {
  return LobbyController();
});
