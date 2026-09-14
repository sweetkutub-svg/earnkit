import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display/Currency - 36px Bold
  static const TextStyle displayCurrency = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.gray900,
  );

  // H1 Screen Title - 24px Bold
  static const TextStyle h1ScreenTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.gray900,
  );

  // H2 Section Header - 20px SemiBold
  static const TextStyle h2SectionHeader = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.gray900,
  );

  // H3 Card Title - 16px SemiBold
  static const TextStyle h3CardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.gray900,
  );

  // Body Text - 14px Regular
  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.gray600,
  );

  // Caption - 12px Regular
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.gray400,
  );

  // Overline/Badge - 10px Medium Uppercase
  static const TextStyle overlineBadge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.gray600,
  );
}