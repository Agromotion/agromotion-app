import 'package:agromotion/app.dart';
import 'package:agromotion/firebase_options.dart';
import 'package:agromotion/services/auth_service.dart';
import 'package:agromotion/services/notification_service.dart';
import 'package:agromotion/services/widget_service.dart';
import 'package:agromotion/theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseAuth.instance.setLanguageCode('pt-PT');

  await NotificationService().initialize();
  await AuthService().initGoogleSignIn();

  // Inicializa widget com dados padrão
  await _initializeWidget();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const AgroMotionApp(),
    ),
  );
}

/// Inicializa o widget com valores padrão ao iniciar a app
Future<void> _initializeWidget() async {
  try {
    await WidgetService.updateRobotWidget(
      status: 'Iniciando',
      battery: 85,
      food: '62kg',
    );
  } catch (e) {
    debugPrint('Erro ao inicializar widget: $e');
  }
}
