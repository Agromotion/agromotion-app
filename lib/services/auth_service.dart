/// Serviço para gerir autenticação de utilizadores.
/// Inclui lógica para login via Google/Email e Password e verificação de autorização.
library;

import 'package:agromotion/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final ValueNotifier<bool> isWhitelisting = ValueNotifier<bool>(false);

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

  bool _isVerifying = false;
  bool get isVerifying => _isVerifying;

  Future<bool> isUserAuthorized(String? email) async {
    if (email == null || email.isEmpty) return false;
    _isVerifying = true; // Inicia verificação

    final cleanEmail = email.trim().toLowerCase();
    try {
      final query = await FirebaseFirestore.instance
          .collection('authorized_emails')
          .where(FieldPath.documentId, isEqualTo: cleanEmail)
          .get(const GetOptions(source: Source.serverAndCache));

      _isVerifying = false;
      return query.docs.isNotEmpty;
    } catch (e) {
      _isVerifying = false;
      return false;
    }
  }

  Future<void> initGoogleSignIn() async {
    if (_isInitialized) return;

    try {
      _googleSignIn.authenticationState.listen((credentials) async {
        if (credentials != null && _auth.currentUser == null) {
          try {
            GoogleAuthProvider.credential(
              accessToken: credentials.accessToken,
              idToken: credentials.idToken,
            );
          } catch (e) {
            AppLogger.error(
              "Erro no processamento de credenciais automáticas",
              e,
            );
          }
        }
      });

      await _googleSignIn.silentSignIn();
      _isInitialized = true;
    } catch (e) {
      AppLogger.error("Erro ao inicializar Google Auth", e);
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      isWhitelisting.value = true; // Bloqueia o Wrapper
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final authorized = await isUserAuthorized(userCredential.user?.email);

      if (!authorized) {
        await logout();
        isWhitelisting.value = false;
        return "Acesso negado: Este utilizador não está autorizado.";
      }

      isWhitelisting.value = false;
      return null;
    } on FirebaseAuthException catch (e) {
      isWhitelisting.value = false;
      return e.message ?? "Erro ao iniciar sessão.";
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      if (kIsWeb) return "Utilize o botão oficial";
      isWhitelisting.value = true;

      final credentials = await _googleSignIn.signIn();
      if (credentials == null) {
        isWhitelisting.value = false;
        return "Login cancelado";
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: credentials.accessToken,
        idToken: credentials.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final authorized = await isUserAuthorized(userCredential.user?.email);
      if (!authorized) {
        await logout();
        isWhitelisting.value = false;
        return "Acesso negado.";
      }

      isWhitelisting.value = false;
      return null;
    } catch (e) {
      isWhitelisting.value = false;
      return "Erro: $e";
    }
  }

  Widget renderGoogleButton() {
    if (kIsWeb) return _googleSignIn.signInButton() ?? const SizedBox.shrink();
    return const SizedBox.shrink();
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      AppLogger.error("Erro ao fazer logout", e);
    }
  }
}
