import 'dart:async';

import 'package:app_ebook/models/user.dart';
import 'package:app_ebook/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.currentUser});

  final _changes = StreamController<AppUser?>.broadcast();
  AppUser? currentUser;
  AuthFailure? nextFailure;
  String? resetEmail;

  void emitUser(AppUser? user) {
    currentUser = user;
    _changes.add(user);
  }

  @override
  Stream<AppUser?> get authStateChanges async* {
    yield currentUser;
    yield* _changes.stream;
  }

  void _failIfNeeded() {
    final failure = nextFailure;
    nextFailure = null;
    if (failure != null) throw failure;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    _failIfNeeded();
    currentUser = AppUser(uid: 'test-uid', email: email, displayName: 'Reader');
    _changes.add(currentUser);
    return currentUser!;
  }

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _failIfNeeded();
    currentUser = AppUser(
      uid: 'test-uid',
      email: email,
      displayName: displayName,
    );
    _changes.add(currentUser);
    return currentUser!;
  }

  @override
  Future<void> signOut() async {
    _failIfNeeded();
    currentUser = null;
    _changes.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    _failIfNeeded();
    resetEmail = email;
  }

  @override
  Future<AppUser> updateDisplayName(String displayName) async {
    _failIfNeeded();
    final user = currentUser!;
    currentUser = AppUser(
      uid: user.uid,
      email: user.email,
      displayName: displayName,
    );
    _changes.add(currentUser);
    return currentUser!;
  }

  Future<void> dispose() => _changes.close();
}
