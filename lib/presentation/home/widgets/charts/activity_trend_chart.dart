import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/analytics.dart';

/// Area + line chart of daily total activity, drawn with a CustomPainter.
/// Shows one point per day with weekday labels beneath. No dependencies.
class ActivityTrendChart extends StatelessWidget {
  final List<ActivityTrendPoint> points;
  final double height;

  const ActivityTrendChart({
    super.key,
    required this.points,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No activity in this period',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textBody),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _TrendPainter(points),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final p in points)
                Expanded(
                  child: Text(
                    p.shortLabel,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(fontSize: 9),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<ActivityTrendPoint> points;
  _TrendPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((p) => p.total.toDouble()).toList();
    final maxV = math.max(1.0, values.fold<double>(0, math.max));
    final n = values.length;
    const padTop = 10.0;
    final usableH = size.height - padTop;
    final dx = n > 1 ? size.width / (n - 1) : 0.0;

    Offset pointAt(int i) {
      final x = n > 1 ? i * dx : size.width / 2;
      final y = padTop + usableH * (1 - values[i] / maxV);
      return Offset(x, y);
    }

    // Faint horizontal gridlines for a clean line-graph feel
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (int g = 0; g <= 2; g++) {
      final y = padTop + usableH * (g / 2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final pts = [for (int i = 0; i < n; i++) pointAt(i)];

    // Smooth line through the points (Catmull-Rom -> cubic bezier)
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < n - 1; i++) {
      final p0 = pts[i == 0 ? 0 : i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[i + 2 < n ? i + 2 : n - 1];
      final cp1 =
          Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final cp2 =
          Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      line.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    // Very subtle fill under the smooth line
    final area = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.10),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(area, areaPaint);

    // Smooth line stroke
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.primary;
    canvas.drawPath(line, stroke);

    // Point markers
    final dot = Paint()..color = AppColors.primary;
    final dotInner = Paint()..color = Colors.white;
    for (final p in pts) {
      canvas.drawCircle(p, 3.2, dot);
      canvas.drawCircle(p, 1.5, dotInner);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.points != points;
}
