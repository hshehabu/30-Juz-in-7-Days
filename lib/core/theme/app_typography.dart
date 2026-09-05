import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography configuration following the 3ilm design system:
/// - Cormorant Garamond for editorial serif headlines
/// - Inter for crisp, modern body & control labels
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(TextTheme base) {
    return TextTheme(
      // Hero & large display titles
      displayLarge: GoogleFonts.cormorantGaramond(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: AppColors.brassGold,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      displayMedium: GoogleFonts.cormorantGaramond(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.brassGold,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.cormorantGaramond(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.deepBrown,
        height: 1.25,
      ),

      // Section headings & tool card headers
      headlineMedium: GoogleFonts.cormorantGaramond(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.deepBrown,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.cormorantGaramond(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: AppColors.deepBrown,
        height: 1.35,
      ),

      // Titles & emphasis
      titleLarge: GoogleFonts.cormorantGaramond(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.brassGold,
        height: 1.3,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.deepBrown,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.deepBrown,
        letterSpacing: 0.1,
      ),

      // Primary reading body text
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.deepBrown,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.deepBrown,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.4,
      ),

      // Eyebrows, labels & buttons
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textLight,
        letterSpacing: 0.2,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0.4,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.brassGold,
        letterSpacing: 0.8,
      ),
    );
  }

  // Specialized styles for classical quotes & arabic citations
  static TextStyle scholarlyQuote([Color color = AppColors.deepBrown]) {
    return GoogleFonts.cormorantGaramond(
      fontSize: 18,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.45,
    );
  }

  static TextStyle appBarTitle([Color color = AppColors.deepBrown]) {
    return GoogleFonts.cormorantGaramond(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 0.2,
    );
  }
}
