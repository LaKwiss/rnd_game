import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rnd_game/exploding_atoms.dart';

class ExplodingAtomsRepository {
  static final firebase = FirebaseFirestore.instance;
  static final collection = firebase.collection('exploding_atoms');

  static Future<void> sendExplodingAtoms(ExplodingAtoms game) async {
    // D'abord on supprime tous les jeux existants
    final snapshot = await collection.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    // Ensuite on ajoute le nouveau jeu
    await collection.add(game.toJson());
  }

  // Optionnel: Méthode dédiée pour reset
  static Future<void> resetGame(String playerId) async {
    final snapshot = await collection.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    final newGame = ExplodingAtoms.createEmpty(
      id: playerId + DateTime.now().toString(),
    );
    await collection.add(newGame.toJson());
  }
}
