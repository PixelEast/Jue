import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import '../constants/dimensions.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // 主色
      primaryColor: AppColors.kleinBlue,
      scaffoldBackgroundColor: AppColors.pureWhite,

      // 文字主题
      textTheme: const TextTheme(
        displayLarge: AppTypography.largeTitle,
        displayMedium: AppTypography.subTitle,
        titleLarge: AppTypography.cardTitle,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.caption,
        bodySmall: AppTypography.small,
      ),

      // 颜色方案
      colorScheme: const ColorScheme.light(
        primary: AppColors.kleinBlue,
        secondary: AppColors.kleinBlue,
        surface: AppColors.pureWhite,
        error: AppColors.warningRed,
      ),

      // 卡片主题
      cardTheme: CardThemeData(
        color: AppColors.pureWhite,
        elevation: AppDimensions.cardElevation,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pureBlack,
          foregroundColor: AppColors.pureWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingXLarge,
            vertical: AppDimensions.spacingLarge,
          ),
          minimumSize: const Size(
            double.infinity,
            AppDimensions.buttonHeightMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        hintStyle: AppTypography.placeholder,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSmall,
          vertical: AppDimensions.spacingMedium,
        ),
      ),

      // 滑块主题
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.kleinBlue,
        inactiveTrackColor: AppColors.mediumGray,
        thumbColor: AppColors.pureBlack,
        overlayColor: AppColors.kleinBlue,
      ),

      // 开关主题
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.pureBlack;
          }
          return AppColors.mediumGray;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.pureBlack;
          }
          return AppColors.mediumGray.withValues(alpha: 0.5);
        }),
      ),

      // 底部导航栏
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.pureWhite,
        selectedItemColor: AppColors.pureBlack,
        unselectedItemColor: AppColors.darkGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // 状态栏
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
    );
  }
}
