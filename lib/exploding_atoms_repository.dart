import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rnd_game/exploding_atoms.dart';

class ExplodingAtomsRepository {
  static final firebase = FirebaseFirestore.instance;
  static final collection = firebase.collection('exploding_atoms');

  // Version mise à jour de sendExplodingAtoms
  static Future<void> sendExplodingAtoms(ExplodingAtoms game) async {
    await collection.doc(game.id).update(game.toJson());
  }

  // Création d'une nouvelle partie / lobby
  static Future<void> createLobby(String creatorId) async {
    final game = ExplodingAtoms.createEmpty(
      creatorId: creatorId,
    );
    await collection.doc(game.id).set(game.toJson());
  }

  // Mise à jour d'une partie
  static Future<void> updateGame(ExplodingAtoms game) async {
    await collection.doc(game.id).update(game.toJson());
  }

  // Rejoindre une partie
  static Future<void> joinGame(String gameId, String playerId) async {
    final doc = await collection.doc(gameId).get();
    if (!doc.exists) return;

    final game = ExplodingAtoms.fromDocument(doc.data()!);
    final updatedGame = game.addPlayer(playerId);

    if (game != updatedGame) {
      // Ne met à jour que si le joueur a pu rejoindre
      await updateGame(updatedGame);
    }
  }

  // Quitter une partie
  static Future<void> leaveGame(String gameId, String playerId) async {
    final doc = await collection.doc(gameId).get();
    if (!doc.exists) return;

    final game = ExplodingAtoms.fromDocument(doc.data()!);

    // Si c'est le dernier joueur, supprime la partie
    if (game.playersIds.length <= 1) {
      await deleteGame(gameId);
      return;
    }

    // Si c'est le créateur, donne la possession au prochain joueur
    final updatedPlayers = List<String>.from(game.playersIds)..remove(playerId);

    final updatedGame = game.copyWith(
      playersIds: updatedPlayers,
      nextPlayerId: game.nextPlayerId == playerId
          ? updatedPlayers.first
          : game.nextPlayerId,
      status: updatedPlayers.length >= game.minPlayers
          ? GameStatus.ready
          : GameStatus.waitingForPlayers,
    );

    await updateGame(updatedGame);
  }

  // Supprimer une partie
  static Future<void> deleteGame(String gameId) async {
    await collection.doc(gameId).delete();
  }

  // Jouer un coup
  static Future<void> playMove(String gameId, int x, int y) async {
    final doc = await collection.doc(gameId).get();
    if (!doc.exists) return;

    final game = ExplodingAtoms.fromDocument(doc.data()!);
    final updatedGame = await game.addAtom(x, y);

    if (game != updatedGame) {
      // Ne met à jour que si le coup est valide
      await updateGame(updatedGame);
    }
  }

  // Méthode utilitaire pour nettoyer les parties terminées anciennes
  static Future<void> cleanupFinishedGames() async {
    final threshold = DateTime.now().subtract(const Duration(days: 1));
    final query = collection
        .where('status', isEqualTo: GameStatus.finished.name)
        .where('lastUpdateTime', isLessThan: threshold.millisecondsSinceEpoch);

    final snapshot = await query.get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Méthode pour récupérer une partie spécifique
  static Future<ExplodingAtoms?> getGame(String gameId) async {
    final doc = await collection.doc(gameId).get();
    if (!doc.exists) return null;

    return ExplodingAtoms.fromDocument(doc.data()!);
  }
}
