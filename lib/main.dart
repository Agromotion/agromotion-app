import 'dart:async'; // Use the real unawaited from dart:async
import 'dart:io';

import 'package:agromotion/app.dart';
import 'package:agromotion/firebase_options.dart';
import 'package:agromotion/services/auth_service.dart';
import 'package:agromotion/services/notification_service.dart';
import 'package:agromotion/services/widget_service.dart';
import 'package:agromotion/theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

void main() async {
  // Use the actual binding result if needed, otherwise just ensure initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase first
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Initialize MediaKit for video performance
  MediaKit.ensureInitialized();

  FirebaseAuth.instance.setLanguageCode('pt-PT');

  // 3. Initialize App Notification Service
  // This requests permissions and subscribes to the FCM topic robot_agromotion_robot_01
  final notificationService = NotificationService();
  unawaited(notificationService.setupPushNotifications());

  unawaited(AuthService().initGoogleSignIn());

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    unawaited(_initializeWidget());
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

Future<void> _initializeWidget() async {
  try {
    // Note: In a production setup, you'd fetch the real values
    // from Firestore robots/robot_id before updating the widget.
    await WidgetService.updateRobotWidget(
      status: 'Conectado',
      battery: 0, // Will be updated by real telemetry stream later
      food: '---',
    );
  } catch (e) {
    debugPrint('Widget Init Error: $e');
  }
}
