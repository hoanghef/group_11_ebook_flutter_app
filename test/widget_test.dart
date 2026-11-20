import 'package:app_ebook/main.dart';
import 'package:app_ebook/screens/login_screen.dart';
import 'package:app_ebook/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fake_auth_repository.dart';

void main() {
  testWidgets('EbookApp opens the login screen', (tester) async {
    await tester.pumpWidget(EbookApp(authRepository: FakeAuthRepository()));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });

  testWidgets('Empty login form shows required field errors', (tester) async {
    await tester.pumpWidget(EbookApp(authRepository: FakeAuthRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Registration opens and validates required fields', (
    tester,
  ) async {
    await tester.pumpWidget(EbookApp(authRepository: FakeAuthRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pump();

    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
    expect(find.byType(RegisterScreen), findsOneWidget);
  });
}
