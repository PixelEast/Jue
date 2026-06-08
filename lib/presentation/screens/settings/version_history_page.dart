import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/frosted_back_button.dart';

class VersionHistoryPage extends StatefulWidget {
  const VersionHistoryPage({super.key});

  @override
  State<VersionHistoryPage> createState() => _VersionHistoryPageState();
}

class _VersionHistoryPageState extends State<VersionHistoryPage> {
  static const String _cacheKey = 'version_history_cache';
  static const int _maxReleases = 15;

  List<_ReleaseRecord> _releases = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isNetworkError = false;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _loadReleases();
  }

  Future<void> _loadReleases() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _isNetworkError = false;
    });

    try {
      final response = await http
          .get(
            Uri.parse('https://api.github.com/repos/PixelEast/Jue/releases'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final releases = data
            .take(_maxReleases)
            .map((json) {
              return _ReleaseRecord(
                version: json['tag_name'] as String? ?? '',
                body: json['body'] as String? ?? '',
                publishedAt: json['published_at'] as String? ?? '',
              );
            })
            .where((r) => r.version.isNotEmpty)
            .toList();

        await _saveToCache(releases);

        if (mounted) {
          setState(() {
            _releases = releases;
            _isLoading = false;
          });
        }
      } else {
        await _loadFromCache();
      }
    } catch (_) {
      await _loadFromCache();
    }
  }

  Future<void> _saveToCache(List<_ReleaseRecord> releases) async {
    final prefs = await SharedPreferences.getInstance();
    final json = releases.map((r) => r.toJson()).toList();
    await prefs.setString(_cacheKey, jsonEncode(json));
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);

      if (cached != null) {
        final List<dynamic> data = jsonDecode(cached);
        final releases = data
            .map((json) => _ReleaseRecord.fromJson(json as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _releases = releases;
            _isLoading = false;
            _hasError = false;
            _isNetworkError = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _isNetworkError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF9F9F9),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
                  ? _buildErrorState()
                  : _buildReleaseList(),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: FrostedBackButton(
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  child: const Text(
                    '版本记录',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isNetworkError
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              size: 72,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              _isNetworkError ? '无网络连接' : '获取版本记录失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isNetworkError
                  ? '请检查网络连接后重试'
                  : '服务器返回了错误，请稍后再试',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 140,
              height: 44,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: _loadReleases,
                    borderRadius: BorderRadius.circular(12),
                    child: const Center(
                      child: Text(
                        '重新加载',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
    );
  }

  Widget _buildReleaseList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(32, 130, 32, 100),
      itemCount: _releases.length,
      itemBuilder: (context, index) {
        return _buildReleaseItem(index);
      },
    );
  }

  Widget _buildReleaseItem(int index) {
    final release = _releases[index];
    final isExpanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedIndex = isExpanded ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7E7E7)),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      release.version,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (release.publishedAt.isNotEmpty)
                    Text(
                      _formatDate(release.publishedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
              if (isExpanded && release.body.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE7E7E7)),
                  ),
                  child: Text(
                    release.body,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF5E5E5E),
                      height: 1.6,
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

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _ReleaseRecord {
  final String version;
  final String body;
  final String publishedAt;

  const _ReleaseRecord({
    required this.version,
    required this.body,
    required this.publishedAt,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'body': body,
        'publishedAt': publishedAt,
      };

  factory _ReleaseRecord.fromJson(Map<String, dynamic> json) =>
      _ReleaseRecord(
        version: json['version'] as String? ?? '',
        body: json['body'] as String? ?? '',
        publishedAt: json['publishedAt'] as String? ?? '',
      );
}
