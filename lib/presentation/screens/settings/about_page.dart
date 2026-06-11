import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors_helper.dart';
import '../../widgets/frosted_back_button.dart';
import 'version_history_page.dart';
import 'feedback_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColorsHelper.isDark(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColorsHelper.scaffoldBackground(context),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 68),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Developed by',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColorsHelper.tertiaryText(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PixelEast · VormStudio',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColorsHelper.secondaryText(context),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 100, 32, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SvgPicture.asset(
                        'figma_exports/Logo_compatible.svg',
                        width: 48,
                        height: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '决',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColorsHelper.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppConstants.appVersion,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColorsHelper.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildAboutCard(
                    context,
                    icon: Icons.history_outlined,
                    title: '版本记录',
                    subtitle: '查看历次版本更新内容',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VersionHistoryPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAboutCard(
                    context,
                    icon: Icons.feedback_outlined,
                    title: '反馈与建议',
                    subtitle: '帮助我们变得更好',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FeedbackPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAboutCard(
                    context,
                    icon: Icons.system_update_outlined,
                    title: '版本更新',
                    subtitle: '当前已是最新版本',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: FrostedBackButton(
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColorsHelper.cardBackground(context),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColorsHelper.cardBorder(context)),
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
                    color: AppColorsHelper.iconBackground(context),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Icon(icon, size: 20, color: AppColorsHelper.iconForeground(context)),
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
                          color: AppColorsHelper.primaryText(context),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColorsHelper.secondaryText(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColorsHelper.tertiaryText(context),
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
