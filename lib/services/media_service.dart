/// Serviço para gerir a captura de mídia (screenshots e gravação de vídeo).
/// Utiliza a biblioteca GAL para guardar mídia na galeria do dispositivo.
library;

import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:gal/gal.dart';
import 'package:agromotion/services/storage_service.dart';

class MediaService {
  final StorageService _storage = StorageService();
  MediaRecorder? _mediaRecorder;
  String? _currentFilePath;
  bool isRecording = false;

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

  Future<void> startRecording(MediaStream? stream) async {
    if (isRecording || Platform.isWindows || stream == null) return;

    final saveDir = await _storage.getSavePath();
    _currentFilePath =
        '$saveDir/REC_${DateTime.now().millisecondsSinceEpoch}.mp4';

    _mediaRecorder = MediaRecorder();
    await _mediaRecorder!.start(
      _currentFilePath!,
      videoTrack: stream.getVideoTracks()[0],
    );
    isRecording = true;
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;
    await _mediaRecorder?.stop();
    isRecording = false;

    if (Platform.isAndroid || Platform.isIOS) {
      await Gal.putVideo(_currentFilePath!);
      final file = File(_currentFilePath!);
      if (await file.exists()) await file.delete();
    }
  }
}
