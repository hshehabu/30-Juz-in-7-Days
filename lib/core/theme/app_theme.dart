import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.ink,
        onPrimary: AppColors.buttonText,
        secondary: AppColors.secondaryNeutral,
        onSecondary: AppColors.secondaryText,
        surface: AppColors.paper,
        onSurface: AppColors.bodyGray,
        outline: AppColors.mistGray,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      textTheme: AppTypography.textTheme(base.textTheme),

      // Flat cards with mist gray border and 4.8px radius
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.standardRadius),
          side: const BorderSide(
            color: AppColors.mistGray,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // App Bar styling: Paper white, black title, zero elevation
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.signalBlack,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.appBarTitle(AppColors.signalBlack),
        iconTheme: const IconThemeData(color: AppColors.signalBlack),
      ),

      // Primary CTA button: Dusty Green, 4.8px radius, zero elevation
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: AppColors.dustyGreen,
          foregroundColor: AppColors.buttonText,
          disabledBackgroundColor: AppColors.controlSurface,
          disabledForegroundColor: AppColors.secondaryText,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.standardRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Secondary CTA button: Light sage neutral (#E4ECE7), dark text, muted border
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.controlSurface,
          foregroundColor: AppColors.secondaryText,
          side: const BorderSide(color: AppColors.secondaryBorder, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.standardRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text button styling: Dusty green
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.dustyGreen,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Dialogs: Flat paper white with 4.8px radius
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.standardRadius),
          side: const BorderSide(color: AppColors.mistGray, width: 1),
        ),
      ),

      // Bottom Sheets: Clean flat surface with subtle radius
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          side: BorderSide(color: AppColors.mistGray, width: 1),
        ),
      ),

      // Dividers: Subtle secondary neutral
      dividerTheme: const DividerThemeData(
        color: AppColors.secondaryNeutral,
        thickness: 1,
        space: 20,
      ),

      // Bottom Navigation Bar: Flat white, dusty green active items
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.paper,
        selectedItemColor: AppColors.dustyGreen,
        unselectedItemColor: AppColors.secondaryText,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Input Decoration: Soft sage fill (#F3F7F5), muted border (#CDD9D3), 4.8px radius
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.controlSurface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.standardRadius),
          borderSide: const BorderSide(color: AppColors.mistGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.standardRadius),
          borderSide: const BorderSide(color: AppColors.mistGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.standardRadius),
          borderSide: const BorderSide(color: AppColors.dustyGreen, width: 1.5),
        ),
      ),
    );
  }
}
