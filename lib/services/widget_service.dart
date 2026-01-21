// lib/services/widget_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:agromotion/utils/app_logger.dart';
import 'package:flutter/services.dart';

class WidgetService {
  static const platform = MethodChannel('com.example.agromotion/widget');

  /// Update the Android home screen widget with new data
  ///
  /// [status] - Robot status text
  /// [battery] - Battery percentage (0-100)
  /// [food] - Food level as string (e.g., "500g" or "10kg")
  static Future<void> updateRobotWidget({
    required String status,
    required int battery,
    required String food,
  }) async {
    try {
      // Extrai o número (ex: "500g" -> 500 ou "10kg" -> 10)
      double foodValue =
          double.tryParse(food.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

      // Converte gramas para KG se necessário
      if (food.toLowerCase().contains('g') &&
          !food.toLowerCase().contains('kg')) {
        foodValue /= 1000;
      }

      // Garante que está entre 0-100 para a barra de progresso
      int foodPercentage = (foodValue * 100 / 100).clamp(0, 100).toInt();
      int batteryPercentage = battery.clamp(0, 100);

      // Chama o método nativo do Android
      await platform.invokeMethod('updateWidget', {
        'battery': batteryPercentage,
        'food': foodPercentage,
        'foodKg': foodValue.toInt(),
      });

      AppLogger.info(
        'Widget atualizado: Battery=$batteryPercentage%, Food=${foodValue}kg',
      );
    } on PlatformException catch (e) {
      AppLogger.error('Falha ao atualizar widget: ${e.message}');
    } catch (e) {
      AppLogger.error('Erro inesperado ao atualizar widget: $e');
    }
  }
}

class RobotSimulator {
  Timer? _timer;
  int _currentIndex = 0;

  Future<void> startSimulation() async {
    // 1. Carrega o JSON dos assets
    final String response = await rootBundle.loadString(
      'assets/mock_robot_data.json',
    );
    final List<dynamic> data = json.decode(response);

    // 2. Inicia um Timer que corre a cada 1 segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 3. Atualiza o Widget com os dados do Mock
      WidgetService.updateRobotWidget(
        status: data[_currentIndex]['status'],
        battery: data[_currentIndex]['battery'],
        food: data[_currentIndex]['food'],
      );

      AppLogger.info(
        "Simulação: ${data[_currentIndex]['status']} | Bat: ${data[_currentIndex]['battery']}%",
      );

      // 4. Avança no index ou volta ao início
      _currentIndex = (_currentIndex + 1) % data.length;
    });
  }

  void stopSimulation() {
    _timer?.cancel();
    _timer = null;
    _currentIndex = 0;
  }
}
