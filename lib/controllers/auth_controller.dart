import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../models/user.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { loading, signedOut, signedIn, guest }

class AuthController extends ChangeNotifier {
  AuthController(this.repository) {
    _subscription = repository.authStateChanges.listen(
      (user) {
        if (_disposed) return;
        currentUser = user;
        status = user == null
            ? (status == AuthStatus.guest
                  ? AuthStatus.guest
                  : AuthStatus.signedOut)
            : AuthStatus.signedIn;
        notifyListeners();
      },
      onError: (_) {
        if (_disposed) return;
        currentUser = null;
        status = AuthStatus.signedOut;
        notifyListeners();
      },
    );
  }

  final AuthRepository repository;
  late final StreamSubscription<AppUser?> _subscription;
  AuthStatus status = AuthStatus.loading;
  AppUser? currentUser;
  bool isBusy = false;
  bool showRegister = false;
  bool _disposed = false;

  void enterGuest() {
    if (status != AuthStatus.signedOut) return;
    status = AuthStatus.guest;
    notifyListeners();
  }

  void openRegister() {
    showRegister = true;
    notifyListeners();
  }

  void closeRegister() {
    showRegister = false;
    notifyListeners();
  }

  void leaveGuest() {
    if (status != AuthStatus.guest) return;
    status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<String?> _run(Future<void> Function() action) async {
    if (isBusy) return 'Please wait for the current request.';
    isBusy = true;
    notifyListeners();
    try {
      await action();
      return null;
    } on AuthFailure catch (error) {
      return error.message;
    } catch (_) {
      return 'Authentication could not be completed. Please try again.';
    } finally {
      isBusy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<String?> signIn(String email, String password) => _run(() async {
    final user = await repository.signIn(email: email, password: password);
    if (_disposed) return;
    currentUser = user;
    status = AuthStatus.signedIn;
    showRegister = false;
  });

  Future<String?> register(String email, String password, String name) =>
      _run(() async {
        final user = await repository.register(
          email: email,
          password: password,
          displayName: name,
        );
        if (_disposed) return;
        currentUser = user;
        status = AuthStatus.signedIn;
        showRegister = false;
      });

  Future<String?> sendPasswordResetEmail(String email) =>
      _run(() => repository.sendPasswordResetEmail(email));

  Future<String?> updateDisplayName(String name) => _run(() async {
    final user = await repository.updateDisplayName(name);
    if (!_disposed) currentUser = user;
  });

  Future<String?> signOut() => _run(() async {
    await repository.signOut();
    if (_disposed) return;
    currentUser = null;
    status = AuthStatus.signedOut;
    showRegister = false;
  });

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}
