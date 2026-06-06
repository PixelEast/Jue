import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class AppStorage {
  static const String _decisionsKey = 'decisions';
  static const String _historyKey = 'history';

  static Future<List<Decision>> getDecisions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_decisionsKey) ?? [];
    return data
        .map((e) => Decision.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveDecisions(List<Decision> decisions) async {
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_historyKey) ?? [];
    return data
        .map(
          (e) => HistoryRecord.fromJson(jsonDecode(e) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> saveHistory(List<HistoryRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _historyKey,
      records.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  static Future<HistoryRecord> addHistoryRecord(HistoryRecord record) async {
    final records = await getHistory();
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
    final prefs = await SharedPreferences.getInstance();
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
}
