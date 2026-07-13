import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  final Color color;
  final double waveHeightPercent; // 0.0 to 1.0, representing how high the wave goes

  WavePainter({
    required this.color,
    this.waveHeightPercent = 0.35,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Start at bottom-left corner
    path.moveTo(0, size.height);
    
    // Line up to start the wave
    path.lineTo(0, size.height * (1.0 - waveHeightPercent));
    
    // Wave bezier curve 1
    path.cubicTo(
      size.width * 0.25, size.height * (1.0 - waveHeightPercent - 0.15),
      size.width * 0.45, size.height * (1.0 - waveHeightPercent + 0.15),
      size.width * 0.7, size.height * (1.0 - waveHeightPercent - 0.05),
    );
    
    // Wave bezier curve 2
    path.quadraticBezierTo(
      size.width * 0.88, size.height * (1.0 - waveHeightPercent - 0.15),
      size.width, size.height * (1.0 - waveHeightPercent + 0.05),
    );
    
    // Line down to bottom-right corner
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Draw a secondary overlapping wave for depth
    final secondaryPaint = Paint()
      ..color = color.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    final secondaryPath = Path();
    secondaryPath.moveTo(0, size.height);
    secondaryPath.lineTo(0, size.height * (1.0 - waveHeightPercent * 0.8));
    
    secondaryPath.cubicTo(
      size.width * 0.3, size.height * (1.0 - waveHeightPercent * 0.8 + 0.1),
      size.width * 0.6, size.height * (1.0 - waveHeightPercent * 0.8 - 0.2),
      size.width, size.height * (1.0 - waveHeightPercent * 0.8),
    );
    
    secondaryPath.lineTo(size.width, size.height);
    secondaryPath.close();
    
    canvas.drawPath(secondaryPath, secondaryPaint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.waveHeightPercent != waveHeightPercent;
  }
}
