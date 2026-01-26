import 'package:agromotion/components/camera/camera_control.dart';
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:flutter/material.dart';
import '../components/agro_appbar.dart';
import '../theme/app_theme.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customColors = theme.extension<AppColorsExtension>()!;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(gradient: customColors.backgroundGradient),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const AgroAppBar(title: 'Vista do Robô'),

              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.videocam_off_rounded,
                              color: colorScheme.onSurface.withAlpha(30),
                              size: 80,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "A ligar à VPN (Tailscale)...",
                              style: TextStyle(
                                color: colorScheme.onSurface.withAlpha(60),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: 40,
                              child: LinearProgressIndicator(
                                backgroundColor: colorScheme.primary.withAlpha(
                                  10,
                                ),
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.only(
                        bottom: context.isSmall ? 100 : 120,
                      ),
                      child: CameraControl(
                        onCapturePressed: () => print("Capturar foto"),
                        onRecordPressed: () => print("Gravar vídeo"),
                        onFlipPressed: () => print("Inverter câmara"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
