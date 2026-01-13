import 'package:agromotion/components/login/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/login_painters.dart';
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
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  Future<void> _handleFirebaseLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showSnackBar("Por favor, preenche todos os campos.", isError: true);
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
      if (result == null) {
        HapticFeedback.selectionClick();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        HapticFeedback.vibrate();
        _showSnackBar(result, isError: true);
      }
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
          // Ondas Animadas
          AnimatedBuilder(
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
          ),

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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SocialLoginButton(
                          label: 'Google',
                          icon: Icons.account_circle,
                          color: Colors.red.shade400,
                          onTap: () {},
                        ),
                        SocialLoginButton(
                          label: 'Microsoft',
                          icon: Icons.window,
                          color: Colors.blue.shade700,
                          onTap: () {},
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
