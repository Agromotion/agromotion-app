import 'dart:async';
import 'package:agromotion/config/app_config.dart';
import 'package:agromotion/models/metric_data.dart';
import 'package:agromotion/widgets/home/auto_mode_switch.dart';
import 'package:agromotion/widgets/home/control_robot_button.dart';
import 'package:agromotion/widgets/statistics/realtime_panel.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agromotion/widgets/agro_appbar.dart';
import 'package:agromotion/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.isVisible = true});
  final bool isVisible;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isOnline = false;
  TelemetrySnapshot _realtime = const TelemetrySnapshot();
  bool _isControllerActive = false;
  String get _robotId => AppConfig.robotId;

  StreamSubscription? _robotSubscription;
  Timer? _heartbeatTimer;
  Timestamp? _lastHeartbeat;
  DateTime? _lastHeartbeatLocalTime;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _listenToRobotStatus();
  }

  @override
  void dispose() {
    _robotSubscription?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  void _listenToRobotStatus() {
    _robotSubscription = FirebaseFirestore.instance
        .collection('robots')
        .doc(_robotId)
        .snapshots()
        .listen((snap) {
          if (!snap.exists || !mounted) return;

          final data = snap.data()!;
          final status = data['status'] as Map<String, dynamic>? ?? {};
          final control = data['control'] as Map<String, dynamic>? ?? {};

          // Cria um map mutável e injeta a contagem de clientes vinda do 'status'
          final telemetry = Map<String, dynamic>.from(
            data['telemetry'] as Map<String, dynamic>? ?? {},
          );
          telemetry['video_client_count'] = status['video_client_count'] ?? 0;

          final activeControllerEmail =
              control['active_controller_email'] as String?;
          final isControllerActive =
              activeControllerEmail != null && activeControllerEmail.isNotEmpty;

          bool isOnline = status['online'] ?? false;
          final newHeartbeat = telemetry['timestamp'] as Timestamp?;

          // Se recebemos um timestamp novo, guardamos a nossa HORA LOCAL do telemóvel
          if (newHeartbeat != null && newHeartbeat != _lastHeartbeat) {
            _lastHeartbeat = newHeartbeat;
            _lastHeartbeatLocalTime = DateTime.now();
          }

          // 1. Verificação passiva a cada snapshot (Garante a verificação mal a app é iniciada)
          if (_lastHeartbeatLocalTime != null && isOnline) {
            final diff = DateTime.now()
                .difference(_lastHeartbeatLocalTime!)
                .inSeconds;
            if (diff > 120) {
              isOnline = false;
              FirebaseFirestore.instance
                  .collection('robots')
                  .doc(_robotId)
                  .update({'status.online': false});
            }
          }

          setState(() {
            _isOnline = isOnline;
            _realtime = TelemetrySnapshot.fromMap(telemetry);
            _isControllerActive = isControllerActive;
          });
        });

    // 2. Verificação ativa em loop (Para detetar falhas de energia em tempo real quando o Firebase para de receber atualizações)
    _heartbeatTimer ??= Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || !_isOnline || _lastHeartbeatLocalTime == null) return;
      final diff = DateTime.now()
          .difference(_lastHeartbeatLocalTime!)
          .inSeconds;
      if (diff > 120) {
        setState(() => _isOnline = false);
        FirebaseFirestore.instance.collection('robots').doc(_robotId).update({
          'status.online': false,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final customColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      backgroundColor: customColors.backgroundBaseColor,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: customColors.backgroundGradient),
        child: Stack(
          children: [
            // ScrollView com SliverAppBar + conteúdo
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                AgroAppBar(
                  isOnline: _isOnline,
                  title: 'Agromotion',
                  showStatus: true,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 5, 24, 250),
                  sliver: SliverToBoxAdapter(
                    child: RealtimePanel(snapshot: _realtime),
                  ),
                ),
              ],
            ),

            // Controles na parte inferior
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Switch de Automático
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 1.0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: AutoModeSwitch(
                      isControllerActive: _isControllerActive,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Botão de Controlar Robô
                  const ControlRobotButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
