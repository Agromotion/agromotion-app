import 'package:agromotion/firebase_options.dart';
import 'package:agromotion/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'theme/theme_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:agromotion/config/env.dart';

// Função para lidar com mensagens em background (Web/Android)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 1. Inicializa o Auth primeiro
  FirebaseAuth.instance.setLanguageCode('pt-PT');
  final authService = AuthService();
  await authService.initGoogleSignIn();

  // 2. Configura Mensagens
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const AgroMotionApp(),
    ),
  );

  // 3. Trata das notificações fora do fluxo crítico de boot (Background)
  _setupFCM(messaging);
}

// Função auxiliar para não entupir o main
void _setupFCM(FirebaseMessaging messaging) async {
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    String? token = await messaging.getToken(
      vapidKey: const String.fromEnvironment('FCM_VAPID_KEY'),
    );

    if (token != null) {
      print("FCM Token: $token");
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          FirebaseDatabase.instance.ref('user_tokens/${user.uid}').set(token);
        }
      });
    }
  }
}
