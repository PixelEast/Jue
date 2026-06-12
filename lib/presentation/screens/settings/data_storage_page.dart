import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors_helper.dart';
import '../../../data/local/app_storage.dart';
import '../../widgets/frosted_back_button.dart';

class DataStoragePage extends StatefulWidget {
  const DataStoragePage({super.key});

  @override
  State<DataStoragePage> createState() => _DataStoragePageState();
}

class _DataStoragePageState extends State<DataStoragePage> {
  int _totalSpace = 0;
  int _freeSpace = 0;
  int _appSize = 0;
  int _decisionsSize = 0;
  int _historySize = 0;
  int _otherDataSize = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _appSize = await AppStorage.getTotalAppStorageSize();
    _decisionsSize = await AppStorage.getDecisionsSize();
    _historySize = await AppStorage.getHistorySize();
    _otherDataSize = await AppStorage.getOtherDataSize();

    try {
      if (Platform.isAndroid) {
        final result = await Process.run('df', ['/data']);
        final lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            _totalSpace = (int.tryParse(parts[1]) ?? 0) * 1024;
            _freeSpace = (int.tryParse(parts[3]) ?? 0) * 1024;
          }
        }
      }
    } catch (_) {}

    if (_totalSpace == 0) {
      try {
        final result = await Process.run('df', ['/']);
        final lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            _totalSpace = (int.tryParse(parts[1]) ?? 0) * 1024;
            _freeSpace = (int.tryParse(parts[3]) ?? 0) * 1024;
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _clearData(String title, Future<void> Function() clearFn) async {
    final confirmed = await _showConfirmDialog(title);
    if (confirmed == true) {
      await clearFn();
      await _loadData();
    }
  }

  Future<bool?> _showConfirmDialog(String title) {
    final isDark = AppColorsHelper.isDark(context);
    return showDialog<bool>(
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
                onTap: () => Navigator.pop(context, false),
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
                          '清除$title',
                          style: TextStyle(
                            color: AppColorsHelper.primaryText(context),
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          '确认清除$title吗？此操作无法撤销。',
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
                                onTap: () => Navigator.pop(context, true),
                                borderRadius: BorderRadius.circular(12),
                                child: const Center(
                                  child: Text(
                                    '确认清除',
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
                                onTap: () => Navigator.pop(context, false),
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColorsHelper.subPageBackground(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final otherAppsSize = _totalSpace - _freeSpace - _appSize;
    final isDark = AppColorsHelper.isDark(context);

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
                    '数据与存储',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: AppColorsHelper.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '查看存储占用，清理数据',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColorsHelper.secondaryText(context),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildStorageOverview(otherAppsSize, isDark),
                  const SizedBox(height: 32),
                  Text(
                    'App 数据',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColorsHelper.secondaryText(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDataCard(
                    icon: Icons.rule_outlined,
                    title: '决定数据',
                    size: _decisionsSize,
                    onClear: () => _clearData('决定数据', AppStorage.clearDecisions),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildDataCard(
                    icon: Icons.history_outlined,
                    title: '历史记录',
                    size: _historySize,
                    onClear: () => _clearData('历史记录', AppStorage.clearHistory),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildDataCard(
                    icon: Icons.storage_outlined,
                    title: '其他数据',
                    size: _otherDataSize,
                    subtitle: '草稿、缓存、使用习惯 · ${_formatSize(_otherDataSize)}',
                    onClear: () => _clearData('其他数据', AppStorage.clearOtherData),
                    isDark: isDark,
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

  Widget _buildStorageOverview(int otherAppsSize, bool isDark) {
    final totalGB = _totalSpace / (1024 * 1024 * 1024);
    final totalUsed = _totalSpace - _freeSpace;
    final usedRatio = _totalSpace > 0 ? totalUsed / _totalSpace : 0.0;
    final appRatio = _totalSpace > 0 ? _appSize / _totalSpace : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorsHelper.cardBackground(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColorsHelper.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '存储空间',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColorsHelper.primaryText(context),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 24,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
                  ),
                  FractionallySizedBox(
                    widthFactor: usedRatio.clamp(0.0, 1.0),
                    child: Container(
                      color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFF94A3B8),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: appRatio.clamp(0.0, 1.0),
                    child: Container(
                      color: const Color(0xFF2D5BFF),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLegend(const Color(0xFF2D5BFF), '决 App', _formatSize(_appSize)),
              const SizedBox(width: 16),
              _buildLegend(
                isDark ? const Color(0xFF3A3A3A) : const Color(0xFF94A3B8),
                '其他 App',
                _formatSize(otherAppsSize),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegend(
                isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
                '可用空间',
                _formatSize(_freeSpace),
              ),
              const SizedBox(width: 16),
              _buildLegend(
                Colors.transparent,
                '总空间',
                '${totalGB.toStringAsFixed(1)} GB',
                showDot: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label, String value, {bool showDot = true}) {
    return Expanded(
      child: Row(
        children: [
          if (showDot) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 12,
                color: AppColorsHelper.secondaryText(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard({
    required IconData icon,
    required String title,
    required int size,
    String? subtitle,
    required VoidCallback onClear,
    required bool isDark,
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
                      subtitle ?? _formatSize(size),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColorsHelper.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: size > 0 ? onClear : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: size > 0
                        ? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F3F3))
                        : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: size > 0
                          ? (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE7E7E7))
                          : (isDark ? const Color(0xFF252525) : const Color(0xFFF0F0F0)),
                    ),
                  ),
                  child: Text(
                    '清理',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: size > 0
                          ? AppColorsHelper.primaryText(context)
                          : AppColorsHelper.tertiaryText(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
