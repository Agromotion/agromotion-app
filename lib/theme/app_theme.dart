import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final LinearGradient backgroundGradient;
  final LinearGradient primaryButtonGradient;
  final LinearGradient glassGradient;

  AppColorsExtension({
    required this.backgroundGradient,
    required this.primaryButtonGradient,
    required this.glassGradient,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith() => this;

  @override
  ThemeExtension<AppColorsExtension> lerp(
    ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      backgroundGradient: LinearGradient.lerp(
        backgroundGradient,
        other.backgroundGradient,
        t,
      )!,
      primaryButtonGradient: LinearGradient.lerp(
        primaryButtonGradient,
        other.primaryButtonGradient,
        t,
      )!,
      glassGradient: LinearGradient.lerp(
        glassGradient,
        other.glassGradient,
        t,
      )!,
    );
  }
}

class AppTheme {
  static const String _fontFamily = 'AudibleSans';

  // A cor vibrante original (ótima para destaques e botões com texto escuro)
  static const Color primaryGreen = Color(0xFFCDFF5E);

  // Uma variante mais escura para garantir contraste em ícones/textos no modo claro
  static const Color primaryGreenDark = Color(0xFF4A6B00);

  static ThemeData get lightTheme => _createTheme(Brightness.light);
  static ThemeData get darkTheme => _createTheme(Brightness.dark);

  static ThemeData _createTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Ajuste de cores do vidro para melhorar contraste no modo claro
    final glassColor = isDark
        ? const Color(0xFF2A3530).withAlpha(120)
        : Colors.white.withAlpha(210); // Mais opaco no modo claro

    final glassBorder = isDark
        ? const Color(0xFF4A5A4F).withAlpha(100)
        : const Color(
            0xFF2E3D33,
          ).withAlpha(40); // Borda ligeiramente mais visível

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF1A2520)
          : const Color(0xFFF0F4F1),

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: brightness,
        // No modo claro, usamos a versão escura como primária para garantir contraste em ícones e textos
        primary: isDark ? primaryGreen : primaryGreenDark,
        onPrimary: isDark ? const Color(0xFF1A2520) : Colors.white,
        secondary: const Color(
          0xFFCDFF5E,
        ), // Mantemos a cor original como secundária de destaque
        surface: glassColor,
        onSurface: isDark ? const Color(0xFFE8F0E8) : const Color(0xFF1A2520),
        outline: glassBorder,
        error: isDark ? const Color(0xFFFF5252) : const Color(0xFFD32F2F),
      ),

      extensions: [
        AppColorsExtension(
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A2520), const Color(0xFF0F1A15)]
                : [
                    const Color(0xFFF5F7F5),
                    const Color(0xFFE2E9E2),
                  ], // Fundo claro mais profundo
          ),
          primaryButtonGradient: const LinearGradient(
            colors: [primaryGreen, Color(0xFFB8E84D)],
          ),
          glassGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF2A3530).withAlpha(140),
                    const Color(0xFF1A2520).withAlpha(100),
                  ]
                : [Colors.white.withAlpha(230), Colors.white.withAlpha(160)],
          ),
        ),
      ],

      cardTheme: CardThemeData(
        elevation: isDark
            ? 0
            : 2, // Ligeira elevação no modo claro para destacar do fundo
        color: glassColor,
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.black.withAlpha(isDark ? 30 : 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: glassBorder, width: 1.5),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF1A2520),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: glassBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? primaryGreen : primaryGreenDark,
            width: 2,
          ),
        ),
      ),

      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: isDark ? const Color(0xFFE8F0E8) : const Color(0xFF1A2520),
        ),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFFE8F0E8) : const Color(0xFF1A2520),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: isDark ? 0 : 4,
          backgroundColor: primaryGreen,
          foregroundColor: const Color(
            0xFF1A2520,
          ), // Texto sempre escuro para contraste no verde limão
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF2A3530) : Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: glassBorder, width: 1.5),
        ),
        contentTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: isDark ? Colors.white : const Color(0xFF1A2520),
        ),
      ),

      dividerTheme: DividerThemeData(color: glassBorder, thickness: 1),
    );
  }
}
