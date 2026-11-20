import 'dart:async';

import 'package:app_ebook/controllers/auth_controller.dart';
import 'package:app_ebook/models/user.dart';
import 'package:app_ebook/repositories/auth_repository.dart';
import 'package:app_ebook/repositories/unavailable_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_repository.dart';

class SlowAuthRepository extends FakeAuthRepository {
  final pendingSignIn = Completer<AppUser>();
  int signInCalls = 0;

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    signInCalls++;
    return pendingSignIn.future;
  }
}

void main() {
  test('Demo auth never creates a signed-in account', () async {
    final repository = UnavailableAuthRepository();
    expect(await repository.authStateChanges.first, isNull);
    await expectLater(
      repository.signIn(email: 'demo@example.com', password: 'not-real'),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.message,
          'message',
          contains('initialization failed'),
        ),
      ),
    );
  });

  test('Auth state restores an existing session and signs out', () async {
    final repository = FakeAuthRepository(
      currentUser: const AppUser(
        uid: 'existing',
        email: 'reader@example.com',
        displayName: 'Reader',
      ),
    );
    final controller = AuthController(repository);
    addTearDown(controller.dispose);
    addTearDown(repository.dispose);

    expect(controller.status, AuthStatus.loading);
    await Future<void>.delayed(Duration.zero);
    expect(controller.status, AuthStatus.signedIn);
    expect(controller.currentUser?.uid, 'existing');

    expect(await controller.signOut(), isNull);
    expect(controller.status, AuthStatus.signedOut);
    expect(controller.currentUser, isNull);
  });

  test('Guest remains separate from an authenticated account', () async {
    final repository = FakeAuthRepository();
    final controller = AuthController(repository);
    addTearDown(controller.dispose);
    addTearDown(repository.dispose);
    await Future<void>.delayed(Duration.zero);

    controller.enterGuest();
    expect(controller.status, AuthStatus.guest);
    expect(controller.currentUser, isNull);
    controller.leaveGuest();
    expect(controller.status, AuthStatus.signedOut);
  });

  test(
    'Sign in, registration, reset and profile update use repository',
    () async {
      final repository = FakeAuthRepository();
      final controller = AuthController(repository);
      addTearDown(controller.dispose);
      addTearDown(repository.dispose);
      await Future<void>.delayed(Duration.zero);

      repository.nextFailure = const AuthFailure('Incorrect credentials');
      expect(
        await controller.signIn('reader@example.com', 'wrong'),
        'Incorrect credentials',
      );
      expect(controller.status, AuthStatus.signedOut);

      expect(
        await controller.register(
          'reader@example.com',
          'test-password',
          'Reader',
        ),
        isNull,
      );
      expect(controller.status, AuthStatus.signedIn);
      expect(controller.currentUser?.displayName, 'Reader');
      expect(await controller.updateDisplayName('New Reader'), isNull);
      expect(controller.currentUser?.displayName, 'New Reader');
      expect(
        await controller.sendPasswordResetEmail('reader@example.com'),
        isNull,
      );
      expect(repository.resetEmail, 'reader@example.com');
    },
  );

  test('Concurrent sign-in requests are rejected', () async {
    final repository = SlowAuthRepository();
    final controller = AuthController(repository);
    addTearDown(controller.dispose);
    addTearDown(repository.dispose);
    await Future<void>.delayed(Duration.zero);

    final first = controller.signIn('reader@example.com', 'test-password');
    expect(controller.isBusy, isTrue);
    expect(
      await controller.signIn('reader@example.com', 'test-password'),
      'Please wait for the current request.',
    );
    expect(repository.signInCalls, 1);
    repository.pendingSignIn.complete(
      const AppUser(
        uid: 'reader',
        email: 'reader@example.com',
        displayName: 'Reader',
      ),
    );
    expect(await first, isNull);
    expect(controller.status, AuthStatus.signedIn);
  });
}
