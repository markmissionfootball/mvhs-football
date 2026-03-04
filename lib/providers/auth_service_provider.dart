import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';
// invite.dart used via FirestoreService

// ── Result types ─────────────────────────────────────────────────

sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  final AppUser user;
  const AuthSuccess(this.user);
}

class AuthError extends AuthResult {
  final String message;
  const AuthError(this.message);
}

// ── Provider ─────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ── Service ──────────────────────────────────────────────────────

class AuthService {
  final _firestore = FirestoreService();

  /// Sign in using username + password.
  /// Looks up username → email, then calls Firebase Auth.
  Future<AuthResult> signInWithUsername(
    String username,
    String password,
  ) async {
    try {
      // Look up user by username to get their email
      final appUser = await _firestore.getUserByUsername(username.trim());
      if (appUser == null) {
        return const AuthError('Invalid username or password');
      }

      final email = appUser.email;
      if (email == null || email.isEmpty) {
        return const AuthError('No email associated with this account');
      }

      // Sign in with Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Re-fetch the user to get the latest data
      final freshUser = await _firestore.getUserByUsername(username.trim());
      return AuthSuccess(freshUser ?? appUser);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return const AuthError('Invalid username or password');
        case 'user-disabled':
          return const AuthError('This account has been disabled');
        case 'too-many-requests':
          return const AuthError('Too many attempts. Please try again later.');
        default:
          return AuthError('Sign-in failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return const AuthError('Unable to sign in. Please try again.');
    }
  }

  /// Send password reset email.
  /// Accepts either a username or an email address.
  /// Always returns success to prevent enumeration attacks.
  Future<bool> sendPasswordReset(String usernameOrEmail) async {
    try {
      String? email;

      // Try as email first (contains @)
      if (usernameOrEmail.contains('@')) {
        email = usernameOrEmail.trim().toLowerCase();
      } else {
        // Look up by username to find the email
        final user =
            await _firestore.getUserByUsername(usernameOrEmail.trim());
        email = user?.email;
      }

      if (email != null && email.isNotEmpty) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      }

      // Always return true to prevent enumeration
      return true;
    } catch (e) {
      debugPrint('Password reset error: $e');
      // Still return true — don't reveal if the email exists
      return true;
    }
  }

  /// Register a new user using an invite code.
  /// 1. Validates the invite code
  /// 2. Creates a Firebase Auth account
  /// 3. Creates the Firestore user document
  /// 4. Claims the invite
  Future<AuthResult> registerWithInvite(
    String email,
    String inviteCode,
    String password,
  ) async {
    try {
      // Step 1: Validate the invite
      final invite = await _firestore.validateInviteCode(
        email.trim(),
        inviteCode.trim(),
      );
      if (invite == null) {
        return const AuthError(
            'Invalid or expired invite code. Please contact your coach.');
      }

      // Step 2: Create Firebase Auth account
      final cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final uid = cred.user!.uid;

      // Step 3: Create Firestore user document
      final newUser = AppUser(
        uid: uid,
        username: email.trim().split('@').first,
        email: email.trim().toLowerCase(),
        role: invite.role,
        linkedPlayerId: invite.linkedPlayerId,
        linkedCoachId: invite.linkedCoachId,
        displayName: invite.displayName,
        mustChangePassword: false, // They just set their password
        mfaComplete: false,
        onboardingSurveyComplete: false,
        createdAt: DateTime.now(),
      );
      await _firestore.createUserDocument(newUser);

      // Step 4: Claim the invite
      await _firestore.claimInvite(invite.id, uid);

      return AuthSuccess(newUser);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return const AuthError(
              'An account already exists with this email.');
        case 'weak-password':
          return const AuthError(
              'Password is too weak. Use at least 8 characters.');
        default:
          return AuthError('Registration failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      return const AuthError('Registration failed. Please try again.');
    }
  }

  /// Change the current user's password.
  Future<AuthResult> changePassword(String newPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const AuthError('Not signed in');
      }

      await user.updatePassword(newPassword);

      // Mark mustChangePassword as false
      await _firestore.updateUser(user.uid, {'mustChangePassword': false});

      // Fetch updated user
      final appUser = await _firestore.getUserByEmail(user.email ?? '');
      if (appUser != null) {
        return AuthSuccess(appUser);
      }
      return const AuthError('Password updated but failed to refresh user.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return const AuthError(
            'Please sign out and sign in again before changing your password.');
      }
      return AuthError('Failed to change password: ${e.message}');
    } catch (e) {
      debugPrint('Change password error: $e');
      return const AuthError('Failed to change password. Please try again.');
    }
  }
}
