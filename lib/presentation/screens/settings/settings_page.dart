import 'package:flutter/material.dart';
import '../../../core/theme/app_colors_helper.dart';
import '../../widgets/app_slogan_footer.dart';
import 'notification_settings_page.dart';
import 'display_settings_page.dart';
import 'about_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final bgColor = AppColorsHelper.scaffoldBackground(context);
    final primaryTextColor = AppColorsHelper.primaryText(context);
    final cardBg = AppColorsHelper.cardBackground(context);
    final cardBorder = AppColorsHelper.cardBorder(context);
    final iconBg = AppColorsHelper.iconBackground(context);
    final iconFg = AppColorsHelper.iconForeground(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 100, 32, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '设置',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '定制你的决定体验',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColorsHelper.secondaryText(context),
                ),
              ),
              const SizedBox(height: 24),

              // Each setting as independent card
              _buildSettingCard(
                icon: Icons.notifications_none_rounded,
                title: '通知',
                subtitle: '智能决定提醒，免打扰时段',
                cardBg: cardBg,
                cardBorder: cardBorder,
                iconBg: iconBg,
                iconFg: iconFg,
                primaryTextColor: primaryTextColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                icon: Icons.palette_outlined,
                title: '界面与显示',
                subtitle: '深色模式，多语言',
                cardBg: cardBg,
                cardBorder: cardBorder,
                iconBg: iconBg,
                iconFg: iconFg,
                primaryTextColor: primaryTextColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DisplaySettingsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                icon: Icons.key_outlined,
                title: '系统权限',
                subtitle: '位置，后台刷新',
                cardBg: cardBg,
                cardBorder: cardBorder,
                iconBg: iconBg,
                iconFg: iconFg,
                primaryTextColor: primaryTextColor,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                icon: Icons.storage_outlined,
                title: '数据与存储',
                subtitle: '查看存储，清理缓存，历史记录',
                cardBg: cardBg,
                cardBorder: cardBorder,
                iconBg: iconBg,
                iconFg: iconFg,
                primaryTextColor: primaryTextColor,
                onTap: () {},
              ),
              const SizedBox(height: 24),
              Text(
                '其他信息',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColorsHelper.secondaryText(context),
                ),
              ),
              const SizedBox(height: 12),

              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(32),
                child: Ink(
                  decoration: BoxDecoration(
                    color: AppColorsHelper.isDark(context)
                        ? const Color(0xFF1E1E1E)
                        : Colors.black,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColorsHelper.isDark(context)
                          ? const Color(0xFF2E2E2E)
                          : const Color(0xFF333333),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(32),
                    splashColor: Colors.white.withValues(alpha: 0.08),
                    highlightColor: Colors.white.withValues(alpha: 0.04),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '关于决 App',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '版本信息，反馈，开发者信息',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF8E8E93),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const AppSloganFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color cardBg,
    required Color cardBorder,
    required Color iconBg,
    required Color iconFg,
    required Color primaryTextColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      child: Ink(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: cardBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          splashColor: Colors.black.withValues(alpha: 0.05),
          highlightColor: Colors.black.withValues(alpha: 0.02),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Icon(icon, size: 20, color: iconFg),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5E5E5E),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFC6C6C6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
