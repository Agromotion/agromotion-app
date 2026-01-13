import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';

// Componentes do teu projeto
import '../components/login/primary_button.dart';
import '../components/login/login_painters.dart';
import '../components/login/login_text_field.dart';
import '../components/login/social_login_button.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _controller;
  late StreamSubscription<User?> _authSubscription;

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _authService.initGoogleSignIn();
    _authSubscription = _authService.authStateChanges.listen((User? user) {
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    _authSubscription.cancel(); // Importante cancelar para evitar leaks
    super.dispose();
  }

  // Login tradicional (Email/Password)
  Future<void> _handleFirebaseLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showSnackBar("Por favor, preencha todos os campos.", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    final result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null) {
        HapticFeedback.vibrate();
        _showSnackBar(result, isError: true);
      }
    }
  }

  // Login Google para Mobile (no Web o botão oficial trata de tudo)
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final result = await _authService.signInWithGoogle();
    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null) _showSnackBar(result, isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Ondas Animadas (Background)
          _buildAnimatedBackground(size),

          // Conteúdo do Formulário
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.agriculture_rounded,
                      size: 70,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AgroMotion',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),

                    LoginTextField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    LoginTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscurePassword: _obscurePassword,
                      onToggleVisibility: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),

                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Entrar',
                      isLoading: _isLoading,
                      onPressed: _handleFirebaseLogin,
                    ),

                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 24),

                    // BOTÕES SOCIAIS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (kIsWeb)
                          // Na Web, renderiza o botão oficial da Google
                          SizedBox(
                            height: 44,
                            child: _authService.renderGoogleButton(),
                          )
                        else
                          // No Mobile, usa o teu SocialLoginButton customizado
                          SocialLoginButton(
                            label: 'Google',
                            icon: Icons.account_circle,
                            color: Colors.red.shade400,
                            onTap: _handleGoogleLogin,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(20),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(size.width, 180),
              painter: AnimatedWavePainter(
                animationValue: _controller.value,
                isTop: true,
                color1: Colors.green[300]!,
                color2: Colors.green[100]!,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(size.width, 180),
              painter: AnimatedWavePainter(
                animationValue: -_controller.value,
                isTop: false,
                color1: Colors.green[300]!,
                color2: Colors.green[100]!,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Ou", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
