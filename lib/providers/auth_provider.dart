import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/player.dart';
import 'demo_data.dart';

/// Streams the current Firebase Auth user (null when signed out).
/// Returns a null stream if Firebase is not initialized.
final firebaseAuthProvider = StreamProvider<User?>((ref) {
  try {
    return FirebaseAuth.instance.authStateChanges();
  } catch (_) {
    return Stream.value(null);
  }
});

/// Resolves the full [AppUser] from Firestore for the currently
/// authenticated user. Falls back to [DemoData.user] when there is
/// no authenticated user or when the Firestore fetch fails, ensuring
/// downstream screens always have user data available.
final appUserProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(firebaseAuthProvider);

  final firebaseUser = authState.whenOrNull(data: (user) => user);

  if (firebaseUser == null) {
    return DemoData.user;
  }

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (doc.exists) {
      return AppUser.fromFirestore(doc);
    }
    return DemoData.user;
  } catch (_) {
    return DemoData.user;
  }
});

/// Provides the current user's UID as a synchronous value.
/// Falls back to [DemoData.user.uid] when the user data is
/// loading or unavailable.
final currentUidProvider = Provider<String>((ref) {
  final appUser = ref.watch(appUserProvider);
  return appUser.whenOrNull(data: (user) => user?.uid) ?? DemoData.user.uid;
});

/// Whether the app is running in demo mode (no Firebase auth).
/// Set to true when user logs in with "demo" username.
final isDemoModeProvider = StateProvider<bool>((ref) => false);

/// Fetches the [Player] profile linked to the current [AppUser].
/// Reads `linkedPlayerId` from the resolved user, then fetches
/// the corresponding document from the `players` collection.
/// Falls back to [DemoData.player] when unavailable.
final currentPlayerProvider = FutureProvider<Player?>((ref) async {
  final appUser = ref.watch(appUserProvider).whenOrNull(data: (u) => u);

  if (appUser == null) {
    return DemoData.player;
  }

  final playerId = appUser.linkedPlayerId;
  if (playerId == null || playerId.isEmpty) {
    return DemoData.player;
  }

  try {
    final doc = await FirebaseFirestore.instance
        .collection('players')
        .doc(playerId)
        .get();

    if (doc.exists) {
      return Player.fromFirestore(doc);
    }
    return DemoData.player;
  } catch (_) {
    return DemoData.player;
  }
});
