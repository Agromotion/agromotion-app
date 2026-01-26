import 'dart:convert';
import 'dart:io';
import 'package:agromotion/services/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:url_launcher/url_launcher.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer remoteRenderer;
  MediaRecorder? _mediaRecorder;
  bool isRecording = false;
  String? _currentFilePath;
  bool _isDisposed = false;

  WebRTCService({required this.remoteRenderer});
  final StorageService _storage = StorageService();

  Future<void> connect(String url) async {
    Map<String, dynamic> configuration = {
      "sdpSemantics": "unified-plan",
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
        {"urls": "stun:stun1.l.google.com:19302"},
      ],
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (_isDisposed) return;
      if (event.track.kind == 'video') {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    RTCSessionDescription offer = await _peerConnection!.createOffer({
      'offerToReceiveVideo': 1,
      'offerToReceiveAudio': 0,
      'mandatory': {'OfferToReceiveVideo': true},
    });
    await _peerConnection!.setLocalDescription(offer);

    final response = await http.post(
      Uri.parse('$url/offer'),
      headers: {
        'Content-Type': 'application/json',
        'X-Skip-Publisher-Welcome': 'true',
      },
      body: jsonEncode({"sdp": offer.sdp, "type": offer.type}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(data["sdp"], data["type"]),
      );
    }
  }

  Future<void> captureScreenshot() async {
    if (_isDisposed) return;
    try {
      final streams = _peerConnection?.getRemoteStreams();
      if (streams != null && streams.isNotEmpty && streams[0] != null) {
        final videoTrack = streams[0]!.getVideoTracks()[0];
        final frame = await videoTrack.captureFrame();

        if (Platform.isAndroid || Platform.isIOS) {
          await Gal.putImageBytes(frame.asUint8List());
        } else {
          // Desktop: Salva no caminho definido pelo StorageService
          final saveDir = await _storage.getSavePath();
          final String filePath =
              '$saveDir/IMG_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File(filePath);
          await file.writeAsBytes(frame.asUint8List());
          debugPrint("Foto salva em: $filePath");
        }
      }
    } catch (e) {
      debugPrint("Erro ao capturar foto: $e");
    }
  }

  Future<void> startRecording() async {
    if (isRecording || _isDisposed || Platform.isWindows) return;

    final streams = _peerConnection?.getRemoteStreams();
    if (streams == null || streams.isEmpty || streams[0] == null) return;

    // Obtém o caminho profissional definido no StorageService
    final saveDir = await _storage.getSavePath();
    _currentFilePath =
        '$saveDir/REC_${DateTime.now().millisecondsSinceEpoch}.mp4';

    _mediaRecorder = MediaRecorder();
    await _mediaRecorder!.start(
      _currentFilePath!,
      videoTrack: streams[0]!.getVideoTracks()[0],
    );
    isRecording = true;
  }

  Future<void> stopRecording() async {
    if (!isRecording || _mediaRecorder == null) return;
    try {
      await _mediaRecorder!.stop();
      isRecording = false;
      if (_currentFilePath != null && (Platform.isAndroid || Platform.isIOS)) {
        await Gal.putVideo(_currentFilePath!);
        final file = File(_currentFilePath!);
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      debugPrint("Erro ao parar gravação: $e");
    } finally {
      _mediaRecorder = null;
    }
  }

  void dispose() {
    _isDisposed = true;
    if (isRecording) stopRecording();
    remoteRenderer.srcObject = null;
    _peerConnection?.dispose();
    _peerConnection = null;
  }
}
