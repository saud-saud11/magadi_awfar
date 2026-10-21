import 'package:flutter/material.dart';

/// Magadi Awfar design system — luxurious emerald + gold, Tajawal typography.
class AppTheme {
  // ── Brand palette ──────────────────────────────────────────────
  static const Color primary = Color(0xFF0E7C66); // Deep emerald
  static const Color primaryLight = Color(0xFF14B88F); // Bright emerald
  static const Color primaryDark = Color(0xFF064E40); // Night emerald
  static const Color primaryContainer = Color(0xFFE6F6F1); // Mint wash
  static const Color teal = Color(0xFF0B8A8F);

  static const Color background = Color(0xFFFAF8F3); // Warm ivory
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF3F0E8);
  static const Color textDark = Color(0xFF14211D);
  static const Color textMuted = Color(0xFF6B7B76);

  static const Color accentGold = Color(0xFFD4A24C);
  static const Color goldLight = Color(0xFFF5E3BC);
  static const Color warning = Color(0xFFF97316);
  static const Color danger = Color(0xFFE5484D);
  static const Color success = Color(0xFF12A150);
  static const Color border = Color(0xFFEAE6DC);

  static const String fontFamily = 'Tajawal';

  // ── Gradients ─────────────────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF053F35), Color(0xFF0E7C66), Color(0xFF0B8A8F)],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFE9C27A), Color(0xFFC48F35)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient emeraldButton = LinearGradient(
    colors: [Color(0xFF14B88F), Color(0xFF0E7C66)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  // ── Shadows ───────────────────────────────────────────────────
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF0E3B33).withOpacity(0.06),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: const Color(0xFF0E3B33).withOpacity(0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> glowShadow(Color c) => [
    BoxShadow(
      color: c.withOpacity(0.35),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static const double radius = 22;

  static ThemeData get lightTheme {
    final base = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accentGold,
      surface: surface,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: textDark,
          height: 1.3,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, color: textDark),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: textDark),
        bodyLarge: TextStyle(color: textDark, height: 1.5),
        bodyMedium: TextStyle(color: textDark, height: 1.5),
        bodySmall: TextStyle(color: textMuted, height: 1.4),
        labelLarge: TextStyle(fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          fontFamily: fontFamily,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.2),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: const BorderSide(color: border),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: textDark,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textMuted, fontFamily: fontFamily),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryDark,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : null,
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      pageTransitionsTheme: const PageTransitionsTheme(),
    );
  }
}
