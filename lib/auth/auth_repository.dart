import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  static FutureOr<String?> getCurrentUsername() async {
    return _auth.currentUser?.displayName;
  }

  static Future<void> updateDisplayName(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
    await _auth.currentUser?.reload();
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  static Future<String?> getDisplayName(String uid) async {
    _firestore.collection('users').doc(uid).get().then((doc) {
      return doc['displayName'];
    });
    return null;
  }

  static Future<DateTime?> getLastConnection(String uid) async {
    _firestore.collection('users').doc(uid).get().then((doc) {
      return doc['lastConnection'];
    });
    return null;
  }

  static Future<void> setLastConnection(DateTime lastConnection) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _firestore.collection('users').doc(uid).update(
        {
          'lastConnection': lastConnection,
        },
      );
    }
  }
}
