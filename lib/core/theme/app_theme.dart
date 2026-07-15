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

  // Accent — secondary chart series (e.g. In-vault / Box-moved)
  static const accentSlate = Color(0xFF5B6B9E);

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

  // Dark theme. Mirrors `light` but sourced from AppPalette.dark. Screens that
  // still reference the legacy `AppColors` const stay light until migrated to
  // `context.colors`; this ThemeData drives Material defaults + migrated screens.
  static ThemeData get dark {
    final p = AppPalette.dark;
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.primaryLight,
      onSecondary: p.onPrimary,
      error: p.danger,
      onError: p.onDanger,
      surface: p.surface,
      onSurface: p.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.surface,
      fontFamily: 'Inter',

      appBarTheme: AppBarTheme(
        backgroundColor: p.appBar,
        foregroundColor: p.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: p.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.border),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: p.onSurfaceVariant),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: p.onSurfaceVariant),
      ),

      dividerTheme: DividerThemeData(color: p.border, space: 1),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: p.onSurface),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: p.onSurface),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: p.onSurface),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: p.onSurface),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: p.onSurface),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: p.onSurface),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: p.onSurface),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: p.onSurfaceVariant),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppPalette — semantic colour tokens resolved per active brightness.
// Migrated widgets read these via `context.colors.<token>` (see extension
// below) instead of the legacy `AppColors` const. `light` mirrors AppColors
// exactly so light mode is unchanged; `dark` is the dark-mode counterpart.
// ─────────────────────────────────────────────────────────────────────────────
class AppPalette {
  // Brand
  final Color primary, primaryLight, primaryDark, onPrimary;
  // Surfaces
  final Color surface, surfaceVariant, onSurface, onSurfaceVariant;
  // Text
  final Color textPrimary, textSecondary, textBody, textHint;
  // Lines / inputs
  final Color border, inputFill;
  // Semantic states
  final Color success, onSuccess, warning, onWarning, danger, onDanger;
  // Accent + status chips
  final Color accentSlate;
  final Color statusInBox, statusIssued, statusFull, statusActive, statusInactive;
  // Elevated card / app-bar surfaces (were hardcoded Colors.white in widgets)
  final Color card, appBar;

  const AppPalette({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.onPrimary,
    required this.surface,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textBody,
    required this.textHint,
    required this.border,
    required this.inputFill,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
    required this.accentSlate,
    required this.statusInBox,
    required this.statusIssued,
    required this.statusFull,
    required this.statusActive,
    required this.statusInactive,
    required this.card,
    required this.appBar,
  });

  static const light = AppPalette(
    primary: Color(0xFF174da7),
    primaryLight: Color(0xFF3B82F6),
    primaryDark: Color(0xFF0F3A7A),
    onPrimary: Color(0xFFFFFFFF),
    surface: Color(0xFFF8FAFC),
    surfaceVariant: Color(0xFFEFF6FF),
    onSurface: Color(0xFF0F172A),
    onSurfaceVariant: Color(0xFF64748B),
    textPrimary: Color(0xFF174da7),
    textSecondary: Color(0xFF94A3B8),
    textBody: Color(0xFF64748B),
    textHint: Color(0xFFCBD5E1),
    border: Color(0xFFE2E8F0),
    inputFill: Color(0xFFF8FAFC),
    success: Color(0xFF009E60),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFF4B400),
    onWarning: Color(0xFFFFFFFF),
    danger: Color(0xFFEF2B2D),
    onDanger: Color(0xFFFFFFFF),
    accentSlate: Color(0xFF5B6B9E),
    statusInBox: Color(0xFF174da7),
    statusIssued: Color(0xFF009E60),
    statusFull: Color(0xFFEF2B2D),
    statusActive: Color(0xFF009E60),
    statusInactive: Color(0xFF94A3B8),
    card: Color(0xFFFFFFFF),
    appBar: Color(0xFFFFFFFF),
  );

  static const dark = AppPalette(
    primary: Color(0xFF3B82F6),
    primaryLight: Color(0xFF60A5FA),
    primaryDark: Color(0xFF93B4F0),   // light blue — used as heading text on dark
    onPrimary: Color(0xFFFFFFFF),
    surface: Color(0xFF0F172A),        // slate-900
    surfaceVariant: Color(0xFF1E293B), // slate-800
    onSurface: Color(0xFFE2E8F0),
    onSurfaceVariant: Color(0xFF94A3B8),
    textPrimary: Color(0xFF93B4F0),
    textSecondary: Color(0xFF94A3B8),
    textBody: Color(0xFFAAB4C4),
    textHint: Color(0xFF64748B),
    border: Color(0xFF334155),         // slate-700
    inputFill: Color(0xFF1E293B),
    success: Color(0xFF12B981),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFF5C242),
    onWarning: Color(0xFFFFFFFF),
    danger: Color(0xFFF0555A),
    onDanger: Color(0xFFFFFFFF),
    accentSlate: Color(0xFF8B9DC9),
    statusInBox: Color(0xFF3B82F6),
    statusIssued: Color(0xFF12B981),
    statusFull: Color(0xFFF0555A),
    statusActive: Color(0xFF12B981),
    statusInactive: Color(0xFF64748B),
    card: Color(0xFF1E293B),
    appBar: Color(0xFF0F172A),
  );
}

/// Access the active [AppPalette] for the current theme brightness.
/// Usage in migrated widgets: `context.colors.primary`, `context.colors.surface`…
extension AppColorsX on BuildContext {
  AppPalette get colors => Theme.of(this).brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;
}
