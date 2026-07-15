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

    // Baseline
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      grid,
    );

    // Line path
    final line = Path();
    for (int i = 0; i < n; i++) {
      final p = pointAt(i);
      i == 0 ? line.moveTo(p.dx, p.dy) : line.lineTo(p.dx, p.dy);
    }

    // Area fill under the line
    final area = Path.from(line)
      ..lineTo(pointAt(n - 1).dx, size.height)
      ..lineTo(pointAt(0).dx, size.height)
      ..close();
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.22),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(area, areaPaint);

    // Line stroke
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
    for (int i = 0; i < n; i++) {
      final p = pointAt(i);
      canvas.drawCircle(p, 3.5, dot);
      canvas.drawCircle(p, 1.6, dotInner);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.points != points;
}
