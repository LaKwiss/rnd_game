import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesRepository {
  static FutureOr<void> saveUid(String uid) async {
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setString('uid', uid);
    });
  }

  static FutureOr<String?> getUid() async {
    return SharedPreferences.getInstance().then((prefs) {
      return prefs.getString('uid');
    });
  }
}
