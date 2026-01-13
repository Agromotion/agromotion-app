import 'package:agromotion/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseAuth.instance.setLanguageCode('pt-PT');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const AgroMotionApp(),
    ),
  );
}
