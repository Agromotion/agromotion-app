import 'package:agromotion/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:agromotion/components/login/google_button_stub.dart'
    if (dart.library.js_util) 'package:agromotion/components/login/google_button_web.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  GoogleSignIn get _google => GoogleSignIn.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool _isSigningIn = false;

  Future<void> initGoogleSignIn() async {
    try {
      await _google.initialize(
        clientId:
            '447251651704-t7a47686npj3lo6esjl09vlvem78n6mp.apps.googleusercontent.com',
      );

      _google.authenticationEvents.listen((event) async {
        if (event is GoogleSignInAuthenticationEventSignIn &&
            _auth.currentUser == null) {
          if (_isSigningIn) return;
          _isSigningIn = true;

          try {
            final googleAuth = event.user.authentication;
            final credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.idToken,
              idToken: googleAuth.idToken,
            );

            await _auth.signInWithCredential(credential);
            AppLogger.info("Utilizador autenticado via Google Sign-In");
          } finally {
            _isSigningIn = false;
          }
        }
      });
    } catch (e, stack) {
      AppLogger.error("Erro ao inicializar Google Sign-In", e, stack);
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser = await _google.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.idToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return null;
    } catch (e, stack) {
      AppLogger.error("Erro ao ligar à conta Google", e, stack);
      return "Erro ao ligar à conta Google.";
    }
  }

  // Método para renderizar o botão oficial na Web
  Widget renderGoogleButton() {
    if (kIsWeb) {
      return renderWebGoogleButton();
    }
    return const SizedBox.shrink();
  }

  Future<void> logout() async {
    try {
      if (kIsWeb) {
        await _google.disconnect();
      }
      await _google.signOut();
      await _auth.signOut();
    } catch (e, stack) {
      AppLogger.error("Erro ao fazer logout", e, stack);
    }
  }
}
