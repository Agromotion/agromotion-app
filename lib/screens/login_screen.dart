import 'package:flutter/material.dart';
import '../components/login_painters.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  void _handleFirebaseLogin() {
    // Aqui vais usar FirebaseAuth.instance.signInWithEmailAndPassword
    print("Login com Email: ${_emailController.text}");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  void _handleGoogleLogin() {
    // Lógica do pacote google_sign_in
    print("Login com Google");
  }

  void _handleMicrosoftLogin() {
    // Lógica do OAuthProvider("microsoft.com")
    print("Login com Microsoft");
  }

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _controller;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(); // Inicia o loop infinito
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose(); // Importante descartar o controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      // O AnimatedBuilder é o segredo: ele ouve o controller e redesenha as ondas
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Onda do Topo
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
              // Onda do Fundo
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(size.width, 180),
                  painter: AnimatedWavePainter(
                    animationValue:
                        -_controller.value, // Negativo para sentido oposto
                    isTop: false,
                    color1: Colors.green[300]!,
                    color2: Colors.green[100]!,
                  ),
                ),
              ),
              // Passamos o formulário como child ou widget fixo para não ser afetado
              // pelo rebuild desnecessário, embora aqui o builder envolva tudo.
              _buildFormContent(theme),
            ],
          );
        },
      ),
    );
  }

  // Extraí o conteúdo para manter o build mais limpo
  Widget _buildFormContent(ThemeData theme) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo e Título
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
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),

              // Campos de User/Pass
              _buildTextField(
                controller: _emailController,
                hint: 'Email',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline,
                isPassword: true,
              ),

              // Botão Login Principal
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _handleFirebaseLogin(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Entrar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),
              _buildDivider(),
              const SizedBox(height: 20),

              // Botões de Login Social
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _socialButton(
                    label: 'Google',
                    iconPath: Icons
                        .account_circle, // Idealmente usar imagem do logo Google
                    color: Colors.red.shade400,
                    onTap: () => _handleGoogleLogin(),
                  ),
                  _socialButton(
                    label: 'Microsoft',
                    iconPath: Icons.window,
                    color: Colors.blue.shade700,
                    onTap: () => _handleMicrosoftLogin(),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Não tens conta? Regista-te aqui',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper para os campos de texto
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  // Linha separadora "OU"
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "OU",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  // Widget do Botão Social
  Widget _socialButton({
    required String label,
    required IconData iconPath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(iconPath, color: color),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
