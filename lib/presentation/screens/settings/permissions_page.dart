import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors_helper.dart';
import '../../widgets/frosted_back_button.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  bool _notificationGranted = false;
  bool _locationGranted = false;
  bool _locationServiceEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notificationStatus = await Permission.notification.status;
    final locationPermission = await Geolocator.checkPermission();
    final locationService = await Geolocator.isLocationServiceEnabled();

    if (mounted) {
      setState(() {
        _notificationGranted = notificationStatus.isGranted;
        _locationGranted = locationPermission == LocationPermission.whileInUse ||
            locationPermission == LocationPermission.always;
        _locationServiceEnabled = locationService;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestNotification() async {
    final status = await Permission.notification.request();
    if (mounted) {
      setState(() => _notificationGranted = status.isGranted);
      if (!status.isGranted) {
        _showGoToSettingsDialog('通知权限', '请在系统设置中开启通知权限，以便接收决定提醒。');
      }
    }
  }

  Future<void> _requestLocation() async {
    if (!_locationServiceEnabled) {
      final serviceEnabled = await Geolocator.openLocationSettings();
      if (!serviceEnabled) {
        if (mounted) {
          _showGoToSettingsDialog('定位服务', '请在系统设置中开启定位服务，以便使用位置条件功能。');
        }
        return;
      }
      if (mounted) setState(() => _locationServiceEnabled = true);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (mounted) {
      setState(() {
        _locationGranted = permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always;
      });

      if (!_locationGranted) {
        _showGoToSettingsDialog('定位权限', '请在系统设置中开启定位权限，以便使用位置条件功能。');
      }
    }
  }

  void _showGoToSettingsDialog(String title, String content) {
    final isDark = AppColorsHelper.isDark(context);
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
                  child: Container(color: Colors.black.withValues(alpha: 0.08)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 55),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E1E).withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E5E5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
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
                          title,
                          style: TextStyle(
                            color: AppColorsHelper.primaryText(context),
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          content,
                          style: TextStyle(
                            color: AppColorsHelper.secondaryText(context),
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
                                color: isDark ? AppColorsHelper.executeButtonEdge(context) : Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  openAppSettings();
                                },
                                borderRadius: BorderRadius.circular(12),
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
                                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F7F7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEAEAEA),
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Center(
                                  child: Text(
                                    '取消',
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
    final isDark = AppColorsHelper.isDark(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColorsHelper.scaffoldBackground(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColorsHelper.scaffoldBackground(context),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 68),
        child: GestureDetector(
          onTap: () => openAppSettings(),
          child: Text(
            '前往系统设置',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColorsHelper.brandColorSoft(context),
            ),
          ),
        ),
      ),
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
                    '系统权限',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: AppColorsHelper.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '管理App所需的系统权限',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColorsHelper.secondaryText(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPermissionCard(
                    icon: Icons.notifications_none_rounded,
                    title: '通知权限',
                    subtitle: '用于发送决定提醒通知',
                    isGranted: _notificationGranted,
                    onTap: _requestNotification,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildPermissionCard(
                    icon: Icons.location_on_outlined,
                    title: '位置信息权限',
                    subtitle: '用于基于位置的逻辑条件功能',
                    isGranted: _locationGranted,
                    onTap: _requestLocation,
                    isDark: isDark,
                    extraInfo: !_locationServiceEnabled
                        ? '定位服务未开启'
                        : null,
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

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onTap,
    required bool isDark,
    String? extraInfo,
  }) {
    final statusText = isGranted ? '已授权' : '未授权';
    final statusColor = isGranted
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
        : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626));

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
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColorsHelper.secondaryText(context),
                        ),
                      ),
                      if (extraInfo != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          extraInfo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
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
}
