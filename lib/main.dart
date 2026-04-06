import 'dart:async'; // Use the real unawaited from dart:async
import 'dart:io';

import 'package:agromotion/app.dart';
import 'package:agromotion/firebase_options.dart';
import 'package:agromotion/services/auth_service.dart';
import 'package:agromotion/services/notification_service.dart';
import 'package:agromotion/theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  MediaKit.ensureInitialized();
  FirebaseAuth.instance.setLanguageCode('pt-PT');
  
  final notificationService = NotificationService();
  unawaited(notificationService.setupPushNotifications());

  unawaited(AuthService().initGoogleSignIn());

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    _setupSystemUI();
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const AgromotionApp(),
    ),
  );
}

void _setupSystemUI() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
