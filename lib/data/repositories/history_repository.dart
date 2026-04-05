import '../models/app_models.dart';
import '../local/app_storage.dart';

class HistoryRepository {
  Future<List<HistoryRecord>> getAllRecords() async {
    return await AppStorage.getHistory();
  }

  Future<List<HistoryRecord>> getLast7DaysRecords() async {
    final records = await getAllRecords();
    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day - 7);
    return records.where((r) => r.createdAt.isAfter(sevenDaysAgo)).toList();
  }

  Future<int> getTotalCount() async {
    final records = await getAllRecords();
    return records.length;
  }

  Future<HistoryRecord> addRecord(HistoryRecord record) async {
    return await AppStorage.addHistoryRecord(record);
  }

  Future<void> updateFeedback(String id, String feedback) async {
    await AppStorage.updateFeedback(id, feedback);
  }

  Future<void> deleteRecord(String id) async {
    await AppStorage.deleteHistoryRecord(id);
  }

  Future<Map<String, int>> getDailyCounts() async {
    final records = await getLast7DaysRecords();
    final counts = <String, int>{};
    for (final record in records) {
      final key = record.dateOnly.toString().substring(0, 10);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }
}
