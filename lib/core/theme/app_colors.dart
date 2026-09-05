import 'package:flutter/material.dart';

/// Design tokens based on the 3ilm design system.
class AppColors {
  AppColors._();

  // Primary brand & action
  static const Color brassGold = Color(0xFFA8842B);
  static const Color brassGoldLight = Color(0xFFC7A24B);
  static const Color brassGoldDark = Color(0xFF86661D);

  // Surface & backgrounds
  static const Color parchment = Color(0xFFFBF6E9);
  static const Color parchmentLight = Color(0xFFFFFDF8);
  static const Color cardSurface = Color(0xFFF7F0DF);

  // Borders & Dividers
  static const Color softSand = Color(0xFFCEC5B7);
  static const Color softSandLight = Color(0xFFE2DDD5);

  // Text colors
  static const Color deepBrown = Color(0xFF2C1810);
  static const Color textMuted = Color(0xFF7A6D63);
  static const Color textLight = Color(0xFFFBF6E9);

  // Status & indicators (respectful, calm, non-judgmental)
  static const Color statusCompleted = Color(0xFFA8842B);
  static const Color statusToday = Color(0xFFA8842B);
  static const Color statusMissed = Color(0xFF9E5346); // Warm subdued terracotta
  static const Color statusUpcoming = Color(0xFFB5ABA0);
}
