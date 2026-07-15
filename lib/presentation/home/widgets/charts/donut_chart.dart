import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// One slice of a [DonutChart].
class DonutSegment {
  final double value;
  final Color color;
  const DonutSegment(this.value, this.color);
}

/// Lightweight donut/ring chart drawn with a CustomPainter — no dependencies.
/// Renders [segments] proportionally around the ring; [center] is stacked in
/// the middle (e.g. a big number + label). When all values are zero it shows
/// just the empty track.
class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final double size;
  final double thickness;
  final Widget? center;

  const DonutChart({
    super.key,
    required this.segments,
    this.size = 120,
    this.thickness = 14,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(
                segments: segments,
                thickness: thickness,
                trackColor: context.colors.border),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double thickness;
  final Color trackColor;

  _DonutPainter(
      {required this.segments,
      required this.thickness,
      required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - thickness) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = segments.fold<double>(
        0, (sum, s) => sum + (s.value > 0 ? s.value : 0));

    // Background track
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (total <= 0) return;

    const start0 = -math.pi / 2; // start at 12 o'clock
    const gap = 0.05; // gap between slices (radians)
    double cursor = start0;
    for (final s in segments) {
      if (s.value <= 0) continue;
      final full = (s.value / total) * (2 * math.pi);
      final sweep = full - gap;
      if (sweep > 0) {
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round
          ..color = s.color;
        canvas.drawArc(rect, cursor + gap / 2, sweep, false, paint);
      }
      cursor += full;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments ||
      old.thickness != thickness ||
      old.trackColor != trackColor;
}
