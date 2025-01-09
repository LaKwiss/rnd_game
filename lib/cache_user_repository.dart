import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rnd_game/cached_user.dart';

class UserCache {
  static late Box<CachedUser> _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CachedUserAdapter());
    _box = await Hive.openBox<CachedUser>('users');
  }

  static Future<String> getDisplayName(String uid) async {
    // Vérifier dans la base locale
    final cached = _box.get(uid);
    if (cached != null && !cached.isExpired) {
      return cached.displayName;
    }

    // Si pas trouvé ou expiré, requête Firestore
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final displayName =
        doc.data()?['displayName'] as String? ?? 'Joueur Anonyme';

    // Sauvegarder dans la base locale
    await _box.put(
        uid,
        CachedUser(
          displayName: displayName,
          timestamp: DateTime.now(),
        ));

    return displayName;
  }
}
