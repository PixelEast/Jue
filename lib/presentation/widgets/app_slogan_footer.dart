import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors_helper.dart';

class AppSloganFooter extends StatelessWidget {
  final bool showDivider;
  final Color? lineColor;
  final Color? textColor;
  final Color? logoColor;

  const AppSloganFooter({
    super.key,
    this.showDivider = true,
    this.lineColor,
    this.textColor,
    this.logoColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColorsHelper.isDark(context);
    final effectiveLineColor = lineColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.15)
            : const Color(0xFFFAFAFA));
    final effectiveTextColor = textColor ??
        (isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF5E5E5E));

    return Column(
      children: [
        if (showDivider) ...[
          Center(
            child: Container(
              width: 80,
              height: 1,
              color: effectiveLineColor,
            ),
          ),
          const SizedBox(height: 16),
        ],
        SvgPicture.asset(
          'figma_exports/Logo_compatible.svg',
          width: 16,
          height: 16,
          colorFilter: logoColor == null
              ? null
              : ColorFilter.mode(logoColor!, BlendMode.srcIn),
        ),
        const SizedBox(height: 8),
        Text(
          '"由逻辑 终结纠结."',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: effectiveTextColor,
            letterSpacing: 9,
          ),
        ),
      ],
    );
  }
}
