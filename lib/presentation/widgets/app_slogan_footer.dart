import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSloganFooter extends StatelessWidget {
  const AppSloganFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 1,
          color: const Color(0xFFFAFAFA),
        ),
        const SizedBox(height: 16),
        SvgPicture.asset(
          'figma_exports/Logo_compatible.svg',
          width: 16,
          height: 16,
        ),
        const SizedBox(height: 8),
        const Text(
          '"由逻辑 终结纠结."',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Color(0xFF5E5E5E),
          ),
        ),
      ],
    );
  }
}
