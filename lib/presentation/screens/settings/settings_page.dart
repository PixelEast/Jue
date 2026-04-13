import 'package:flutter/material.dart';
import '../../widgets/app_slogan_footer.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 100, 32, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '设置',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '定制你的决定体验',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF5E5E5E),
                ),
              ),
              const SizedBox(height: 24),

              // Each setting as independent card
              _buildSettingCard(
                icon: Icons.notifications_none_rounded,
                title: '通知',
                subtitle: '建议决定提醒，通知',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                icon: Icons.palette_outlined,
                title: '界面与显示',
                subtitle: '深色模式，字体大小',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                icon: Icons.key_outlined,
                title: '系统权限',
                subtitle: '位置，后台刷新',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                icon: Icons.storage_outlined,
                title: '数据与存储',
                subtitle: '查看存储，清理缓存，历史记录',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                icon: Icons.language_outlined,
                title: '语言设置',
                subtitle: '简体中文',
                onTap: () {},
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '其他信息',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5E5E5E),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // About card (black background)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF191919),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF474747),
                          width: 1,
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
                            'V0.2 Beta',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF8E8E93)),
                  ],
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
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
            const Icon(Icons.chevron_right, color: Color(0xFFC6C6C6), size: 20),
          ],
        ),
      ),
    );
  }
}
