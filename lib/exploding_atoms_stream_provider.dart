import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/exploding_atoms.dart';

final explodingAtomsStreamProvider =
    StreamProvider<List<ExplodingAtoms>>((ref) {
  return FirebaseFirestore.instance
      .collection('exploding_atoms')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return ExplodingAtoms.fromDocument(doc.data());
    }).toList();
  });
});
