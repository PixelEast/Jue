import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../../core/utils/app_events.dart';

class AppStorage {
  static const String _decisionsKey = 'decisions';
  static const String _historyKey = 'history';
  static const String _notificationSettingsKey = 'notification_settings';
  static const String _usagePatternsKey = 'usage_patterns';
  static const String _darkModeKey = 'dark_mode';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<List<Decision>> getDecisions() async {
    final prefs = await _getPrefs();
    final data = prefs.getStringList(_decisionsKey) ?? [];
    return data
        .map((e) => Decision.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveDecisions(List<Decision> decisions) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(
      _decisionsKey,
      decisions.map((d) => jsonEncode(d.toJson())).toList(),
    );
  }

  static Future<Decision?> saveDecision(Decision decision) async {
    final decisions = await getDecisions();
    final index = decisions.indexWhere((d) => d.id == decision.id);
    if (index >= 0) {
      decisions[index] = decision;
    } else {
      decisions.add(decision);
    }
    await saveDecisions(decisions);
    return decision;
  }

  static Future<void> deleteDecision(String id) async {
    final decisions = await getDecisions();
    decisions.removeWhere((d) => d.id == id);
    await saveDecisions(decisions);
  }

  static Future<List<HistoryRecord>> getHistory() async {
    final prefs = await _getPrefs();
    final data = prefs.getStringList(_historyKey) ?? [];
    return data
        .map(
          (e) => HistoryRecord.fromJson(jsonDecode(e) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> saveHistory(List<HistoryRecord> records) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(
      _historyKey,
      records.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  static Future<HistoryRecord> addHistoryRecord(HistoryRecord record) async {
    final records = await getHistory();

    if (records.isNotEmpty) {
      final lastRecordTime = records.first.createdAt;
      if (!record.createdAt.isAfter(lastRecordTime)) {
        record.createdAt = lastRecordTime.add(const Duration(milliseconds: 1));
      }
    }

    records.insert(0, record);
    await saveHistory(records);
    return record;
  }

  static Future<void> updateFeedback(String id, String feedback) async {
    final records = await getHistory();
    final index = records.indexWhere((r) => r.id == id);
    if (index >= 0) {
      records[index].feedback = feedback;
      await saveHistory(records);
    }
  }

  static Future<void> deleteHistoryRecord(String id) async {
    final records = await getHistory();
    records.removeWhere((r) => r.id == id);
    await saveHistory(records);
  }

  static Future<List<HistoryRecord>> getHistoryPaginated({
    required int offset,
    required int limit,
  }) async {
    final prefs = await _getPrefs();
    final data = prefs.getStringList(_historyKey) ?? [];
    final allRecords = data
        .map(
          (e) => HistoryRecord.fromJson(jsonDecode(e) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final start = offset.clamp(0, allRecords.length);
    final end = (offset + limit).clamp(0, allRecords.length);
    return allRecords.sublist(start, end);
  }

  static Future<NotificationSettings> getNotificationSettings() async {
    final prefs = await _getPrefs();
    final data = prefs.getString(_notificationSettingsKey);
    if (data == null) return NotificationSettings();
    return NotificationSettings.fromJson(
      jsonDecode(data) as Map<String, dynamic>,
    );
  }

  static Future<void> saveNotificationSettings(
    NotificationSettings settings,
  ) async {
    final prefs = await _getPrefs();
    await prefs.setString(
      _notificationSettingsKey,
      jsonEncode(settings.toJson()),
    );
  }

  static Future<List<DecisionUsagePattern>> getUsagePatterns() async {
    final prefs = await _getPrefs();
    final data = prefs.getStringList(_usagePatternsKey) ?? [];
    return data
        .map(
          (e) => DecisionUsagePattern.fromJson(
            jsonDecode(e) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<void> saveUsagePatterns(
    List<DecisionUsagePattern> patterns,
  ) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(
      _usagePatternsKey,
      patterns.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }

  static Future<void> saveUsagePattern(DecisionUsagePattern pattern) async {
    final patterns = await getUsagePatterns();
    final index = patterns.indexWhere((p) => p.decisionId == pattern.decisionId);
    if (index >= 0) {
      patterns[index] = pattern;
    } else {
      patterns.add(pattern);
    }
    await saveUsagePatterns(patterns);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await _getPrefs();
    final data = prefs.get(_darkModeKey);
    if (data is bool) return data;
    if (data is int) return data != 0;
    return true;
  }

  static Future<void> saveDarkMode(bool isDark) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_darkModeKey, isDark);
  }

  static Future<int> _getPrefsKeySize(String key) async {
    try {
      final prefs = await _getPrefs();
      final value = prefs.get(key);
      if (value == null) return 0;
      if (value is String) return utf8.encode(value).length;
      if (value is List<String>) {
        int total = 0;
        for (final s in value) {
          total += utf8.encode(s).length;
        }
        return total;
      }
      if (value is bool) return 1;
      if (value is int) return 8;
      if (value is double) return 8;
    } catch (_) {}
    return 0;
  }

  static Future<int> getDecisionsSize() => _getPrefsKeySize(_decisionsKey);
  static Future<int> getHistorySize() => _getPrefsKeySize(_historyKey);

  static Future<int> getOtherDataSize() async {
    int total = 0;
    total += await _getPrefsKeySize(_usagePatternsKey);
    total += await _getPrefsKeySize(_notificationSettingsKey);
    total += await _getPrefsKeySize(_darkModeKey);
    try {
      final prefs = await _getPrefs();
      if (prefs.containsKey('version_history_cache')) {
        total += await _getPrefsKeySize('version_history_cache');
      }
    } catch (_) {}
    return total;
  }

  static Future<int> _getDirectorySize(Directory dir) async {
    int total = 0;
    try {
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            total += await entity.length();
          }
        }
      }
    } catch (_) {}
    return total;
  }

  static Future<int> getTotalAppStorageSize() async {
    // Try native Android StorageStats API
    try {
      const channel = MethodChannel('com.example.jue/storage');
      final size = await channel.invokeMethod<int>('getAppSize');
      if (size != null && size > 0) return size;
    } catch (_) {}

    // Fallback: measure directories manually
    int fallback = 0;
    try {
      final supportDir = await getApplicationSupportDirectory();
      final appRoot = supportDir.parent;
      fallback += await _getDirectorySize(appRoot);
    } catch (_) {}
    try {
      final cacheDir = await getTemporaryDirectory();
      fallback += await _getDirectorySize(cacheDir);
    } catch (_) {}
    return fallback;
  }

  static Future<void> clearDecisions() async {
    final prefs = await _getPrefs();
    await prefs.remove(_decisionsKey);
    AppEvents.notifyDecisionsChanged();
  }

  static Future<void> clearHistory() async {
    final prefs = await _getPrefs();
    await prefs.remove(_historyKey);
    AppEvents.notifyHistoryChanged();
  }

  static Future<void> clearOtherData() async {
    final prefs = await _getPrefs();
    await prefs.remove(_usagePatternsKey);
    await prefs.remove('version_history_cache');
    final decisions = await getDecisions();
    final nonDraft = decisions.where((d) => !d.isDraft).toList();
    await saveDecisions(nonDraft);
  }
}
