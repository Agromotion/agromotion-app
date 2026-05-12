import 'package:agromotion/screens/camera_screen.dart';
import 'package:flutter/material.dart';
import 'package:agromotion/theme/app_theme.dart';

class ControlRobotButton extends StatelessWidget {
  const ControlRobotButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<AppColorsExtension>()!;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CameraScreen()),
        );
      },
      child: Container(
        height: 65,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: customColors.primaryButtonGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withAlpha(30),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'CONDUZIR',
            style: TextStyle(
              color: Colors.white,
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
