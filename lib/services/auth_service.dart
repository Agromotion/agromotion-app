import 'package:agromotion/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _webClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const String _webClientSecret = String.fromEnvironment(
    'GOOGLE_CLIENT_SECRET',
  );
  bool _isInitialized = false;

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    params: GoogleSignInParams(
      clientId: _webClientId,
      clientSecret: kIsWeb ? null : _webClientSecret,
      redirectPort: 5555,
      scopes: ['openid', 'profile', 'email'],
    ),
  );

  FirebaseAuth get _auth => FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- Inicialização ---
  Future<void> initGoogleSignIn() async {
    if (_isInitialized) return;

    try {
      await _googleSignIn.silentSignIn();

      _googleSignIn.authenticationState.listen((credentials) async {
        if (credentials != null && _auth.currentUser == null) {
          try {
            final credential = GoogleAuthProvider.credential(
              accessToken: credentials.accessToken,
              idToken: credentials.idToken,
            );
            await _auth.signInWithCredential(credential);
            AppLogger.info("Firebase autenticado com sucesso.");
          } catch (e) {
            AppLogger.error("Erro ao vincular ao Firebase", e);
          }
        }
      });

      _isInitialized = true;
    } catch (e) {
      AppLogger.error("Erro ao inicializar Google Auth", e);
    }
  }

  // --- Métodos de Login e logout ---
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Erro ao iniciar sessão.";
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      if (kIsWeb) return "Utilize o botão oficial renderGoogleButton()";

      AppLogger.info("Iniciando fluxo no browser nativo...");
      final credentials = await _googleSignIn.signIn();

      if (credentials == null) return "Login cancelado";

      // Login explícito para garantir a transição de ecrã na LoginScreen
      final credential = GoogleAuthProvider.credential(
        accessToken: credentials.accessToken,
        idToken: credentials.idToken,
      );

      await _auth.signInWithCredential(credential);
      return null;
    } catch (e, stack) {
      AppLogger.error("Erro crítico no login Windows", e, stack);
      return "Erro na autenticação: $e";
    }
  }

  Widget renderGoogleButton() {
    if (kIsWeb) return _googleSignIn.signInButton() ?? const SizedBox.shrink();
    return const SizedBox.shrink();
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      AppLogger.error("Erro ao fazer logout", e);
    }
  }
}
