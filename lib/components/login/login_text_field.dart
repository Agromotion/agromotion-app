import 'package:flutter/material.dart';

class LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscurePassword;
  final VoidCallback? onToggleVisibility;
  final TextInputType keyboardType;

  const LoginTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscurePassword = true,
    this.onToggleVisibility,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Para o Glassmorphism funcionar sobre vídeo, o texto deve ser branco
    // independentemente do tema do sistema, pois o fundo de login costuma ser fixo.
    const glassWhite = Colors.white;
    const glassWhiteLow = Colors.white70;

    return TextField(
      controller: controller,
      obscureText: isPassword ? obscurePassword : false,
      keyboardType: keyboardType,
      style: const TextStyle(color: glassWhite),
      cursorColor: glassWhite,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: glassWhiteLow),
        floatingLabelStyle: TextStyle(
          color: isDark ? theme.colorScheme.primary : glassWhite,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Icon(icon, color: glassWhiteLow),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: glassWhiteLow,
                ),
                onPressed: onToggleVisibility,
              )
            : null,

        filled: true,
        // No modo claro, aumentamos ligeiramente a opacidade do branco para compensar a claridade
        fillColor: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.12),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2), // Borda sutil de vidro
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? theme.colorScheme.primary : Colors.white,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }
}
