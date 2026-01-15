import 'package:agromotion/app.dart';
import 'package:agromotion/firebase_options.dart';
import 'package:agromotion/services/auth_service.dart';
import 'package:agromotion/services/notification_service.dart';
import 'package:agromotion/theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseAuth.instance.setLanguageCode('pt-PT');

  await NotificationService().initialize();
  await AuthService().initGoogleSignIn();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const AgroMotionApp(),
    ),
  );
}
