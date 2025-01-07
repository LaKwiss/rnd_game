import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rnd_game/shared_preferences_repository.dart';

class AuthRepository {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static FutureOr<bool> login(String email, String password) async {
    final data = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    await SharedPreferencesRepository.saveUid(data.user!.uid);
    return true;
  }

  static FutureOr<bool> register(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    return true;
  }

  static FutureOr<void> logout() async {
    await _auth.signOut();
  }

  static User? get user => _auth.currentUser;

  static Stream<User?> get userChanges => _auth.authStateChanges();
}
