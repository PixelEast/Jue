import 'package:flutter/material.dart';
import '../../main.dart';

class AppColorsHelper {
  const AppColorsHelper._();

  // 品牌色
  static const Color brandColor = Color(0xFF2D5BFF);

  static Color scaffoldBackground(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color subPageBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF262626)
        : const Color(0xFFF9F9F9);
  }

  static Color cardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF3F3F3);
  }

  static Color cardBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFE7E7E7);
  }

  static Color primaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF0F172A);
  }

  static Color secondaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF5E5E5E);
  }

  static Color tertiaryText(BuildContext context) {
    return const Color(0xFF8E8E93);
  }

  static Color iconBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? brandColor.withValues(alpha: 0.35)
        : Colors.black;
  }

  static Color iconForeground(BuildContext context) {
    return Colors.white;
  }

  static Color dividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFE7E7E7);
  }

  static Color navBarBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.80);
  }

  static Color navBarBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
  }

  static Color decisionCardText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF004EE8);
  }

  static Color brandColorSoft(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF2D5BFF);
  }

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color executeButtonCenter(BuildContext context) {
    return isDark(context) ? const Color(0xFF3B5FCC) : const Color(0xFF5075FF);
  }

  static Color executeButtonEdge(BuildContext context) {
    return isDark(context) ? const Color(0xFF1B4D8F) : const Color(0xFF2D5BFF);
  }

  static Color executeButtonBorder(BuildContext context) {
    return isDark(context) ? const Color(0xFF4A6FCC) : const Color(0xFF577CFF);
  }

  static Color executeExpandCenter(BuildContext context) {
    return isDark(context) ? const Color(0xFF3B5FCC) : const Color(0xFF5075FF);
  }

  static Color executeExpandEdge(BuildContext context) {
    return isDark(context) ? const Color(0xFF1B4D8F) : const Color(0xFF2D5BFF);
  }

  static Color executeResultBg(BuildContext context) {
    return isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF9F9F9);
  }

  static Widget buildThemeAwareDialog({
    required Widget Function(BuildContext context, bool isDark) builder,
  }) {
    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return builder(context, isDark);
      },
    );
  }
}
