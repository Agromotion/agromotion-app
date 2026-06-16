import 'dart:async';

import 'package:agromotion/screens/camera_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agromotion/config/app_config.dart';
import 'package:agromotion/theme/app_theme.dart';
import 'package:agromotion/widgets/agro_snackbar.dart';

class ControlRobotButton extends StatefulWidget {
  const ControlRobotButton({super.key});

  @override
  State<ControlRobotButton> createState() => _ControlRobotButtonState();
}

class _ControlRobotButtonState extends State<ControlRobotButton> {
  late FirebaseFirestore _firestore;
  bool _isAutoModeOn = false;
  bool _isOnline = false;
  String get _robotId => AppConfig.robotId;
  StreamSubscription? _autoModeSubscription;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _listenToAutoMode();
  }

  @override
  void dispose() {
    _autoModeSubscription?.cancel();
    super.dispose();
  }

  void _listenToAutoMode() {
    _autoModeSubscription = _firestore
        .collection('robots')
        .doc(_robotId)
        .snapshots()
        .listen((snap) {
          if (!snap.exists || !mounted) return;

          final data = snap.data()!;
          final statusMap = data['status'] as Map<String, dynamic>? ?? {};
          final isAutoMode = statusMap['autoMode'] ?? false;
          final isOnline = statusMap['online'] ?? false;

          setState(() {
            _isAutoModeOn = isAutoMode;
            _isOnline = isOnline;
          });
        });
  }

  void _handleButtonPress() {
    if (_isAutoModeOn || !_isOnline) {
      AgroSnackbar.show(
        context,
        message: 'Desative o modo automático para controlar o robô',
        isError: true,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<AppColorsExtension>()!;

    final isDisabled = _isAutoModeOn || !_isOnline;

    return GestureDetector(
      onTap: isDisabled ? null : _handleButtonPress,
      child: Container(
        height: 65,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDisabled
              ? LinearGradient(
                  colors: [Colors.grey.shade400, Colors.grey.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : customColors.primaryButtonGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDisabled
                  ? Colors.grey.withAlpha(20)
                  : cs.primary.withAlpha(30),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'CONDUZIR',
            style: TextStyle(
              color: isDisabled ? Colors.grey.shade300 : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
