import 'package:flutter/material.dart';

class AppColors {
  // ExpensTra Brand Colors
  static const Color navy = Color(0xFF00033A);
  static const Color blueDark = Color(0xFF162647);
  static const Color blueMedium = Color(0xFF163473);
  static const Color gold = Color(0xFFD2AB17);
  
  // Light Theme Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = navy;
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color inputBackground = Color(0xFFF8F9FB);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  
  // Dark Theme Colors
  static const Color darkBackground = navy;
  static const Color darkSurface = blueDark;
  static const Color darkCardBackground = blueDark;
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkInputBackground = blueMedium;
  
  // Semantic Colors
  static const Color income = success;
  static const Color expense = error;
  static const Color primary = blueMedium;
  static const Color secondary = blueDark;
  static const Color accent = gold;
  
  // Chart Colors
  static const List<Color> chartColors = [
    blueMedium,
    gold,
    blueDark,
    Color(0xFF60A5FA),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
  ];
  
  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [blueMedium, blueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient goldGradient = LinearGradient(
    colors: [gold, Color(0xFFEDC047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Opacity variations
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  static Color goldWithOpacity(double opacity) => gold.withOpacity(opacity);
  static Color navyWithOpacity(double opacity) => navy.withOpacity(opacity);
  
  // Helper methods
  static Color getChartColor(int index) {
    return chartColors[index % chartColors.length];
  }
  
  static Color getTransactionColor(bool isIncome) {
    return isIncome ? income : expense;
  }
}