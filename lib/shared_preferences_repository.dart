import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesRepository {
  static FutureOr<void> setUid(String uid) async {
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setString('uid', uid);
    });
  }

  static FutureOr<String?> getUid() async {
    return SharedPreferences.getInstance().then((prefs) {
      return prefs.getString('uid');
    });
  }

  static FutureOr<void> setLastConnection(DateTime lastConnection) async {
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setString('lastConnection', lastConnection.toIso8601String());
    });
  }

  static FutureOr<DateTime?> getLastConnection() async {
    return SharedPreferences.getInstance().then((prefs) {
      final lastConnection = prefs.getString('lastConnection');
      if (lastConnection != null) {
        return DateTime.parse(lastConnection);
      }
      return null;
    });
  }
}
