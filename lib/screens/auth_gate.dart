import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../controllers/auth_scope.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final status = auth.status;
    return switch (status) {
      AuthStatus.loading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthStatus.signedOut =>
        auth.showRegister ? const RegisterScreen() : const LoginScreen(),
      AuthStatus.signedIn || AuthStatus.guest => const HomeScreen(),
    };
  }
}
