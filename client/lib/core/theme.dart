import 'package:flutter/material.dart';

abstract final class NsdColors {
  static const primary = Color(0xFFC4333B);
  static const primaryDark = Color(0xFFA82930);
  static const surface = Color(0xFFFFFAF8);
  static const blush = Color(0xFFFCE7E3);
  static const cream = Color(0xFFF8F2EC);
  static const mint = Color(0xFFF0DFD9);
  static const beige = Color(0xFFF7E8DE);
  static const ink = Color(0xFF2B1D1B);
  static const muted = Color(0xFF7E6862);
  static const border = Color(0xFFE8D7D1);
  static const green = Color(0xFF3D8A73);
  static const blue = Color(0xFF4E71C7);
  static const gold = Color(0xFFC68B38);
  static const coral = Color(0xFFD94E45);
}

ThemeData nsdTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: NsdColors.primary,
    brightness: Brightness.light,
    primary: NsdColors.primary,
    secondary: NsdColors.green,
    surface: Colors.white,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: NsdColors.surface,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: NsdColors.ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: NsdColors.border),
      ),
    ),
    textTheme: base.textTheme.copyWith(
      displayLarge: const TextStyle(
        fontSize: 54,
        height: 1.03,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.8,
        color: NsdColors.ink,
      ),
      headlineLarge: const TextStyle(
        fontSize: 34,
        height: 1.08,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.1,
        color: NsdColors.ink,
      ),
      headlineMedium: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: NsdColors.ink,
      ),
      titleLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: NsdColors.ink,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        height: 1.55,
        color: NsdColors.muted,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: NsdColors.muted,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFFF7F5),
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
        borderSide: const BorderSide(color: NsdColors.primary, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NsdColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        foregroundColor: NsdColors.primary,
        side: const BorderSide(color: NsdColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
