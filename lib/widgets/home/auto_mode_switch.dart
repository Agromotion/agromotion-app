import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agromotion/config/app_config.dart';
import 'package:agromotion/widgets/agro_snackbar.dart';

class AutoModeSwitch extends StatefulWidget {
  final bool isControllerActive;

  const AutoModeSwitch({super.key, this.isControllerActive = false});

  @override
  State<AutoModeSwitch> createState() => _AutoModeSwitchState();
}

class _AutoModeSwitchState extends State<AutoModeSwitch> {
  late FirebaseFirestore _firestore;
  bool _isAutoModeOn = false;
  bool _isLoading = false;
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
          bool isOnline = statusMap['online'] ?? false;

          setState(() {
            _isAutoModeOn = isAutoMode;
            _isOnline = isOnline;
          });
        });
  }

  Future<void> _toggleAutoMode(bool value) async {
    if (value && widget.isControllerActive) {
      AgroSnackbar.show(
        context,
        message:
            'Alguém está a controlar o robô. Desative para ativar automático.',
        isError: true,
      );
      return;
    }

    // Atualiza localmente imediatamente para feedback visual
    setState(() {
      _isAutoModeOn = value;
      _isLoading = true;
    });

    try {
      // Atualiza ambos os campos para sincronização completa
      await _firestore.collection('robots').doc(_robotId).update({
        'status.autoMode': value,
      });

      if (!mounted) return;

      final message = value
          ? 'Modo automático ativado'
          : 'Modo automático desativado';
      AgroSnackbar.show(context, message: message);
    } catch (e) {
      if (!mounted) return;
      // Reverte o estado local se falhar
      setState(() {
        _isAutoModeOn = !value;
      });
      AgroSnackbar.show(
        context,
        message: 'Erro ao atualizar modo automático',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Simplificado: se estiver a carregar ou se o controller estiver ativo, desativa o switch
    // Mas se o switch já estiver ligado (true), permitimos desligar mesmo com o controller ativo,
    // ou mantemos bloqueado conforme a sua regra de negócio.
    final isDisabled = widget.isControllerActive || _isLoading || !_isOnline;

    return Row(
      children: [
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Modo Automático',
                style: TextStyle(
                  color: isDisabled
                      ? cs.onSurface.withAlpha(128)
                      : cs.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.isControllerActive)
                Text(
                  'Alguém está a conduzir',
                  style: TextStyle(
                    color: cs.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
        Switch.adaptive(
          value: _isAutoModeOn,
          onChanged: isDisabled ? null : _toggleAutoMode,
          activeThumbColor: Colors.green,
          inactiveThumbColor: Colors.grey.shade400,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
