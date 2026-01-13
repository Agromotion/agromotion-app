import 'dart:convert';
import 'package:flutter/services.dart'; // Necessário para rootBundle
import 'package:googleapis_auth/auth_io.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  Future<void> sendDirectNotification({
    required String title,
    required String body,
    required String token,
  }) async {
    try {
      // 1. Carregar o ficheiro JSON dos assets
      final String responseJson = await rootBundle.loadString(
        'assets/service-account.json',
      );
      final data = json.decode(responseJson);

      // 2. Criar credenciais e cliente
      final credentials = ServiceAccountCredentials.fromJson(data);
      final client = await clientViaServiceAccount(credentials, _scopes);

      final String projectId = data['project_id'];
      final String url =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      // 3. Payload da mensagem (Adicionei suporte melhorado para Web)
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
            'fcm_options': {
              'link': '/', // Abre a app ao clicar
            },
          },
        },
      };

      final response = await client.post(
        Uri.parse(url),
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('✅ Notificação direta enviada!');
      } else {
        print('❌ Erro FCM: ${response.body}');
      }

      client.close();
    } catch (e) {
      print('❌ Erro NotificationService: $e');
    }
  }
}
