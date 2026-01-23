import 'package:agromotion/components/agro_loading.dart';
import 'package:agromotion/screens/login_screen.dart';
import 'package:agromotion/screens/main_screen.dart';
import 'package:agromotion/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        return ValueListenableBuilder<bool>(
          valueListenable: authService.isWhitelisting,
          builder: (context, isWhitelisting, child) {
            // Se o Firebase ainda está a carregar o estado inicial
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: AgroLoading()));
            }

            final user = authSnapshot.data;

            // Se houver um user no Firebase, mas o AuthService ainda estiver a
            // verificar a whitelist, mantemos a LoginScreen (com o overlay de loading dela).
            if (user != null && !isWhitelisting) {
              return const MainScreen();
            }

            // Em qualquer outro caso (sem user ou a verificar whitelist),
            // mantemos a LoginScreen.
            return const LoginScreen();
          },
        );
      },
    );
  }
}
