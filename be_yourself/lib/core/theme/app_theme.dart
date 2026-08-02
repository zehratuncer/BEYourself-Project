import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quote_reminder/core/theme/app_colors.dart';

final class AppTheme {
  static ThemeData light() {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        surface: AppColors.cardBackground,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineMedium: GoogleFonts.inter(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }
}
