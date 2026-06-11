import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class VersionInfo {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String releaseNotes;

  const VersionInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    final tagName = (json['tag_name'] as String? ?? '').replaceAll('v', '').replaceAll('V', 'V');
    final body = json['body'] as String? ?? '';
    final assets = json['assets'] as List<dynamic>? ?? [];

    String downloadUrl = '';
    for (final asset in assets) {
      final name = (asset as Map<String, dynamic>)['name'] as String? ?? '';
      if (name.contains('arm64') && name.endsWith('.apk')) {
        downloadUrl = asset['browser_download_url'] as String? ?? '';
        break;
      }
    }
    if (downloadUrl.isEmpty && assets.isNotEmpty) {
      downloadUrl = (assets.first as Map<String, dynamic>)['browser_download_url'] as String? ?? '';
    }

    int buildNumber = 0;
    final buildMatch = RegExp(r'\+(\d+)').firstMatch(tagName);
    if (buildMatch != null) {
      buildNumber = int.tryParse(buildMatch.group(1)!) ?? 0;
    }

    return VersionInfo(
      version: tagName,
      buildNumber: buildNumber,
      downloadUrl: downloadUrl,
      releaseNotes: body,
    );
  }
}

class VersionService {
  static final VersionService _instance = VersionService._();
  factory VersionService() => _instance;
  VersionService._();

  static const _apiUrl = 'https://api.github.com/repos/PixelEast/Jue/releases/latest';
  VersionInfo? _cachedInfo;
  DateTime? _lastCheckTime;

  Future<VersionInfo?> checkForUpdate({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedInfo != null && _lastCheckTime != null) {
      if (DateTime.now().difference(_lastCheckTime!).inMinutes < 30) {
        return _cachedInfo;
      }
    }

    try {
      debugPrint('VersionService: Checking for update...');
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final info = VersionInfo.fromJson(json);
        _cachedInfo = info;
        _lastCheckTime = DateTime.now();
        debugPrint('VersionService: Latest version: ${info.version} (build ${info.buildNumber})');
        return info;
      }
      debugPrint('VersionService: API returned ${response.statusCode}');
    } catch (e) {
      debugPrint('VersionService: Error: $e');
    }
    return null;
  }

  bool hasUpdate(VersionInfo remoteInfo) {
    final currentBuild = _extractBuildNumber(AppConstants.appVersion);
    return remoteInfo.buildNumber > currentBuild;
  }

  int _extractBuildNumber(String version) {
    final match = RegExp(r'(\d+)$').firstMatch(version);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }
}
