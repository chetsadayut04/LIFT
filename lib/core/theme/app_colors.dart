import 'package:flutter/material.dart';

/// Central Design System Color Tokens for LIFT (Cyber Volt & Pitch Black Theme)
class AppColors {
  // Primary Volt Accents
  static const Color primary = Color(0xFFCCFF00); // Cyber Volt Neon
  static const Color primaryVariant = Color(0xFFD4FF3A);
  static const Color onPrimary = Color(0xFF000000);

  // Dark & OLED Backgrounds
  static const Color bg = Color(0xFF0A0A0C); // Pitch Black
  static const Color surface = Color(0xFF14161A); // Sleek Dark Slate Card
  static const Color surfaceElevated = Color(0xFF1B1E24);
  static const Color inputBg = Color(0xFF13151A);

  // Borders & Outlines
  static const Color border = Color(0xFF23272F);
  static const Color borderSubtle = Color(0xFF1C2027);
  static const Color borderHighlight = Color(0x40CCFF00); // 25% volt glow

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF8E95A5);

  // Status & Utility Colors
  static const Color success = Color(0xFFCCFF00);
  static const Color error = Color(0xFFFF5252);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF00E5FF);
}
