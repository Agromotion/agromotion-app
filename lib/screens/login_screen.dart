import 'package:agromotion/components/agro_loading.dart';
import 'package:agromotion/components/login/login_background.dart';
import 'package:agromotion/components/login/login_footer.dart';
import 'package:agromotion/components/login/login_text_field.dart';
import 'package:agromotion/components/login/primary_button.dart';
import 'package:agromotion/components/login/social_login_button.dart';
import 'package:agromotion/screens/main_screen.dart';
import 'package:agromotion/screens/settings_screen.dart'; // Import necessário
import 'package:agromotion/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService.initGoogleSignIn();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _processLogin(Future<String?> loginTask) async {
    setState(() => _isLoading = true);
    if (!kIsWeb) HapticFeedback.mediumImpact();

    final minimumDisplayTime = Future.delayed(
      const Duration(milliseconds: 3500),
    );
    final results = await Future.wait([loginTask, minimumDisplayTime]);
    final String? error = results[0] as String?;

    if (mounted) {
      if (error != null) {
        setState(() => _isLoading = false);
        if (!kIsWeb) HapticFeedback.vibrate();
        _showSnackBar(error, isError: true);
      } else {
        if (!kIsWeb) HapticFeedback.lightImpact();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background de Vídeo
          const Positioned.fill(child: LoginBackground()),

          // Botão de Definições no Topo Direito
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Form de Login
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 15),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo_512.png',
                        width: 90,
                        height: 90,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Agromotion',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Card com Glassmorphism
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withAlpha(70)
                              : Colors.white.withAlpha(85),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.white30,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 20),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                              onToggleVisibility: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            const SizedBox(height: 24),
                            PrimaryButton(
                              label: 'Entrar',
                              isLoading: _isLoading,
                              onPressed: () => _processLogin(
                                _authService.login(
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            kIsWeb
                                ? _authService.renderGoogleButton()
                                : SocialLoginButton(
                                    label: 'Continuar com Google',
                                    icon: Icons.account_circle_outlined,
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.white,
                                    textColor: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    onTap: () => _processLogin(
                                      _authService.signInWithGoogle(),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: LoginFooter(),
              ),
            ),
          ),

          // Overlay de Loading
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha(55),
                child: const Center(child: AgroLoading(size: 100)),
              ),
            ),
        ],
      ),
    );
  }
}
