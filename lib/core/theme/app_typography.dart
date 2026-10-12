import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography configuration:
/// - Plus Jakarta Sans used throughout for a soft, sleek, bespoke contemporary voice
/// - Tajawal used for modern Arabic UI titles and labels
/// - Amiri strictly preserved for classical Quranic Surahs and Hadith citations
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(TextTheme base) {
    return TextTheme(
      // Hero & large display titles
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.signalBlack,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.signalBlack,
        letterSpacing: -0.3,
        height: 1.25,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.signalBlack,
        height: 1.3,
      ),

      // Section headings
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.signalBlack,
        height: 1.35,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.signalBlack,
        height: 1.35,
      ),

      // Titles & emphasis
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.signalBlack,
        height: 1.3,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.signalBlack,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.signalBlack,
      ),

      // Primary reading body text (14px base)
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.bodyGray,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.bodyGray,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.secondaryText,
        height: 1.4,
      ),

      // Labels & Buttons
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.buttonText,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryText,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryText,
        letterSpacing: 0.5,
      ),
    );
  }

  // Specialized styles for classical quotes & arabic citations
  static TextStyle scholarlyQuote([
    Color color = AppColors.dustyGreen,
    bool isArabic = false,
  ]) {
    if (isArabic) {
      return GoogleFonts.amiri(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.6,
      );
    }
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.5,
    );
  }

  static TextStyle appBarTitle([
    Color color = AppColors.signalBlack,
    bool isArabic = false,
  ]) {
    if (isArabic) {
      return GoogleFonts.tajawal(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.3,
      );
    }
    return GoogleFonts.plusJakartaSans(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle arabicSurahTitle([
    Color color = AppColors.dustyGreen,
    double fontSize = 18,
  ]) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }
}
