import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static FutureOr<bool> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
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

  static FutureOr<String?> getUid() async {
    return _auth.currentUser?.uid;
  }
}
