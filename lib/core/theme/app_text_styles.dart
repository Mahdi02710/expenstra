import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Light theme text styles
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: -0.5,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: -0.3,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: -0.2,
  );
  
  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle h6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  static const TextStyle subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle subtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.4,
    letterSpacing: 1.2,
  );
  
  // Button text styles
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  
  // Dark theme text styles
  static const TextStyle h1Dark = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.darkTextPrimary,
    height: 1.5,
    letterSpacing: -0.5,
  );
  
  static const TextStyle h2Dark = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    height: 1.5,
    letterSpacing: -0.3,
  );
  
  static const TextStyle h3Dark = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    height: 1.5,
    letterSpacing: -0.2,
  );
  
  static const TextStyle h4Dark = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    height: 1.5,
  );
  
  static const TextStyle body1Dark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.darkTextPrimary,
    height: 1.5,
  );
  
  static const TextStyle body2Dark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.darkTextSecondary,
    height: 1.5,
  );
  
  static const TextStyle captionDark = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.darkTextMuted,
    height: 1.4,
  );
  
  // Special text styles
  static const TextStyle currencyLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  static const TextStyle currencyMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    height: 1.2,
    letterSpacing: -0.3,
  );
  
  static const TextStyle currencySmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle incomeAmount = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.income,
    height: 1.2,
  );
  
  static const TextStyle expenseAmount = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.expense,
    height: 1.2,
  );
  
  static const TextStyle tabLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
  
  // Helper methods for dynamic styling
  static TextStyle getAmountStyle(bool isIncome, {double? fontSize}) {
    return TextStyle(
      fontSize: fontSize ?? 18,
      fontWeight: FontWeight.w600,
      color: isIncome ? AppColors.income : AppColors.expense,
      height: 1.2,
    );
  }
  
  static TextStyle getPrimaryTextStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      height: 1.5,
    );
  }
  
  static TextStyle getSecondaryTextStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      height: 1.5,
    );
  }
}