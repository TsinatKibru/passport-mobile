import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/analytics.dart';
import '../../../../l10n/app_localizations.dart';

/// Width reserved on the left of the plot for the Y-axis value labels.
const double _kYAxisWidth = 26.0;

/// Bar chart of daily total activity, drawn with a CustomPainter.
/// Shows one bar per day with weekday labels beneath and Y-axis value labels
/// on the left. Matches the skeleton shimmer design.
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
    final c = context.colors;
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            AppLocalizations.of(context).chartNoActivity,
            style: AppTextStyles.bodyMedium.copyWith(color: c.textBody),
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
              painter: _TrendPainter(
                points,
                lineColor: c.primary,
                gridColor: c.border,
                labelColor: c.textBody,
                dotInnerColor: c.card,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Offset the day labels by the Y-axis width so they line up under the
          // plotted bars.
          Padding(
            padding: const EdgeInsets.only(left: _kYAxisWidth),
            child: Row(
              children: [
                for (final p in points)
                  Expanded(
                    child: Text(
                      p.shortLabel,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption
                          .copyWith(fontSize: 9, color: c.onSurfaceVariant),
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
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;
  final Color dotInnerColor;

  _TrendPainter(
    this.points, {
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
    required this.dotInnerColor,
  });

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

    // Horizontal gridlines + Y-axis value labels (top = maxV, mid, 0).
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int g = 0; g <= 2; g++) {
      final y = padTop + usableH * (g / 2);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), grid);
      final labelValue = (maxV * (1 - g / 2)).round();
      _drawYLabel(canvas, '$labelValue', y, leftPad - 5, size.height);
    }

    if (n == 0) return;

    final barSpacing = plotW / n;
    // Set a balanced bar width with min/max caps to ensure it looks premium on all screen sizes
    final barWidth = math.max(10.0, math.min(24.0, barSpacing * 0.45));

    for (int i = 0; i < n; i++) {
      final barHeight = usableH * (values[i] / maxV);
      final top = padTop + usableH - barHeight;
      final bottom = padTop + usableH;

      // Calculate center of this segment
      final segmentCenter = leftPad + i * barSpacing + barSpacing / 2;
      final left = segmentCenter - barWidth / 2;
      final right = segmentCenter + barWidth / 2;

      if (values[i] > 0) {
        final rect = Rect.fromLTRB(left, top, right, bottom);
        final rrect = RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
        );

        final barPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lineColor,
              lineColor.withValues(alpha: 0.35),
            ],
          ).createShader(rect);

        canvas.drawRRect(rrect, barPaint);
      } else {
        // Draw a tiny placeholder dot or base pill for zero values to keep visual rhythm
        final zeroRect = Rect.fromLTRB(left, bottom - 3, right, bottom);
        final zeroRrect = RRect.fromRectAndCorners(
          zeroRect,
          topLeft: const Radius.circular(1.5),
          topRight: const Radius.circular(1.5),
          bottomLeft: const Radius.circular(1.5),
          bottomRight: const Radius.circular(1.5),
        );
        final zeroPaint = Paint()..color = lineColor.withValues(alpha: 0.12);
        canvas.drawRRect(zeroRrect, zeroPaint);
      }
    }
  }

  /// Draws a right-aligned Y-axis label centred (vertically) on [centerY],
  /// clamped so the top/bottom labels stay within the canvas.
  void _drawYLabel(
      Canvas canvas, String text, double centerY, double rightX, double maxH) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          color: labelColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final top = (centerY - tp.height / 2).clamp(0.0, maxH - tp.height);
    tp.paint(canvas, Offset(rightX - tp.width, top));
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.points != points ||
      old.lineColor != lineColor ||
      old.gridColor != gridColor ||
      old.labelColor != labelColor ||
      old.dotInnerColor != dotInnerColor;
}
