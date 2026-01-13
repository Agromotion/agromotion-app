import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedWavePainter extends CustomPainter {
  final double animationValue;
  final bool isTop;
  final Color color1;
  final Color color2;

  AnimatedWavePainter({
    required this.animationValue, 
    required this.isTop,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2.withOpacity(0.6);

    _drawWave(canvas, size, paint2, animationValue, 0.4, 10); // Onda de trás
    _drawWave(canvas, size, paint1, animationValue, 0.5, 0);  // Onda da frente
  }

  void _drawWave(Canvas canvas, Size size, Paint paint, double anim, double heightFactor, double offset) {
    final path = Path();
    
    // Ajuste para ondas no topo ou no fundo
    double baseHeight = isTop ? 0 : size.height;
    double waveHeight = isTop ? size.height * heightFactor : size.height * (1 - heightFactor);

    path.moveTo(0, baseHeight);
    path.lineTo(0, waveHeight);

    // Criamos o movimento senoidal usando ciclos
    for (double i = 0; i <= size.width; i++) {
      double dx = i;
      // O cálculo do Sin cria o efeito de oscilação
      double dy = waveHeight + 
          math.sin((i / size.width * 2 * math.pi) + (anim * 2 * math.pi) + offset) * 15;
      path.lineTo(dx, dy);
    }

    path.lineTo(size.width, baseHeight);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(AnimatedWavePainter oldDelegate) => true;
}