import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/analytics.dart';

/// Width reserved on the left of the plot for the Y-axis value labels.
const double _kYAxisWidth = 26.0;

/// Area + line chart of daily total activity, drawn with a CustomPainter.
/// Shows one point per day with weekday labels beneath and Y-axis value labels
/// on the left. No dependencies.
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
          // Offset the day labels by the Y-axis width so they line up under the
          // plotted points.
          Padding(
            padding: const EdgeInsets.only(left: _kYAxisWidth),
            child: Row(
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
    final rawMax = values.fold<double>(0, math.max);
    // Round up to a "nice" even ceiling (min 2) so the mid-axis label is a
    // whole number and the line keeps a little headroom below the top.
    final ceil = rawMax.ceil();
    final maxV = (ceil < 2 ? 2 : (ceil.isEven ? ceil : ceil + 1)).toDouble();

    final n = values.length;
    const padTop = 8.0;
    const padBottom = 6.0;
    const leftPad = _kYAxisWidth;
    final usableH = size.height - padTop - padBottom;
    final plotW = size.width - leftPad;
    final dx = n > 1 ? plotW / (n - 1) : 0.0;

    Offset pointAt(int i) {
      final x = n > 1 ? leftPad + i * dx : leftPad + plotW / 2;
      final y = padTop + usableH * (1 - values[i] / maxV);
      return Offset(x, y);
    }

    // Horizontal gridlines + Y-axis value labels (top = maxV, mid, 0).
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (int g = 0; g <= 2; g++) {
      final y = padTop + usableH * (g / 2);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), grid);
      final labelValue = (maxV * (1 - g / 2)).round();
      _drawYLabel(canvas, '$labelValue', y, leftPad - 5, size.height);
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
      ).createShader(Rect.fromLTWH(leftPad, 0, plotW, size.height));
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

  /// Draws a right-aligned Y-axis label centred (vertically) on [centerY],
  /// clamped so the top/bottom labels stay within the canvas.
  void _drawYLabel(
      Canvas canvas, String text, double centerY, double rightX, double maxH) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          color: AppColors.textBody,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final top = (centerY - tp.height / 2).clamp(0.0, maxH - tp.height);
    tp.paint(canvas, Offset(rightX - tp.width, top));
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.points != points;
}
