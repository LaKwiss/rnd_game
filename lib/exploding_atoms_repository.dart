import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rnd_game/exploding_atoms.dart';

class ExplodingAtomsRepository {
  static final firebase = FirebaseFirestore.instance;

  static Future<void> sendExplodingAtoms(ExplodingAtoms game) async {
    await firebase
        .collection('exploding_atoms')
        .doc(game.id)
        .set(game.toJson())
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Upload timeout'),
        );
  }
}
