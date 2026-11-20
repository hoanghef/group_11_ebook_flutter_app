import '../models/user.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<AppUser> updateDisplayName(String displayName);
}
