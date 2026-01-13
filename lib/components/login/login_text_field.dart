import 'package:flutter/material.dart';

class LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscurePassword;
  final VoidCallback? onToggleVisibility;
  final TextInputType? keyboardType;

  const LoginTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscurePassword = false,
    this.onToggleVisibility,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword && obscurePassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withAlpha(230),
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
}
