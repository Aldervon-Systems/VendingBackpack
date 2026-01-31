import 'package:flutter/material.dart';

class AppColors {
  static const Color foundation = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color dataPrimary = Color(0xFF0F172A);
  static const Color dataSecondary = Color(0xFF64748B);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF43F5E);
  static const Color actionAccent = Color(0xFF3B82F6);
}

class AppStyle {
  static TextStyle metric({
    double fontSize = 24,
    Color color = AppColors.dataPrimary,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }

  static TextStyle label({
    double fontSize = 12,
    Color color = AppColors.dataSecondary,
    FontWeight fontWeight = FontWeight.w500,
    double letterSpacing = 0.5,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  static BoxDecoration surfaceCard = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: AppColors.dataPrimary.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration interactiveCard({bool active = false}) {
    return BoxDecoration(
      color: active ? AppColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      border: active ? Border.all(color: AppColors.border, width: 1) : null,
    );
  }
}
