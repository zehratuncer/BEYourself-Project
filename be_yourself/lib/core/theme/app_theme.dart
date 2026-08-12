import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:be_yourself/core/theme/app_colors.dart';

final class AppTheme {
  static ThemeData light() {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardColor: AppColors.lightCardBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: Brightness.light,
        primary: AppColors.primaryBlue,
        surface: AppColors.lightCardBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryBlue),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        space: 1,
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightCardBackground,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.lightTextSecondary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightCardBackground,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineMedium: GoogleFonts.inter(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
          letterSpacing: -0.5,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.lightTextSecondary,
          height: 1.4,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkCardBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: Brightness.dark,
        primary: AppColors.primaryBlueLight,
        surface: AppColors.darkCardBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryBlueLight),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        space: 1,
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCardBackground,
        selectedItemColor: AppColors.primaryBlueLight,
        unselectedItemColor: AppColors.darkTextSecondary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkCardBackground,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineMedium: GoogleFonts.inter(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
          letterSpacing: -0.5,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextSecondary,
          height: 1.4,
        ),
      ),
    );
  }
}
