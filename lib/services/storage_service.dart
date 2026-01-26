import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class StorageService {
  static const String _storageKey = 'custom_storage_path';

  // Retorna o caminho de salvamento baseado na plataforma e preferência
  Future<String> getSavePath() async {
    if (kIsWeb) return 'downloads';

    final prefs = await SharedPreferences.getInstance();
    String? customPath = prefs.getString(_storageKey);

    if (customPath != null && Directory(customPath).existsSync()) {
      return customPath;
    }

    // Caminhos padrão profissionais
    if (Platform.isWindows) {
      final docDir = await getApplicationDocumentsDirectory();
      final defaultPath = Directory('${docDir.path}\\Agromotion\\Capturas');
      if (!defaultPath.existsSync()) await defaultPath.create(recursive: true);
      return defaultPath.path;
    } else if (Platform.isMacOS) {
      final downloadDir = await getDownloadsDirectory();
      return downloadDir?.path ?? '/Downloads';
    } else {
      // Mobile (Android/iOS)
      final tempDir = await getTemporaryDirectory();
      return tempDir.path;
    }
  }

  Future<String?> pickCustomPath() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) return null;

    String? result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Selecionar local para capturas Agromotion',
    );

    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, result);
    }
    return result;
  }
}
