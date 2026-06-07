import 'package:flutter/material.dart';

abstract final class NsdColors {
  static const ink = Color(0xFF15342D);
  static const green = Color(0xFF2F806A);
  static const greenDark = Color(0xFF1E5C4C);
  static const mint = Color(0xFFE8F4EF);
  static const cream = Color(0xFFF8F5ED);
  static const coral = Color(0xFFE7654F);
  static const gold = Color(0xFFE7A540);
  static const blue = Color(0xFF5579A8);
  static const border = Color(0xFFDCE6E1);
}

ThemeData nsdTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: NsdColors.green,
    brightness: Brightness.light,
    primary: NsdColors.green,
    secondary: NsdColors.gold,
    surface: Colors.white,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF9FBFA),
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: const TextStyle(
        fontSize: 60,
        height: 1.03,
        fontWeight: FontWeight.w800,
        letterSpacing: -2.5,
        color: NsdColors.ink,
      ),
      headlineLarge: const TextStyle(
        fontSize: 38,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: NsdColors.ink,
      ),
      headlineMedium: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: NsdColors.ink,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: NsdColors.ink,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        height: 1.6,
        color: Color(0xFF52645E),
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: Color(0xFF60706B),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: NsdColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: NsdColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF7FAF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: NsdColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: NsdColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: NsdColors.green, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        foregroundColor: NsdColors.ink,
        side: const BorderSide(color: NsdColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
