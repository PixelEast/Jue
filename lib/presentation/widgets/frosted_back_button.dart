import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors_helper.dart';

class FrostedBackButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;

  const FrostedBackButton({
    super.key,
    required this.onTap,
    this.icon = Icons.arrow_back,
  });

  @override
  State<FrostedBackButton> createState() => _FrostedBackButtonState();
}

class _FrostedBackButtonState extends State<FrostedBackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColorsHelper.isDark(context);
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.78);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xFFF2F2F2);
    final iconColor = isDark ? Colors.white : const Color(0xFF000000);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            scale: _pressed ? 0.96 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _pressed
                    ? bgColor.withValues(alpha: bgColor.a * 0.85)
                    : bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _pressed ? 0.1 : 0.15,
                    ),
                    blurRadius: _pressed ? 2 : 4,
                    offset: const Offset(0, 1),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
