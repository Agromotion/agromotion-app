/// Serviço para gerir a captura de screenshots.
/// Utiliza a biblioteca GAL para guardar mídia.
library;

import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:gal/gal.dart';
import 'package:agromotion/services/storage_service.dart';

class MediaService {
  final StorageService _storage = StorageService();
  Future<void> captureScreenshot(MediaStream? stream) async {
    if (stream == null || stream.getVideoTracks().isEmpty) return;
    final frame = await stream.getVideoTracks()[0].captureFrame();

    if (Platform.isAndroid || Platform.isIOS) {
      await Gal.putImageBytes(frame.asUint8List());
    } else {
      final saveDir = await _storage.getSavePath();
      final file = File(
        '$saveDir/IMG_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(frame.asUint8List());
    }
  }
}
