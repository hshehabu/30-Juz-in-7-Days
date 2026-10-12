import 'package:flutter/material.dart';

/// Design tokens based on the Robi's works design system:
/// - Minimalist monochrome palette with near-black and neutral grays
/// - High-contrast, clean, flat surfaces
class AppColors {
  AppColors._();

  // Core semantic palette: Dusty Green & Soft Organic Neutrals
  static const Color dustyGreen = Color(0xFF416757);
  static const Color dustyGreenDark = Color(0xFF2E4B3E);
  static const Color dustyGreenLight = Color(0xFF5B8171);
  static const Color primary = dustyGreen;
  static const Color signalBlack = Color(0xFF1E2B25); // Deepest forest charcoal
  static const Color forestCharcoal = Color(0xFF1E2B25); // Sleek toast & dark surface
  static const Color terracotta = Color(0xFFB85D43);    // Warm muted warning & destructive action
  static const Color ink = dustyGreen;                 // Primary action & CTA tone
  static const Color paper = Color(0xFFFFFFFF);        // Clean crisp canvas
  static const Color bodyGray = Color(0xFF283630);     // Primary reading body text
  static const Color mistGray = Color(0xFFCDD9D3);     // Soft sage border
  static const Color controlSurface = Color(0xFFF3F7F5); // Whisper-soft dusty green surface
  static const Color secondaryNeutral = Color(0xFFE4ECE7); // Light sage-neutral
  static const Color secondaryBorder = Color(0xFFBCCDC5);
  static const Color secondaryText = Color(0xFF566A61); // Muted sage slate
  static const Color buttonText = Color(0xFFFFFFFF);    // Crisp white text on dusty green

  // Mapped design tokens for backward compatibility
  static const Color brassGold = dustyGreen;
  static const Color brassGoldLight = dustyGreenLight;
  static const Color brassGoldDark = dustyGreenDark;

  // Surface & backgrounds
  static const Color parchment = paper;
  static const Color parchmentLight = paper;
  static const Color cardSurface = controlSurface;

  // Borders & Dividers
  static const Color softSand = mistGray;
  static const Color softSandLight = secondaryNeutral;

  // Text colors
  static const Color deepBrown = signalBlack;
  static const Color textMuted = secondaryText;
  static const Color textLight = buttonText;

  // Status & indicators (respectful, calm, organic)
  static const Color statusCompleted = dustyGreen;
  static const Color statusToday = dustyGreenDark;
  static const Color statusMissed = Color(0xFF8A9C94);
  static const Color statusUpcoming = mistGray;

  // Geometry
  static const double standardRadius = 4.8;
  static const double microRadius = 0.0;
}
