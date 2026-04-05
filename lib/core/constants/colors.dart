import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // 主色调
  static const Color kleinBlue = Color(0xFF002FA7);
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // 中性色
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color lightGrayBg = Color(0xFFF9F9F9);
  static const Color mediumGray = Color(0xFFE5E5EA);
  static const Color darkGray = Color(0xFF8E8E93);
  static const Color lightTextGray = Color(0xFFC7C7CC);

  // 功能色
  static const Color successBlue = Color(0xFF6FA8FF);
  static const Color warningRed = Color(0xFFFF6B6B);
  static const Color disabledBlack = Color(0xFF3A3A3A);

  // 渐变色
  static const List<Color> barChartGradient = [
    Color(0xFFB8D4FF),
    Color(0xFF6FA8FF),
    Color(0xFF002FA7),
  ];
}
