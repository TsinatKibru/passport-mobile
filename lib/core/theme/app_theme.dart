import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppColors — CONVENTIONS.md §2
// All colors used in the app are defined here.
// NEVER use Color(0xFF...) or Colors.* directly in widget code.
// ─────────────────────────────────────────────────────────────────────────────
abstract class AppColors {
  // Brand - ICS Official Colors
  static const primary = Color(0xFF174da7);       // ICS Blue (from logo)
  static const primaryLight = Color(0xFF3B82F6);  // Light Blue
  static const primaryDark = Color(0xFF0F3A7A);   // Darker blue for text
  static const onPrimary = Color(0xFFFFFFFF);

  // Surface
  static const surface = Color(0xFFF8FAFC);
  static const surfaceVariant = Color(0xFFEFF6FF);
  static const onSurface = Color(0xFF0F172A);
  static const onSurfaceVariant = Color(0xFF64748B);
  
  // Text colors
  static const textPrimary = Color(0xFF174da7);     // ICS blue for headings
  static const textSecondary = Color(0xFF94A3B8);   // Light gray for subtitles
  static const textBody = Color(0xFF64748B);        // Medium gray for body text
  static const textHint = Color(0xFFCBD5E1);        // Lighter gray for hints

  // Border / divider
  static const border = Color(0xFFE2E8F0);
  static const inputFill = Color(0xFFF8FAFC);       // Input background

  // Semantic states
  static const success = Color(0xFF009E60);       // Ethiopian flag green
  static const onSuccess = Color(0xFFFFFFFF);

  static const warning = Color(0xFFF4B400);       // Ethiopian flag yellow
  static const onWarning = Color(0xFFFFFFFF);

  static const danger = Color(0xFFEF2B2D);        // Ethiopian flag red
  static const onDanger = Color(0xFFFFFFFF);

  // Status chips — matches PassportStatus / BoxStatus from schema
  static const statusInBox = Color(0xFF174da7);
  static const statusIssued = Color(0xFF009E60);
  static const statusFull = Color(0xFFEF2B2D);
  static const statusActive = Color(0xFF009E60);
  static const statusInactive = Color(0xFF94A3B8);
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTextStyles — pull from theme, never hardcode font sizes
// ─────────────────────────────────────────────────────────────────────────────
abstract class AppTextStyles {
  static const _base = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.onSurface,
    decoration: TextDecoration.none,
  );

  static final displayLarge = _base.copyWith(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2);
  static final displayMedium = _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3);
  static final titleLarge   = _base.copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4);
  static final titleMedium  = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);
  static final bodyLarge    = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static final bodyMedium   = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static final labelLarge   = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static final labelSmall   = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.4, color: AppColors.onSurfaceVariant);
  static final caption      = _base.copyWith(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant);
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme — the single ThemeData used by MaterialApp
// ─────────────────────────────────────────────────────────────────────────────
abstract class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.onPrimary,
      error: AppColors.danger,
      onError: AppColors.onDanger,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: 'Inter',

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
        labelStyle: AppTextStyles.bodyMedium,
      ),

      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        labelLarge: AppTextStyles.labelLarge,
        labelSmall: AppTextStyles.labelSmall,
      ),
    );
  }
}
