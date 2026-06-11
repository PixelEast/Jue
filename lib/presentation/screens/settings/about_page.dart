import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors_helper.dart';
import '../../../core/utils/version_service.dart';
import '../../widgets/frosted_back_button.dart';
import 'version_history_page.dart';
import 'feedback_page.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  VersionInfo? _updateInfo;
  bool _isChecking = false;
  bool _hasChecked = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _downloadedFilePath;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate({bool forceRefresh = false}) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final info = await VersionService().checkForUpdate(forceRefresh: forceRefresh);

    if (mounted) {
      setState(() {
        _isChecking = false;
        _hasChecked = true;
        if (info != null && VersionService().hasUpdate) {
          _updateInfo = info;
        } else {
          _updateInfo = null;
        }
      });
    }
  }

  Future<void> _downloadUpdate() async {
    if (_updateInfo?.downloadUrl.isEmpty != false) return;
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        if (mounted) {
          setState(() => _isDownloading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法获取存储目录')),
          );
        }
        return;
      }

      final savePath = '${dir.path}/jue-update.apk';
      final dio = Dio();

      await dio.download(
        _updateInfo!.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadedFilePath = savePath;
        });
        _installApk();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    }
  }

  Future<void> _installApk() async {
    if (_downloadedFilePath == null) return;
    try {
      final file = File(_downloadedFilePath!);
      if (await file.exists()) {
        await OpenFile.open(_downloadedFilePath!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开安装包: $e')),
        );
      }
    }
  }

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
                  if (_updateInfo != null) ...[
                    _buildUpdateCard(isDark),
                    const SizedBox(height: 12),
                  ],
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
                    subtitle: _isChecking
                        ? '正在检查更新...'
                        : (_hasChecked
                            ? (_updateInfo != null ? '发现新版本 ${_updateInfo!.version}' : '当前已是最新版本')
                            : '点击检查更新'),
                    onTap: () => _checkForUpdate(forceRefresh: true),
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

  Widget _buildUpdateCard(bool isDark) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1B4D8F), const Color(0xFF0F2D5A)]
                : [const Color(0xFF2D5BFF), const Color(0xFF1A3D9E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '新版本',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _updateInfo!.version,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (_updateInfo!.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _updateInfo!.releaseNotes,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (_isDownloading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress : null,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _downloadProgress > 0
                      ? '下载中 ${(_downloadProgress * 100).toInt()}%'
                      : '准备下载...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: _downloadUpdate,
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Text(
                            '立即更新',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D5BFF),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
