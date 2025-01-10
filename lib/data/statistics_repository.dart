import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rnd_game/shared_preferences_repository.dart';

class StatisticsRepository {
  static FutureOr<void> setLastConnection(DateTime lastConnection) async {
    SharedPreferencesRepository.setLastConnection(lastConnection);
    final String? uid = await SharedPreferencesRepository.getUid();
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'lastConnection': lastConnection,
      });
    }
  }

  static FutureOr<DateTime?> getLastConnection() async {
    final String? uid = await SharedPreferencesRepository.getUid();
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['lastConnection'] as DateTime?;
    }
    return null;
  }

  static FutureOr<void> incGamePlayed() async {
    final uid = await SharedPreferencesRepository.getUid();
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'gamesPlayed': FieldValue.increment(1),
      });
    }
  }

  static FutureOr<void> incGameWon() async {
    final uid = await SharedPreferencesRepository.getUid();
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'gamesWon': FieldValue.increment(1),
      });
    }
  }

  static FutureOr<void> incGameLost() async {
    final uid = await SharedPreferencesRepository.getUid();
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'gamesLost': FieldValue.increment(1),
      });
    }
  }

  static FutureOr<void> incTimePlayed(Duration timePlayed) async {
    final uid = await SharedPreferencesRepository.getUid();
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'timePlayed': FieldValue.increment(timePlayed.inSeconds),
      });
    }
  }
}
