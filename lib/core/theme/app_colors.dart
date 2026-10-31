import 'package:flutter/material.dart';

/// Central Design System Color Tokens for LIFT (Electric Volt & Cyan Glow Theme)
class AppColors {
  // Primary Volt Accents (Luminous Electric Volt)
  static const Color primary = Color(0xFFD4FF00); // Electric Volt Neon - crisp & luminous
  static const Color primaryVariant = Color(0xFFE4FF3A);
  static const Color onPrimary = Color(0xFF070A0F);

  // Secondary & Cyan Glow Accents (Sporty Electric Cyan)
  static const Color secondary = Color(0xFF00E5FF); // Electric Cyan Glow
  static const Color secondaryVariant = Color(0xFF00B0FF);
  static const Color onSecondary = Color(0xFF070A0F);

  // Tertiary Electric Violet (PRs, High Impact)
  static const Color tertiary = Color(0xFF8B5CF6);
  static const Color onTertiary = Color(0xFFFFFFFF);

  // Deep Navy & Midnight Backgrounds (Rich Depth & Modern Contrast)
  static const Color bg = Color(0xFF0B0F17); // Rich Midnight Navy Charcoal
  static const Color surface = Color(0xFF131926); // High-contrast Sleek Midnight Slate
  static const Color surfaceElevated = Color(0xFF1B2335); // Elevated Card Surface
  static const Color inputBg = Color(0xFF0E131E); // Deep Input Background

  // Borders & Glow Outlines
  static const Color border = Color(0xFF222D42); // Clean Modern Border
  static const Color borderSubtle = Color(0xFF192030);
  static const Color borderHighlight = Color(0x60D4FF00); // 38% Volt glow
  static const Color borderCyan = Color(0x5000E5FF); // 31% Cyan glow

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC); // Pure Crisp Slate White
  static const Color textSecondary = Color(0xFFCBD5E1); // Bright Silver Slate
  static const Color textMuted = Color(0xFF8E9BB5); // Legible Muted Slate

  // Status & Utility Colors
  static const Color success = Color(0xFFD4FF00); // Electric Volt Success
  static const Color error = Color(0xFFFF4757); // Vibrant Coral Red
  static const Color onError = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFFFB300); // Solar Amber
  static const Color info = Color(0xFF00E5FF); // Electric Cyan

  // Gradients for Dynamic Visual Flair
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD4FF00), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF161E30), Color(0xFF101624)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGlow = LinearGradient(
    colors: [Color(0x25D4FF00), Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
