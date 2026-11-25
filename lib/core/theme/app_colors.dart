import 'package:flutter/material.dart';

/// Central Design System Color Tokens for LIFT (Pro Athletic Precision & Matte Obsidian)
/// Replaces generic AI cyberpunk glow with gym-tested, high-contrast athletic ergonomics.
class AppColors {
  // Primary Athletic Volt (Crisp, High-Contrast Performance Lime)
  static const Color primary = Color(0xFFCCFF00); // Pure Athletic Volt
  static const Color primaryVariant = Color(0xFFB8E600);
  static const Color onPrimary = Color(0xFF000000);

  // Secondary Athletic Steel Blue (Focused utility, avoids overdone neon cyan)
  static const Color secondary = Color(0xFF38BDF8); // Clean Performance Blue
  static const Color secondaryVariant = Color(0xFF0284C7);
  static const Color onSecondary = Color(0xFF000000);

  // Tertiary Apex Coral / PR Highlights (Sharp Athletic Contrast)
  static const Color tertiary = Color(0xFFFF4757); // Apex Coral Red
  static const Color onTertiary = Color(0xFFFFFFFF);

  // True OLED Black Canvas & Graphite Telemetry Surfaces (WHOOP / Garmin Pro aesthetic)
  static const Color bg = Color(0xFF000000); // True OLED Black
  static const Color surface = Color(0xFF111318); // Graphite Telemetry Surface
  static const Color surfaceElevated = Color(0xFF181B22); // Elevated Tactile Surface
  static const Color inputBg = Color(0xFF090B0F); // Precision Input Dark

  // Clean 1px Industrial Borders (Minimalist, zero AI neon blur)
  static const Color border = Color(0xFF1F242D); // 1px Crisp Telemetry Edge
  static const Color borderSubtle = Color(0xFF151820);
  static const Color borderHighlight = Color(0x35CCFF00); // 21% Volt subtle rim
  static const Color borderCyan = Color(0x2538BDF8); // 15% Slate blue rim

  // High-Legibility Typography (Readable from 2 meters away)
  static const Color textPrimary = Color(0xFFF8FAFC); // Pure Crisp Slate White
  static const Color textSecondary = Color(0xFFCBD5E1); // Bright Silver Slate
  static const Color textMuted = Color(0xFF717D96); // Refined Technical Slate

  // Status & Utility Colors
  static const Color success = Color(0xFFCCFF00); // Athletic Volt Check
  static const Color error = Color(0xFFFF3B30); // Precision Red
  static const Color onError = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFF59E0B); // Industrial Amber
  static const Color info = Color(0xFF38BDF8); // Technical Slate Blue

  // Clean Athletic Gradients (Toned down from AI neon rainbow to focused tone-on-tone)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFCCFF00), Color(0xFFB5E600)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF13161D), Color(0xFF0B0D11)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGlow = LinearGradient(
    colors: [Color(0x10CCFF00), Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
