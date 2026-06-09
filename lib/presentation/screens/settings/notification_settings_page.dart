import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors_helper.dart';
import '../../../data/local/app_storage.dart';
import '../../../data/models/app_models.dart';
import '../../../core/utils/notification_service.dart';
import '../../widgets/frosted_back_button.dart';
import '../../widgets/time_wheel_picker.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationService _notificationService = NotificationService();

  NotificationSettings _settings = NotificationSettings();
  bool _hasPermission = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final settings = await AppStorage.getNotificationSettings();
    final hasPermission = await _notificationService.checkPermission();
    if (mounted) {
      setState(() {
        _settings = settings;
        _hasPermission = hasPermission;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    await AppStorage.saveNotificationSettings(_settings);
  }

  Future<void> _requestPermission() async {
    final granted = await _notificationService.requestPermission();
    if (mounted) {
      setState(() => _hasPermission = granted);
      if (!granted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (context) => Material(
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
                      vertical: 55,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE5E5E5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '需要通知权限',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Color(0xFF000000),
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          '请在系统设置中开启通知权限，以便接收决定提醒。',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Color(0xFF5E5E5E),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: Ink(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  _notificationService.openSystemSettings();
                                },
                                borderRadius: BorderRadius.circular(12),
                                splashColor: Colors.white.withValues(
                                  alpha: 0.08,
                                ),
                                highlightColor: Colors.white.withValues(
                                  alpha: 0.04,
                                ),
                                child: const Center(
                                  child: Text(
                                    '去设置',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: Ink(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F3F3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFEAEAEA),
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(12),
                                splashColor: Colors.black.withValues(
                                  alpha: 0.04,
                                ),
                                highlightColor: Colors.black.withValues(
                                  alpha: 0.02,
                                ),
                                child: const Center(
                                  child: Text(
                                    '取消',
                                    style: TextStyle(
                                      color: Color(0xFF000000),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColorsHelper.scaffoldBackground(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColorsHelper.scaffoldBackground(context),
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
                    '通知',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: AppColorsHelper.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '不错过每一个决定',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColorsHelper.secondaryText(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_hasPermission) ...[
                    _buildPermissionCard(),
                    const SizedBox(height: 12),
                  ],
                  _buildSettingCard(
                    icon: Icons.notifications_active_outlined,
                    title: '通知总开关',
                    subtitle: '一键关闭所有通知',
                    value: _settings.enabled,
                    onChanged: (value) {
                      setState(() => _settings.enabled = value);
                      _saveSettings();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    icon: Icons.alarm_outlined,
                    title: '决定提醒',
                    subtitle: '根据你的使用习惯，在合适的时机提醒你执行决定',
                    value: _settings.reminderEnabled,
                    onChanged: _settings.enabled
                        ? (value) {
                            setState(() => _settings.reminderEnabled = value);
                            _saveSettings();
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildDndCard(),
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

  Widget _buildPermissionCard() {
    final isDark = AppColorsHelper.isDark(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: isDark
              ? AppColorsHelper.brandColor.withValues(alpha: 0.12)
              : AppColorsHelper.brandColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColorsHelper.brandColor.withValues(alpha: 0.2),
          ),
        ),
        child: InkWell(
          onTap: _requestPermission,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D5BFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.notifications_off_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '通知权限未开启',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D5BFF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '点击跳转系统设置开启通知权限',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF2D5BFF).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: const Color(0xFF2D5BFF).withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final enabled = onChanged != null;
    final isDark = AppColorsHelper.isDark(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      child: Ink(
        decoration: BoxDecoration(
          color: isDark
              ? AppColorsHelper.cardBackground(context)
              : (enabled
                  ? const Color(0xFFF3F3F3)
                  : const Color(0xFFF3F3F3).withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark
                ? AppColorsHelper.cardBorder(context)
                : const Color(0xFFE7E7E7),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColorsHelper.iconBackground(context)
                      : const Color(0xFFC6C6C6),
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
                        color: enabled
                            ? AppColorsHelper.primaryText(context)
                            : const Color(0xFF8E8E93),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: enabled
                              ? AppColorsHelper.secondaryText(context)
                              : const Color(0xFFC6C6C6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 40,
                  height: 24,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeTrackColor: AppColorsHelper.iconBackground(context),
                    inactiveTrackColor: const Color(0xFFC6C6C6),
                    activeThumbColor: Colors.white,
                    inactiveThumbColor: Colors.white,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDndCard() {
    final enabled = _settings.enabled;
    final isDark = AppColorsHelper.isDark(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      child: Ink(
        decoration: BoxDecoration(
          color: isDark
              ? AppColorsHelper.cardBackground(context)
              : (enabled
                  ? const Color(0xFFF3F3F3)
                  : const Color(0xFFF3F3F3).withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark
                ? AppColorsHelper.cardBorder(context)
                : const Color(0xFFE7E7E7),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: enabled
                          ? AppColorsHelper.iconBackground(context)
                          : const Color(0xFFC6C6C6),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(16)),
                    ),
                    child: Icon(
                      Icons.do_not_disturb_on_outlined,
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
                          '免打扰时段',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: enabled
                                ? AppColorsHelper.primaryText(context)
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '该时段内不会发送任何通知',
                          style: TextStyle(
                            fontSize: 12,
                            color: enabled
                                ? AppColorsHelper.secondaryText(context)
                                : const Color(0xFFC6C6C6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 40,
                      height: 24,
                      child: Switch(
                        value: _settings.dndEnabled,
                        onChanged: enabled
                            ? (value) {
                                setState(() => _settings.dndEnabled = value);
                                _saveSettings();
                              }
                            : null,
                        activeTrackColor: AppColorsHelper.iconBackground(context),
                        inactiveTrackColor: const Color(0xFFC6C6C6),
                        activeThumbColor: Colors.white,
                        inactiveThumbColor: Colors.white,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
              if (_settings.dndEnabled && enabled) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeSelector(
                        label: '开始',
                        hour: _settings.dndStartHour,
                        minute: _settings.dndStartMinute,
                        onPicked: (h, m) {
                          setState(() {
                            _settings.dndStartHour = h;
                            _settings.dndStartMinute = m;
                          });
                          _saveSettings();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        width: 16,
                        height: 1,
                        color: AppColorsHelper.dividerColor(context),
                      ),
                    ),
                    Expanded(
                      child: _buildTimeSelector(
                        label: '结束',
                        hour: _settings.dndEndHour,
                        minute: _settings.dndEndMinute,
                        onPicked: (h, m) {
                          setState(() {
                            _settings.dndEndHour = h;
                            _settings.dndEndMinute = m;
                          });
                          _saveSettings();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required int hour,
    required int minute,
    required void Function(int hour, int minute) onPicked,
  }) {
    return GestureDetector(
      onTap: () => _pickTime(hour, minute, onPicked),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColorsHelper.isDark(context) ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColorsHelper.isDark(context) ? const Color(0xFF3A3A3A) : const Color(0xFFE7E7E7),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColorsHelper.secondaryText(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColorsHelper.primaryText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(
    int hour,
    int minute,
    void Function(int hour, int minute) onPicked,
  ) async {
    final picked = await TimeWheelPickerDialog.show(
      context: context,
      initialHour: hour,
      initialMinute: minute,
      title: '选择时间',
    );
    if (picked != null) {
      onPicked(picked.hour, picked.minute);
    }
  }
}
