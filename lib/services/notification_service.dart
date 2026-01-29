/// Serviço para gerir notificações push via Firebase Cloud Messaging (FCM).
/// Inclui lógica para inicialização, pedido de permissões e envio de notificações diretas.
library;

import 'dart:convert';
import 'dart:io';
import 'package:agromotion/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  AuthClient? _client;
  String? _projectId;

  Future<void> initialize() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      _setupTokenHandlers();
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.info(
          'Recebida mensagem em foreground: ${message.notification?.title}',
        );
      });
    } else {
      AppLogger.info("Notificações Push ignoradas nesta plataforma.");
    }
  }

  void _setupTokenHandlers() async {
    String? token = await _messaging.getToken(
      vapidKey: String.fromEnvironment('FCM_VAPID_KEY'),
    );
    if (token != null) _saveTokenToDatabase(token);
    _messaging.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  void _saveTokenToDatabase(String token) {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        FirebaseDatabase.instance.ref('user_tokens/${user.uid}').set(token);
      }
    });
  }

  Future<void> _prepareClient() async {
    if (_client != null) return;

    final String responseJson = await rootBundle.loadString(
      'assets/service-account.json',
    );
    final data = json.decode(responseJson);
    _projectId = data['project_id'];

    final credentials = ServiceAccountCredentials.fromJson(data);
    _client = await clientViaServiceAccount(credentials, _scopes);
  }

  Future<void> sendDirectNotification({
    required String title,
    required String body,
    required String token,
  }) async {
    try {
      await _prepareClient();

      final String url =
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      final message = {
        'message': {
          'token': token,
          'notification': {'title': title, 'body': body},
          'webpush': {
            'notification': {
              'title': title,
              'body': body,
              'icon': '/icons/Icon-192.png',
            },
            'fcm_options': {'link': '/'},
          },
        },
      };

      final response = await _client!.post(
        Uri.parse(url),
        body: jsonEncode(message),
      );

      if (response.statusCode != 200) {
        AppLogger.error('Erro ao enviar notificação FCM: ${response.body}');
        _client = null;
      }
    } catch (e) {
      AppLogger.error('Erro ao enviar notificação FCM: $e');
      _client = null;
    }
  }
}
