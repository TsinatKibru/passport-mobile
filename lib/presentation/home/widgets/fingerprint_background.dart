import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class FingerprintBackground extends StatelessWidget {
  final Widget child;
  final bool showWatermark;

  const FingerprintBackground({
    super.key,
    required this.child,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (showWatermark)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _FingerprintWatermarkPainter(),
              ),
            ),
          ),
        child,
      ],
    );
  }
}

class _FingerprintWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // We will draw faint fingerprint patterns and security lines.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppColors.primary.withOpacity(0.025); // Extremely subtle

    // Draw passport security wavy lines across the screen
    final wavyPath1 = Path();
    wavyPath1.moveTo(0, size.height * 0.15);
    for (double i = 0; i <= size.width; i += 2) {
      wavyPath1.lineTo(
        i,
        size.height * 0.15 +
            math.sin(i * 0.02) * 15 +
            math.cos(i * 0.005) * 10,
      );
    }
    canvas.drawPath(wavyPath1, paint);

    final wavyPath2 = Path();
    wavyPath2.moveTo(0, size.height * 0.7);
    for (double i = 0; i <= size.width; i += 2) {
      wavyPath2.lineTo(
        i,
        size.height * 0.7 +
            math.cos(i * 0.015) * 12 +
            math.sin(i * 0.008) * 8,
      );
    }
    canvas.drawPath(wavyPath2, paint);

    // Draw stylized concentric fingerprint arches/loops at bottom right or center
    final center = Offset(size.width * 0.85, size.height * 0.85);
    for (int r = 30; r < 280; r += 12) {
      final rect = Rect.fromCircle(center: center, radius: r.toDouble());
      final path = Path();
      // Draw an arch with slight random noise to look hand-drawn / organic
      double startAngle = math.pi * 0.9;
      double sweepAngle = math.pi * 1.2;
      
      path.addArc(rect, startAngle, sweepAngle);
      
      // Let's distort the path slightly to give a fingerprint texture
      final distortedPath = Path();
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        final length = metric.length;
        bool isFirst = true;
        for (double d = 0; d < length; d += 4) {
          final tangent = metric.getTangentForOffset(d);
          if (tangent != null) {
            final pos = tangent.position;
            // Introduce a subtle sine distortion based on position
            final offsetFactor = math.sin(d * 0.05 + r) * 1.5;
            final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
            final distortedPos = pos + normal * offsetFactor;
            
            if (isFirst) {
              distortedPath.moveTo(distortedPos.dx, distortedPos.dy);
              isFirst = false;
            } else {
              distortedPath.lineTo(distortedPos.dx, distortedPos.dy);
            }
          }
        }
      }
      canvas.drawPath(distortedPath, paint);
    }

    // Draw secondary fingerprint loop at top left
    final centerTopLeft = Offset(size.width * 0.15, size.height * 0.1);
    for (int r = 20; r < 180; r += 14) {
      final rect = Rect.fromCircle(center: centerTopLeft, radius: r.toDouble());
      final path = Path();
      path.addArc(rect, -math.pi * 0.2, math.pi * 1.1);
      canvas.drawPath(path, paint);
    }

    // Draw Ethiopian geometric micro-patterns at some corners (very subtle star or diamond)
    final starPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withOpacity(0.015);
    
    _drawEthiopianStar(canvas, Offset(size.width * 0.5, size.height * 0.4), 60, starPaint);
  }

  void _drawEthiopianStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    int points = 8;
    double outerRadius = size / 2;
    double innerRadius = size / 4;
    double angle = math.pi / points;

    for (int i = 0; i < 2 * points; i++) {
      double r = (i % 2 == 0) ? outerRadius : innerRadius;
      double currAngle = i * angle;
      double x = center.dx + math.cos(currAngle) * r;
      double y = center.dy + math.sin(currAngle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
