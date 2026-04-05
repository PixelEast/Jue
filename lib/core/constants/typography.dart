import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();

  // 大标题 (32-36pt)
  static const TextStyle largeTitle = TextStyle(
    fontFamily: 'Noto Sans SC',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  // 副标题 (24-28pt)
  static const TextStyle subTitle = TextStyle(
    fontFamily: 'Noto Sans SC',
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: Color(0xFF002FA7),
  );

  // 卡片标题 (18-20pt)
  static const TextStyle cardTitle = TextStyle(
    fontFamily: 'Noto Sans SC',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  // 正文 (15-16pt)
  static const TextStyle body = TextStyle(
    fontFamily: 'Noto Sans SC',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.black,
  );

  // 副文 (13-14pt 灰色)
  static const TextStyle caption = TextStyle(
    fontFamily: 'Noto Sans SC',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Color(0xFF8E8E93),
  );

  // 小字 (11-12pt 灰色)
  static const TextStyle small = TextStyle(
    fontFamily: 'Noto Sans SC',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Color(0xFF8E8E93),
  );

  // 占位符文本
  static const TextStyle placeholder = TextStyle(
    fontFamily: 'Noto Sans SC',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Color(0xFFC7C7CC),
  );

  // 按钮文字
  static const TextStyle button = TextStyle(
    fontFamily: 'Noto Sans SC',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
