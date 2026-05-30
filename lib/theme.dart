import 'package:flutter/material.dart';

const Color bg = Color(0xFF0F172A);
const Color surface = Color(0xFF1E293B);
const Color surface2 = Color(0xFF334155);
const Color indigo = Color(0xFF6366F1);
const Color indigoLight = Color(0xFF818CF8);
const Color indigoFaint = Color(0xFFA5B4FC);
const Color teal = Color(0xFF14B8A6);
const Color green = Color(0xFF4ADE80);
const Color amber = Color(0xFFFBBF24);
const Color orange = Color(0xFFF97316);
const Color red = Color(0xFFEF4444);
const Color textPrimary = Color(0xFFF8FAFC);
const Color textSecondary = Color(0xFF94A3B8);
const Color textMuted = Color(0xFF64748B);

Color levelColor(int lvl) => const {
  1: Color(0xFF4ADE80),
  2: Color(0xFF86EFAC),
  3: Color(0xFFFBBF24),
  4: Color(0xFFF97316),
  5: Color(0xFFEF4444),
}[lvl] ?? const Color(0xFF94A3B8);

Color levelBg(int lvl) => const {
  1: Color(0xFF052E16),
  2: Color(0xFF14532D),
  3: Color(0xFF451A03),
  4: Color(0xFF431407),
  5: Color(0xFF450A0A),
}[lvl] ?? const Color(0xFF1E293B);

ThemeData buildTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: indigo,
      secondary: teal,
      surface: surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      foregroundColor: textPrimary,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xF50F172A),
      selectedItemColor: indigoLight,
      unselectedItemColor: Color(0xFF475569),
    ),
  );
}
