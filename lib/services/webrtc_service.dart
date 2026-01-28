import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:agromotion/services/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer remoteRenderer;
  RTCDataChannel? _dataChannel;
  MediaRecorder? _mediaRecorder;
  Timer? _statsTimer;

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
      ],
    };

    _peerConnection = await createPeerConnection(configuration);

    await _peerConnection!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    // Criar canal de dados para comandos de qualidade
    RTCDataChannelInit dcInit = RTCDataChannelInit();
    _dataChannel = await _peerConnection!.createDataChannel("commands", dcInit);

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (_isDisposed) return;
      if (event.track.kind == 'video') {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    RTCSessionDescription offer = await _peerConnection!.createOffer({
      'offerToReceiveVideo': 1,
      'offerToReceiveAudio': 0,
    });
    await _peerConnection!.setLocalDescription(offer);

    final response = await http.post(
      Uri.parse('$url/offer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"sdp": offer.sdp, "type": offer.type}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(data["sdp"], data["type"]),
      );
    }
  }

  void setVideoQuality(String quality) {
    if (_dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dataChannel!.send(
        RTCDataChannelMessage(
          jsonEncode({"type": "SET_QUALITY", "value": quality}),
        ),
      );
    }
  }

  void startAutoQualityMonitor(Function(String) onQualityChanged) {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      double loss = await getConnectionLoss();
      if (loss > 5.0) {
        setVideoQuality("480");
        onQualityChanged("480");
      } else if (loss < 1.0) {
        setVideoQuality("original");
        onQualityChanged("original");
      }
    });
  }

  void stopAutoQualityMonitor() => _statsTimer?.cancel();

  Future<double> getConnectionLoss() async {
    if (_peerConnection == null) return 0.0;
    List<StatsReport> stats = await _peerConnection!.getStats();
    for (var report in stats) {
      if (report.type == 'inbound-rtp' && report.values['kind'] == 'video') {
        int lost = report.values['packetsLost'] ?? 0;
        int received = report.values['packetsReceived'] ?? 0;
        if ((received + lost) == 0) return 0.0;
        return (lost / (received + lost)) * 100;
      }
    }
    return 0.0;
  }

  Future<void> captureScreenshot() async {
    final streams = _peerConnection?.getRemoteStreams();
    if (streams == null || streams.isEmpty) return;
    final frame = await streams[0]?.getVideoTracks()[0].captureFrame();
    if (Platform.isAndroid || Platform.isIOS) {
      await Gal.putImageBytes(frame!.asUint8List());
    } else {
      final saveDir = await _storage.getSavePath();
      final file = File(
        '$saveDir/IMG_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(frame!.asUint8List());
    }
  }

  Future<void> startRecording() async {
    if (isRecording || Platform.isWindows) return;
    final streams = _peerConnection?.getRemoteStreams();
    final saveDir = await _storage.getSavePath();
    _currentFilePath =
        '$saveDir/REC_${DateTime.now().millisecondsSinceEpoch}.mp4';
    _mediaRecorder = MediaRecorder();
    await _mediaRecorder!.start(
      _currentFilePath!,
      videoTrack: streams![0]?.getVideoTracks()[0],
    );
    isRecording = true;
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;
    await _mediaRecorder?.stop();
    isRecording = false;
    if (Platform.isAndroid || Platform.isIOS) {
      await Gal.putVideo(_currentFilePath!);
      File(_currentFilePath!).delete();
    }
  }

  void dispose() {
    _isDisposed = true;
    _statsTimer?.cancel();
    _dataChannel?.close();
    _peerConnection?.dispose();
  }
}
