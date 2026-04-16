import 'dart:async';
import 'package:agromotion/config/app_config.dart';
import 'package:agromotion/models/metric_data.dart';
import 'package:agromotion/widgets/home/home_action_button.dart';
import 'package:agromotion/widgets/statistics/realtime_panel.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agromotion/widgets/agro_appbar.dart';
import 'package:agromotion/screens/camera_screen.dart';
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
  String get _robotId => AppConfig.robotId;

  StreamSubscription? _robotSubscription;

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
          final telemetry = data['telemetry'] as Map<String, dynamic>? ?? {};

          setState(() {
            _isOnline = status['online'] ?? false;
            _realtime = TelemetrySnapshot.fromMap(telemetry);
          });
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
                  padding: const EdgeInsets.fromLTRB(24, 5, 24, 200),
                  sliver: SliverToBoxAdapter(
                    child: RealtimePanel(snapshot: _realtime),
                  ),
                ),
              ],
            ),

            // Botão de Ação fixo acima da NavBar
            Positioned(
              bottom: 110,
              left: 24,
              right: 24,
              child: HomeActionButton(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CameraScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
