import 'dart:math' as math;
import 'package:agromotion/components/agro_loading.dart';
import 'package:agromotion/components/agro_snackbar.dart';
import 'package:agromotion/components/login/login_background.dart';
import 'package:agromotion/components/login/login_footer.dart';
import 'package:agromotion/components/login/login_text_field.dart';
import 'package:agromotion/components/login/primary_button.dart';
import 'package:agromotion/components/login/social_login_button.dart';
import 'package:agromotion/screens/settings_screen.dart';
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
    if (!mounted) return;

    setState(() => _isLoading = true);

    final String? error = await loginTask;

    if (mounted) {
      setState(() => _isLoading = false);

      if (error != null) {
        AgroSnackbar.show(context, message: error, isError: true);
        if (!kIsWeb) HapticFeedback.vibrate();
      } else {
        if (!kIsWeb) HapticFeedback.lightImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Fundo
          const Positioned.fill(child: LoginBackground()),

          // Main Layout
          LayoutBuilder(
            builder: (context, constraints) {
              double contentWidth = math.min(constraints.maxWidth * 0.9, 450);
              contentWidth = math.max(contentWidth, 320);

              if (contentWidth > constraints.maxWidth) {
                contentWidth = constraints.maxWidth * 0.95;
              }

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Center(
                      child: Container(
                        width: contentWidth,
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 60,
                            ), // Espaço para o botão de settings
                            _buildHeader(),
                            const SizedBox(height: 40),
                            _buildLoginCard(),
                            const Spacer(),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.0),
                              child: LoginFooter(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Botão de Settings
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 15,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                tooltip: 'Definições',
              ),
            ),
          ),

          // 4. Loading Overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha(60),
                child: const Center(child: AgroLoading()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15)],
          ),
          child: Image.asset('assets/logo_512.png', width: 120, height: 120),
        ),
        const SizedBox(height: 16),
        const Text(
          'Agromotion',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              onToggleVisibility: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
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
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: theme.colorScheme.onSurface.withAlpha(50),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "ou",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(180),
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: theme.colorScheme.onSurface.withAlpha(50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            kIsWeb
                ? _authService.renderGoogleButton()
                : SocialLoginButton(
                    label: 'Continuar com Google',
                    icon: Icons.account_circle_outlined,
                    color: theme.colorScheme.secondaryContainer.withAlpha(150),
                    textColor: theme.colorScheme.onSecondaryContainer,
                    onTap: () => _processLogin(_authService.signInWithGoogle()),
                  ),
          ],
        ),
      ),
    );
  }
}
