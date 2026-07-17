import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final Color? borderColor;
  final double borderWidth;
  final Gradient? gradient;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Clip clipBehavior;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.boxShadow,
    this.borderColor,
    this.borderWidth = 1.0,
    this.gradient,
    this.backgroundColor,
    this.padding,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBorderColor = borderColor ??
        (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6));
    
    final defaultGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Colors.white.withOpacity(0.07),
              Colors.white.withOpacity(0.02),
            ]
          : [
              Colors.white.withOpacity(0.85),
              Colors.white.withOpacity(0.65),
            ],
    );

    final defaultShadows = isDark
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0xFF1E293B).withOpacity(0.04), // Slate-800
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF1E293B).withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ];

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? (gradient == null ? (isDark ? Colors.white.withOpacity(0.05) : Colors.white) : null),
        gradient: backgroundColor == null ? (gradient ?? defaultGradient) : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: cardBorderColor,
          width: borderWidth,
        ),
        boxShadow: boxShadow ?? defaultShadows,
      ),
      clipBehavior: clipBehavior,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
