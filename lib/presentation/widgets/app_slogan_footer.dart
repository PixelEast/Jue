import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSloganFooter extends StatelessWidget {
  final bool showDivider;
  final Color lineColor;
  final Color textColor;
  final Color? logoColor;

  const AppSloganFooter({
    super.key,
    this.showDivider = true,
    this.lineColor = const Color(0xFFFAFAFA),
    this.textColor = const Color(0xFF5E5E5E),
    this.logoColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showDivider) ...[
          Container(
            width: double.infinity,
            height: 1,
            color: lineColor,
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
            color: textColor,
          ),
        ),
      ],
    );
  }
}
