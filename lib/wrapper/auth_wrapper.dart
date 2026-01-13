import 'package:agromotion/screens/login_screen.dart';
import 'package:agromotion/screens/main_screen.dart';
import 'package:agromotion/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Decide qual o ecrã a mostrar com base no estado de autenticação
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      // Este stream emite um evento sempre que o utilizador entra ou sai
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se o snapshot tem dados, o utilizador está autenticado
        if (snapshot.hasData) {
          return const MainScreen();
        }

        // Caso contrário, vai para o login
        return const LoginScreen();
      },
    );
  }
}
