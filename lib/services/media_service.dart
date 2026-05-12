/// Serviço para gerir a captura de screenshots.
/// Utiliza a biblioteca GAL para guardar mídia.
library;

import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:gal/gal.dart';

class MediaService {
  Future<void> captureScreenshot(MediaStream? stream) async {
    if (stream == null || stream.getVideoTracks().isEmpty) return;
    final frame = await stream.getVideoTracks()[0].captureFrame();
    await Gal.putImageBytes(frame.asUint8List());
    if (Platform.isAndroid || Platform.isIOS) {
    } else {
      final saveDir = 'downloads';
      final file = File(
        '$saveDir/IMG_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(frame.asUint8List());
    }
  }
}
