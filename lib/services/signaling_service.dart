import 'package:agromotion/config/app_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get robotId => AppConfig.robotId;

  /// Listen for the Answer from the Robot
  Stream<DocumentSnapshot> getSignalingStream() {
    return _firestore.collection('robot_sessions').doc(robotId).snapshots();
  }

  /// Post the Offer and ICE Candidates to Firestore
  Future<void> sendOffer(
    RTCSessionDescription offer,
    List<RTCIceCandidate> candidates,
  ) async {
    await _firestore.collection('robot_sessions').doc(robotId).set({
      'offer': {'sdp': offer.sdp, 'type': offer.type},
      'appCandidates': candidates
          .map(
            (e) => {
              'candidate': e.candidate,
              'sdpMid': e.sdpMid,
              'sdpMLineIndex': e.sdpMLineIndex,
            },
          )
          .toList(),
      'answer': null,
      'robotCandidates': [],
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }
}
