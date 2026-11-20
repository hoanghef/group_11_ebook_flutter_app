import '../models/user.dart';
import 'auth_repository.dart';

class UnavailableAuthRepository implements AuthRepository {
  static const failure = AuthFailure(
    'Firebase is unavailable: configuration is missing or initialization failed. Sign-in is unavailable in demo mode.',
  );

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(null);

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      Future.error(failure);

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  }) => Future.error(failure);

  @override
  Future<void> signOut() => Future.error(failure);

  @override
  Future<void> sendPasswordResetEmail(String email) => Future.error(failure);

  @override
  Future<AppUser> updateDisplayName(String displayName) =>
      Future.error(failure);
}
