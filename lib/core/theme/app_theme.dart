import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────
///  AppColors — single source of truth for all design tokens
/// ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Primary (Sky Blue) ──────────────────────────────────────
  static const Color primary        = Color(0xFF0EA5E9); // Sky 500
  static const Color primaryDark    = Color(0xFF0284C7); // Sky 600
  static const Color primaryDeep    = Color(0xFF0369A1); // Sky 700
  static const Color accent         = Color(0xFF38BDF8); // Sky 400 − glow / highlights

  // ── Surface (dark mode) ─────────────────────────────────────
  static const Color bgDark         = Color(0xFF0A1929);
  static const Color surfaceDark    = Color(0xFF132F4C);
  static const Color surfaceDim     = Color(0xFF0C1F35);
  static const Color borderDark     = Color(0xFF1E4976);
  static const Color borderDimDark  = Color(0xFF374151);

  // ── Surface (light mode) ────────────────────────────────────
  static const Color bgLight        = Color(0xFFF0F9FF);
  static const Color surfaceLight   = Colors.white;
  static const Color borderLight    = Color(0xFFE5E7EB);
  static const Color borderAccentLight = Color(0xFFBAE6FD);

  // ── Text (dark) ─────────────────────────────────────────────
  static const Color textPrimaryDark   = Colors.white;
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textDimDark       = Color(0xFF6B7280);
  static const Color textHintDark      = Color(0xFF4B5563);

  // ── Text (light) ────────────────────────────────────────────
  static const Color textPrimaryLight   = Color(0xFF1F2937);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textHintLight      = Color(0xFF9CA3AF);

  // ── Semantic ────────────────────────────────────────────────
  // Using cyan-blue family only — no green anywhere
  static const Color success  = Color(0xFF22D3EE); // Cyan 400
  static const Color error    = Color(0xFFF87171); // Red 400
  static const Color warning  = Color(0xFFFBBF24); // Amber 400
  static const Color info     = Color(0xFF38BDF8); // Sky 400

  // ── Gradients ───────────────────────────────────────────────
  static const List<Color> gradientPrimary   = [Color(0xFF0369A1), Color(0xFF0EA5E9)];
  static const List<Color> gradientAccent    = [Color(0xFF0EA5E9), Color(0xFF38BDF8)];
  static const List<Color> gradientBgDark    = [Color(0xFF0F172A), Color(0xFF020617)];
  static const List<Color> gradientBgLight   = [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFBAE6FD)];
  static const List<Color> gradientAppBar    = [Color(0xFF0369A1), Color(0xFF0EA5E9)];

  // ── Shadow helpers ──────────────────────────────────────────
  static List<BoxShadow> glowShadow({double intensity = 0.15}) => [
    BoxShadow(color: primary.withValues(alpha: intensity), blurRadius: 16, spreadRadius: 1, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> cardShadow() => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
  ];
}

/// ─────────────────────────────────────────────────────────────
///  AppSpacing
/// ─────────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double base = 16;
  static const double lg   = 24;
  static const double xl   = 32;
  static const double xxl  = 48;
}

/// ─────────────────────────────────────────────────────────────
///  AppRadius
/// ─────────────────────────────────────────────────────────────
class AppRadius {
  AppRadius._();
  static const double sm   = 8;
  static const double md   = 12;
  static const double card = 16;
  static const double lg   = 24;
  static const double pill = 28;
  static const double full = 999;
}

/// ─────────────────────────────────────────────────────────────
///  AppTheme — Flutter ThemeData
/// ─────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final baseColor = isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark;
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge:  base.displayLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 28, color: baseColor),
      displayMedium: base.displayMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 22, color: baseColor),
      displaySmall:  base.displaySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 18, color: baseColor),
      headlineMedium:base.headlineMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16, color: baseColor),
      titleLarge:    base.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 16, color: baseColor),
      titleMedium:   base.titleMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 14, color: baseColor),
      bodyLarge:     base.bodyLarge?.copyWith(fontSize: 14, height: 1.6, color: baseColor),
      bodyMedium:    base.bodyMedium?.copyWith(fontSize: 13, height: 1.5, color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark),
      bodySmall:     base.bodySmall?.copyWith(fontSize: 12, color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark),
      labelLarge:    base.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
    );
  }

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary:   AppColors.primary,
      secondary: AppColors.accent,
      surface:   AppColors.surfaceLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
    ),
    scaffoldBackgroundColor: AppColors.bgLight,
    textTheme: _buildTextTheme(Brightness.light),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.textHintLight, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.primary,
      secondary: AppColors.accent,
      surface:   AppColors.surfaceDark,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryDark,
    ),
    scaffoldBackgroundColor: AppColors.bgDark,
    textTheme: _buildTextTheme(Brightness.dark),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: const BorderSide(color: AppColors.borderDark, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: const BorderSide(color: AppColors.borderDark, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.textHintDark, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );
}
