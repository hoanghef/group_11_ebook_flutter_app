import 'dart:async';

import 'package:app_ebook/main.dart';
import 'package:app_ebook/models/user.dart';
import 'package:app_ebook/repositories/auth_repository.dart';
import 'package:app_ebook/screens/home_screen.dart';
import 'package:app_ebook/screens/login_screen.dart';
import 'package:app_ebook/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'catalog_test.dart';
import 'fake_auth_repository.dart';
import 'fake_user_library_repository.dart';

class DelayedAuthRepository extends FakeAuthRepository {
  final states = StreamController<AppUser?>();

  @override
  Stream<AppUser?> get authStateChanges => states.stream;
}

Future<void> pumpApp(WidgetTester tester, FakeAuthRepository auth) async {
  await tester.pumpWidget(
    EbookApp(
      authRepository: auth,
      catalogRepository: FakeCatalogRepository(),
      userLibraryRepository: FakeUserLibraryRepository(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Auth gate waits for the first session event', (tester) async {
    final auth = DelayedAuthRepository();
    await tester.pumpWidget(
      EbookApp(
        authRepository: auth,
        catalogRepository: FakeCatalogRepository(),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    auth.states.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await auth.states.close();
  });

  testWidgets('Restored session opens Home and can sign out', (tester) async {
    final auth = FakeAuthRepository(
      currentUser: const AppUser(
        uid: 'existing',
        email: 'reader@example.com',
        displayName: 'Reader',
      ),
    );
    await pumpApp(tester, auth);

    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('reader@example.com'), findsOneWidget);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Sign in succeeds and failure stays on login', (tester) async {
    final auth = FakeAuthRepository();
    await pumpApp(tester, auth);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'reader@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'test-password');

    auth.nextFailure = const AuthFailure('Incorrect credentials');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Incorrect credentials'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Registration handles errors and creates a session', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await pumpApp(tester, auth);
    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Reader');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'reader@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'test-password');
    await tester.enterText(find.byType(TextFormField).at(3), 'test-password');
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Register'));
    auth.nextFailure = const AuthFailure('Email already registered');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('Email already registered'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Guest can read catalog but cannot use favorites', (
    tester,
  ) async {
    await pumpApp(tester, FakeAuthRepository());
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.tap(find.text('Moonlight Stories').first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton &&
                  widget.tooltip == 'Sign in to save favorites',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Guest mode'), findsOneWidget);
    final favorites = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Favorites'),
    );
    expect(favorites.onTap, isNull);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Password reset sends email through repository', (tester) async {
    final auth = FakeAuthRepository();
    await pumpApp(tester, auth);
    await tester.enterText(
      find.byType(TextFormField).first,
      'reader@example.com',
    );
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(auth.resetEmail, 'reader@example.com');
  });

  testWidgets('Signed-in user can update display name', (tester) async {
    final auth = FakeAuthRepository(
      currentUser: const AppUser(
        uid: 'existing',
        email: 'reader@example.com',
        displayName: 'Reader',
      ),
    );
    await pumpApp(tester, auth);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit display name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Updated Reader');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(auth.currentUser?.displayName, 'Updated Reader');
    expect(find.text('Updated Reader'), findsOneWidget);
  });

  testWidgets('Signed-in favorites stay available in the user library', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      currentUser: const AppUser(
        uid: 'favorite-test',
        email: 'favorite@example.com',
        displayName: 'Reader',
      ),
    );
    await pumpApp(tester, auth);
    await tester.tap(find.text('Moonlight Stories').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Favorite'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Moonlight Stories'), findsOneWidget);
  });
}
