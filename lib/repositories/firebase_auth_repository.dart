import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../models/user.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);
  final firebase.FirebaseAuth _auth;

  AppUser _profile(firebase.User user) => AppUser(
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    createdAt: user.metadata.creationTime,
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on firebase.FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error.code));
    }
  }

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.userChanges().map((user) => user == null ? null : _profile(user));

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      _guard(() async {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return _profile(credential.user!);
      });

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  }) => _guard(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(displayName);
    await user.reload();
    return _profile(_auth.currentUser ?? user);
  });

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase.FirebaseAuthException catch (error) {
      // Do not reveal whether an address has an account.
      if (error.code == 'user-not-found') return;
      throw AuthFailure(_messageFor(error.code));
    }
  }

  @override
  Future<AppUser> updateDisplayName(String displayName) => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Please sign in first.');
    await user.updateDisplayName(displayName);
    await user.reload();
    return _profile(_auth.currentUser ?? user);
  });

  static String _messageFor(String code) => switch (code) {
    'invalid-email' => 'Enter a valid email address.',
    'email-already-in-use' => 'This email is already registered.',
    'weak-password' => 'Choose a stronger password.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Email or password is incorrect.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    'network-request-failed' => 'Check your internet connection and try again.',
    'user-disabled' => 'This account has been disabled.',
    'requires-recent-login' => 'Please sign in again to update your profile.',
    _ => 'Authentication could not be completed. Please try again.',
  };
}
