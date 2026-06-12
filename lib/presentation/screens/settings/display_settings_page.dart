import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors_helper.dart';
import '../../../main.dart';
import '../../widgets/frosted_back_button.dart';

class DisplaySettingsPage extends StatefulWidget {
  const DisplaySettingsPage({super.key});

  @override
  State<DisplaySettingsPage> createState() => _DisplaySettingsPageState();
}

class _DisplaySettingsPageState extends State<DisplaySettingsPage> {
  String _selectedLanguage = '简体中文';

  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColorsHelper.subPageBackground(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 100, 32, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    '界面与显示',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: AppColorsHelper.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '定制你的视觉体验',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColorsHelper.secondaryText(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSettingCard(
                    icon: Icons.dark_mode_outlined,
                    title: '深色模式',
                    subtitle: '深色模式跟随系统',
                    value: themeNotifier.themeMode == ThemeMode.system,
                    onChanged: (value) {
                      themeNotifier.toggleDarkMode(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildLanguageCard(),
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

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColorsHelper.cardBackground(context),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColorsHelper.cardBorder(context)),
          ),
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
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 40,
                  height: 24,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeTrackColor: AppColorsHelper.iconBackground(context),
                    inactiveTrackColor: const Color(0xFFB0B0B0),
                    activeThumbColor: Colors.white,
                    inactiveThumbColor: const Color(0xFFF0F0F0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildLanguageCard() {
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
          onTap: _showLanguageDialog,
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
                  child: Icon(
                    Icons.language_outlined,
                    size: 20,
                    color: AppColorsHelper.iconForeground(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '多语言',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColorsHelper.primaryText(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '切换App语言',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColorsHelper.secondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _selectedLanguage,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D5BFF),
                  ),
                ),
                const SizedBox(width: 8),
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

  void _showLanguageDialog() {
    final isDark = AppColorsHelper.isDark(context);
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (context) => _LanguageDialog(
        selectedLanguage: _selectedLanguage,
        isDark: isDark,
        onLanguageSelected: (lang) {
          setState(() => _selectedLanguage = lang);
        },
      ),
    );
  }
}

class _LanguageDialog extends StatefulWidget {
  final String selectedLanguage;
  final bool isDark;
  final ValueChanged<String> onLanguageSelected;

  const _LanguageDialog({
    required this.selectedLanguage,
    required this.isDark,
    required this.onLanguageSelected,
  });

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog>
    with SingleTickerProviderStateMixin {
  int _englishDodgeAttempts = 0;
  double _englishOffsetY = 0;
  bool _englishVisible = true;
  late AnimationController _dodgeController;
  late Animation<double> _dodgeAnimation;

  @override
  void initState() {
    super.initState();
    _dodgeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _dodgeAnimation = CurvedAnimation(
      parent: _dodgeController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _dodgeController.dispose();
    super.dispose();
  }

  void _onEnglishTap() {
    if (!_englishVisible) return;

    setState(() {
      _englishDodgeAttempts++;
      if (_englishDodgeAttempts >= 3) {
        _englishVisible = false;
      } else {
        _englishOffsetY = _englishDodgeAttempts.isOdd ? 30.0 : -30.0;
        _dodgeController.forward(from: 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 310,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 40,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? const Color(0xFF1E1E1E).withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: widget.isDark
                          ? const Color(0xFF2E2E2E)
                          : const Color(0xFFE5E5E5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '选择语言',
                        style: TextStyle(
                          color: AppColorsHelper.primaryText(context),
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildLanguageOption('简体中文', widget.isDark),
                      if (_englishVisible)
                        AnimatedBuilder(
                          animation: _dodgeAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _englishOffsetY * _dodgeAnimation.value),
                              child: child,
                            );
                          },
                          child: _buildEnglishOption(widget.isDark),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String language, bool isDark) {
    final isSelected = widget.selectedLanguage == language;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? const Color(0xFF2D5BFF) : Colors.black)
                  : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F3F3)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? (isDark ? const Color(0xFF2D5BFF) : Colors.black)
                    : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE7E7E7)),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                widget.onLanguageSelected(language);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12),
              splashColor: isSelected
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              highlightColor: isSelected
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.02),
              child: Center(
                child: Text(
                  language,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColorsHelper.primaryText(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnglishOption(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE7E7E7),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: _onEnglishTap,
              borderRadius: BorderRadius.circular(12),
              splashColor: Colors.black.withValues(alpha: 0.04),
              highlightColor: Colors.black.withValues(alpha: 0.02),
              child: Center(
                child: Text(
                  'English',
                  style: TextStyle(
                    color: AppColorsHelper.primaryText(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
