/// Serviço para gerir a comunicação de telemetria via Data Channel WebRTC.
/// Inclui lógica para envio de comandos e receção de dados de telemetria.
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class TelemetryService {
  RTCDataChannel? _dataChannel;
  Timer? _pingTimer;

  Function(Map<String, dynamic>)? onTelemetryReceived;
  Function(int)? onLatencyMeasured;

  bool get isConnected =>
      _dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen;

  void initialize(RTCDataChannel channel) {
    _dataChannel = channel;
    _setupListeners();
  }

  void _setupListeners() {
    _dataChannel?.onMessage = (RTCDataChannelMessage message) {
      try {
        Map<String, dynamic> data = jsonDecode(message.text);
        if (data['type'] == 'TELEMETRY') {
          onTelemetryReceived?.call(data);
        } else if (data['type'] == 'PONG') {
          int sentTime = data['timestamp'];
          int now = DateTime.now().millisecondsSinceEpoch;
          onLatencyMeasured?.call(now - sentTime);
        }
      } catch (e) {
        debugPrint("Erro Telemetria: $e");
      }
    };
  }

  void startPingSequence() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen) {
        _dataChannel!.send(
          RTCDataChannelMessage(
            jsonEncode({
              "type": "PING",
              "timestamp": DateTime.now().millisecondsSinceEpoch,
            }),
          ),
        );
      }
    });
  }

  void sendCommand(String type, dynamic value) {
    if (_dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dataChannel!.send(
        RTCDataChannelMessage(jsonEncode({"type": type, "value": value})),
      );
    }
  }

  void dispose() {
    _pingTimer?.cancel();
    _dataChannel?.close();
  }
}
