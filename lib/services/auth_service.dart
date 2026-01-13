import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Obter o utilizador atual
  User? get currentUser => _auth.currentUser;

  // Stream para monitorizar o estado do login (logado ou não)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login com Email e Senha
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Sucesso
    } on FirebaseAuthException catch (e) {
      return e.message; // Devolve o erro
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
