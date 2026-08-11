import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary brand color
  static const Color primaryBlue = Color(0xFF025BB5);
  static const Color primaryBlueLight = Color(0xFF60A5FA);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF9F9FF);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF111C2D);
  static const Color lightTextSecondary = Color(0xFF516072);
  static const Color lightInputFill = Color(0xFFF0F3FF);
  static const Color lightDivider = Color(0xFFE2E8F0);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCardBackground = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkInputFill = Color(0xFF1E293B);
  static const Color darkDivider = Color(0xFF334155);

  // Legacy & Shared Text colors
  static const Color textPrimary = Color(0xFF0056BD);
  static const Color textSecondary = Color(0xFF64748B);

  // Background and surface colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Aura glow and shadows
  static const Color auraGlowInner = Color(0x223B82F6);
  static const Color auraGlowOuter = Color(0x00FFFFFF);
  static const Color cardShadow = Color(0x1F025BB5);
  static const Color bottomIndicator = Color(0xFFD3E2FB);
}
