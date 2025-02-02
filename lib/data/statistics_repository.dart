import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rnd_game/auth/auth_repository.dart';

class StatisticsRepository {
  static FutureOr<void> setLastConnection(DateTime lastConnection) async {
    AuthRepository.setLastConnection(lastConnection);
    final String? uid = await AuthRepository.getUid();
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'lastConnection': lastConnection,
      });
    }
  }

  static FutureOr<DateTime?> getLastConnection() async {
    final String? uid = await AuthRepository.getUid();
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['lastConnection'] as DateTime?;
    }
    return null;
  }

  static FutureOr<void> incGamePlayed() async {
    final uid = await AuthRepository.getUid();
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'gamesPlayed': FieldValue.increment(1),
      });
    }
  }

  static FutureOr<void> incGameWon() async {
    final uid = await AuthRepository.getUid();
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'gamesWon': FieldValue.increment(1),
      });
    }
  }

  static FutureOr<void> incGameLost() async {
    final uid = await AuthRepository.getUid();
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'gamesLost': FieldValue.increment(1),
      });
    }
  }

  static FutureOr<void> incTimePlayed(Duration duration) async {
    final uid = await AuthRepository.getUid();
    log(duration.toString());
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'timePlayed': FieldValue.increment(duration.inSeconds),
    });
  }
}
