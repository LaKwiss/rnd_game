// exploding_atoms_stream_provider.dart
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/exploding_atoms.dart';

final explodingAtomsStreamProvider =
    StreamProvider<List<ExplodingAtoms>>((ref) {
  return FirebaseFirestore.instance
      .collection('exploding_atoms')
      .snapshots()
      .map((snapshot) {
    try {
      return snapshot.docs.map((doc) {
        // On récupère l'ID du document et on l'ajoute aux données
        final data = doc.data();
        data['id'] = doc.id; // Assurons-nous que l'ID est présent

        // On utilise un try-catch pour chaque document
        try {
          return ExplodingAtoms.fromDocument(data);
        } catch (e) {
          log('Erreur lors de la conversion du document ${doc.id}: $e');
          // On pourrait retourner un jeu "invalide" ou le filtrer plus tard
          rethrow; // ou gérer l'erreur différemment selon tes besoins
        }
      }).toList();
    } catch (e) {
      log('Erreur lors de la conversion des documents: $e');
      return <ExplodingAtoms>[]; // Retourne une liste vide en cas d'erreur
    }
  });
});
