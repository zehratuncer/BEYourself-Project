import 'package:flutter/material.dart';

import 'package:quote_reminder/core/constants/app_constants.dart';
import 'package:quote_reminder/core/theme/app_colors.dart';

class LogoCard extends StatelessWidget {
  const LogoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 144,
      height: 144,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withAlpha(25),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.primaryBlue.withAlpha(12),
            blurRadius: 50,
            spreadRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Image.asset(
          AppConstants.logoAssetPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
