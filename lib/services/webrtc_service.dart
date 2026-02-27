import 'dart:async';
import 'dart:convert';
import 'package:agromotion/config/app_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  final RTCVideoRenderer remoteRenderer;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get robotId => AppConfig.robotId;

  StreamSubscription? _signalingSubscription;
  bool _isDisposed = false;

  // Status Getters
  bool get isConnected =>
      _dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen;
  bool get isDisposed => _isDisposed;

  WebRTCService({required this.remoteRenderer});

  Future<void> connect() async {
    if (_isDisposed) return;

    // 1. Peer Connection Configuration
    // STUN servers allow the App and Pi to find each other behind any WiFi/NAT
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
        {"urls": "stun:stun1.l.google.com:19302"},
      ],
      "sdpSemantics": "unified-plan",
    };

    _peerConnection = await createPeerConnection(configuration);

    // 2. Setup DataChannel for ultra-low latency commands (<30ms)
    // ordered: false + maxRetransmits: 0 = "UDP-like" (fastest possible for driving)
    RTCDataChannelInit dcInit = RTCDataChannelInit()
      ..ordered = false
      ..maxRetransmits = 0;

    _dataChannel = await _peerConnection!.createDataChannel("commands", dcInit);

    // 3. Handle Remote Video Track (from Pi)
    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video' && !_isDisposed) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    // 4. Handle ICE Candidates
    // Whenever the App finds a "path" to the internet, it sends it to the Robot via Firestore
    _peerConnection!.onIceCandidate = (candidate) {
      _db.collection('robots').doc(robotId).update({
        'app_candidates': FieldValue.arrayUnion([
          {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        ]),
      });
    };

    // 5. Create WebRTC Offer
    RTCSessionDescription offer = await _peerConnection!.createOffer({
      'offerToReceiveVideo': 1,
      'offerToReceiveAudio': 0,
    });
    await _peerConnection!.setLocalDescription(offer);

    // 6. Push Offer to Firestore to wake up the Robot
    await _db.collection('robots').doc(robotId).set({
      'webrtc_session': {
        'offer': {'sdp': offer.sdp, 'type': offer.type},
        'answer': null,
      },
      'app_candidates': [],
      'robot_candidates': [],
      'last_handshake': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 7. Listen for the Robot's Answer and ICE Candidates
    _signalingSubscription = _db
        .collection('robots')
        .doc(robotId)
        .snapshots()
        .listen((snapshot) async {
          if (!snapshot.exists || _isDisposed) return;
          final data = snapshot.data()!;

          // Handle Answer from Robot
          final session = data['webrtc_session'];
          if (session != null &&
              session['answer'] != null &&
              _peerConnection?.getRemoteDescription() == null) {
            await _peerConnection!.setRemoteDescription(
              RTCSessionDescription(
                session['answer']['sdp'],
                session['answer']['type'],
              ),
            );
            debugPrint("WebRTC: Answer received from Robot.");
          }

          // Handle ICE Candidates from Robot (Hole Punching)
          final List? robotCandidates = data['robot_candidates'];
          if (robotCandidates != null && robotCandidates.isNotEmpty) {
            for (var c in robotCandidates) {
              _peerConnection!.addCandidate(
                RTCIceCandidate(
                  c['candidate'],
                  c['sdpMid'],
                  c['sdpMLineIndex'],
                ),
              );
            }
          }
        });
  }

  /// Sends movement commands directly to the Pi's memory via P2P DataChannel.
  /// Bypasses all databases for maximum responsiveness.
  void sendJoystick(double x, double y) {
    if (isConnected && !_isDisposed) {
      final String msg = jsonEncode({
        "x": double.parse(x.toStringAsFixed(2)),
        "y": double.parse(y.toStringAsFixed(2)),
      });
      _dataChannel!.send(RTCDataChannelMessage(msg));
    }
  }

  void dispose() {
    _isDisposed = true;
    _signalingSubscription?.cancel();
    _dataChannel?.close();
    _peerConnection?.dispose();
    remoteRenderer.srcObject = null;
  }
}
