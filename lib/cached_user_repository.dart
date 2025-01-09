import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rnd_game/cached_user.dart';

class CachedUserRepository {
  // Notre box Hive pour stocker les utilisateurs
  static late Box<CachedUser> _box;

  // Instance Firestore pour plus de clarté et réutilisabilité
  static final _firestore = FirebaseFirestore.instance;
  static final _usersCollection = _firestore.collection('users');

  // Durée de validité du cache (peut être ajustée selon les besoins)
  static const cacheDuration = Duration(hours: 24);

  /// Initialise Hive et ouvre la box pour les utilisateurs.
  /// Doit être appelé au démarrage de l'application.
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      Hive.registerAdapter(CachedUserAdapter());
      _box = await Hive.openBox<CachedUser>('users');
    } catch (e) {
      // Log l'erreur et réessaye de créer une nouvelle box si nécessaire
      log('Erreur lors de l\'initialisation de Hive: $e');
      await Hive.deleteBoxFromDisk('users');
      _box = await Hive.openBox<CachedUser>('users');
    }
  }

  /// Récupère le nom d'affichage d'un utilisateur, d'abord depuis le cache,
  /// puis depuis Firestore si nécessaire.
  static Future<String> getDisplayName(String uid) async {
    try {
      // Vérification du cache
      final cached = _box.get(uid);
      if (cached != null && !cached.isExpired) {
        return cached.displayName;
      }

      // Si pas en cache ou expiré, on va chercher sur Firestore
      return await _fetchAndCacheUser(uid);
    } catch (e) {
      log('Erreur lors de la récupération du displayName: $e');
      return 'Joueur Anonyme';
    }
  }

  /// Récupère les données depuis Firestore et met à jour le cache
  static Future<String> _fetchAndCacheUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      final displayName =
          doc.data()?['displayName'] as String? ?? 'Joueur Anonyme';

      await _box.put(
        uid,
        CachedUser(
          displayName: displayName,
          timestamp: DateTime.now(),
        ),
      );

      return displayName;
    } catch (e) {
      // Si Firestore échoue, on vérifie si on a une ancienne valeur en cache
      final oldCached = _box.get(uid);
      if (oldCached != null) {
        return oldCached.displayName;
      }
      rethrow;
    }
  }

  /// Met à jour le displayName d'un utilisateur dans Firestore et le cache
  static Future<void> updateDisplayName(
      String uid, String newDisplayName) async {
    try {
      // Mise à jour Firestore
      await _usersCollection.doc(uid).update({
        'displayName': newDisplayName,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Mise à jour du cache
      await _box.put(
        uid,
        CachedUser(
          displayName: newDisplayName,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      log('Erreur lors de la mise à jour du displayName: $e');
      rethrow;
    }
  }

  /// Vide le cache pour un utilisateur spécifique
  static Future<void> invalidateCache(String uid) async {
    await _box.delete(uid);
  }

  /// Vide tout le cache (utile lors de la déconnexion)
  static Future<void> clearCache() async {
    await _box.clear();
  }

  /// Précharge les displayNames pour une liste d'UIDs
  /// Utile quand on sait qu'on va avoir besoin de plusieurs noms
  static Future<void> preloadDisplayNames(List<String> uids) async {
    try {
      // Filtrer les UIDs qui ne sont pas déjà en cache valide
      final uidsToFetch = uids.where((uid) {
        final cached = _box.get(uid);
        return cached == null || cached.isExpired;
      }).toList();

      if (uidsToFetch.isEmpty) return;

      // Récupérer tous les utilisateurs d'un coup
      final snapshot = await _usersCollection
          .where(FieldPath.documentId, whereIn: uidsToFetch)
          .get();

      // Mettre à jour le cache pour chaque utilisateur
      for (final doc in snapshot.docs) {
        final uid = doc.id;
        final displayName =
            doc.data()['displayName'] as String? ?? 'Joueur Anonyme';

        await _box.put(
          uid,
          CachedUser(
            displayName: displayName,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      log('Erreur lors du préchargement des displayNames: $e');
    }
  }
}
