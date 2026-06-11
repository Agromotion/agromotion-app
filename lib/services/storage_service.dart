/// Serviço para gerir o armazenamento de capturas de ecrã e vídeos.
/// Inclui lógica para escolher caminhos de armazenamento personalizados.
library;

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _joystickSwapKey = 'joystick_swap_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';

  /// Obtém a preferência de troca de joysticks
  Future<bool> getJoystickSwap() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_joystickSwapKey) ?? false;
  }

  /// Define a preferência de troca de joysticks
  Future<void> setJoystickSwap(bool swap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_joystickSwapKey, swap);
  }

  /// Obtém a preferência de vibração
  Future<bool> getVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  /// Define a preferência de vibração
  Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, enabled);
  }
}
