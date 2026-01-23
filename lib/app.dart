import 'package:agromotion/wrapper/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

class AgromotionApp extends StatelessWidget {
  const AgromotionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Agromotion',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: _locales,
      supportedLocales: const [Locale('pt', 'PT')],
      locale: const Locale('pt', 'PT'),
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }

  static const _locales = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}
