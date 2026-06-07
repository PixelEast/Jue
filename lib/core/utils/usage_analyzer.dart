import '../../data/models/app_models.dart';
import '../../data/repositories/decision_repository.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/local/app_storage.dart';

class UsageAnalyzer {
  final DecisionRepository _decisionRepo = DecisionRepository();
  final HistoryRepository _historyRepo = HistoryRepository();

  static const Duration _dedupeWindow = Duration(minutes: 5);

  Future<void> analyzeAndUpdate() async {
    final decisions = await _decisionRepo.getAllDecisions();
    final records = await _historyRepo.getAllRecords();
    final existingPatterns = await AppStorage.getUsagePatterns();
    final now = DateTime.now();

    final Map<String, List<HistoryRecord>> recordsByDecision = {};
    for (final record in records) {
      recordsByDecision.putIfAbsent(record.decisionId, () => []).add(record);
    }

    for (final entry in recordsByDecision.entries) {
      entry.value.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    final List<DecisionUsagePattern> updatedPatterns = [];
    double maxExecutionsPerWeek = 0;

    for (final decision in decisions) {
      if (decision.isDraft) continue;

      final rawRecords = recordsByDecision[decision.id] ?? [];
      final decisionRecords = _deduplicateRecords(rawRecords);
      final existingPattern = existingPatterns
          .cast<DecisionUsagePattern?>()
          .firstWhere((p) => p?.decisionId == decision.id, orElse: () => null);

      final pattern = _analyzeDecision(
        decision,
        decisionRecords,
        existingPattern,
        now,
      );

      if (pattern.executionsPerWeek > maxExecutionsPerWeek) {
        maxExecutionsPerWeek = pattern.executionsPerWeek;
      }

      updatedPatterns.add(pattern);
    }

    for (final pattern in updatedPatterns) {
      pattern.priority = maxExecutionsPerWeek > 0
          ? pattern.executionsPerWeek / maxExecutionsPerWeek
          : 0;
    }

    await AppStorage.saveUsagePatterns(updatedPatterns);
  }

  DecisionUsagePattern _analyzeDecision(
    Decision decision,
    List<HistoryRecord> records,
    DecisionUsagePattern? existing,
    DateTime now,
  ) {
    final totalExecutions = records.length;
    if (totalExecutions == 0) {
      return DecisionUsagePattern(
        decisionId: decision.id,
        totalExecutions: 0,
        lastAnalyzedAt: now,
        lastNotifiedAt: existing?.lastNotifiedAt,
        todayNotifyCount: existing?.todayNotifyCount ?? 0,
        todayNotifyDate: existing?.todayNotifyDate,
      );
    }

    final firstRecord = records.last.createdAt;
    final daysSinceFirst = now.difference(firstRecord).inDays;
    final weeksSinceFirst = daysSinceFirst < 7 ? 1.0 : daysSinceFirst / 7.0;
    final executionsPerWeek = totalExecutions / weeksSinceFirst;

    final frequentSlots = _analyzeTimeSlots(records);
    final frequentWeekdays = _analyzeWeekdays(records);
    final frequentLocations = _analyzeLocations(decision, records);

    return DecisionUsagePattern(
      decisionId: decision.id,
      totalExecutions: totalExecutions,
      executionsPerWeek: executionsPerWeek,
      frequentSlots: frequentSlots,
      frequentLocations: frequentLocations,
      frequentWeekdays: frequentWeekdays,
      lastAnalyzedAt: now,
      lastNotifiedAt: existing?.lastNotifiedAt,
      todayNotifyCount: existing?.todayNotifyCount ?? 0,
      todayNotifyDate: existing?.todayNotifyDate,
    );
  }

  List<TimeSlot> _analyzeTimeSlots(List<HistoryRecord> records) {
    final Map<int, int> hourCounts = {};
    for (final record in records) {
      final hour = record.createdAt.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    if (hourCounts.isEmpty) return [];

    final sortedHours = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<TimeSlot> slots = [];
    final usedHours = <int>{};

    for (final entry in sortedHours) {
      if (usedHours.contains(entry.key)) continue;
      if (slots.length >= 2) break;

      final clusterHours = <int>[entry.key];
      usedHours.add(entry.key);

      for (final other in sortedHours) {
        if (usedHours.contains(other.key)) continue;
        final diff = (entry.key - other.key).abs();
        if (diff <= 2 || diff >= 22) {
          clusterHours.add(other.key);
          usedHours.add(other.key);
        }
      }

      clusterHours.sort();
      final startHour = clusterHours.first;
      final endHour = clusterHours.last;
      final frequency = clusterHours
          .map((h) => hourCounts[h] ?? 0)
          .reduce((a, b) => a + b)
          .toDouble() /
          records.length;

      slots.add(TimeSlot(
        startHour: startHour,
        startMinute: 0,
        endHour: (endHour + 1).clamp(0, 23),
        endMinute: 0,
        frequency: frequency,
      ));
    }

    return slots;
  }

  List<int> _analyzeWeekdays(List<HistoryRecord> records) {
    final Map<int, int> weekdayCounts = {};
    for (final record in records) {
      final weekday = record.createdAt.weekday;
      weekdayCounts[weekday] = (weekdayCounts[weekday] ?? 0) + 1;
    }

    if (weekdayCounts.isEmpty) return [];

    final threshold = records.length * 0.15;
    return weekdayCounts.entries
        .where((e) => e.value >= threshold)
        .map((e) => e.key)
        .toList()
      ..sort();
  }

  List<LocationCluster> _analyzeLocations(
    Decision decision,
    List<HistoryRecord> records,
  ) {
    if (decision.logicConditionType != 'location') return [];

    final Map<String, int> groupCounts = {};
    for (final record in records) {
      groupCounts[record.optionGroupName] =
          (groupCounts[record.optionGroupName] ?? 0) + 1;
    }

    final List<LocationCluster> clusters = [];
    for (final entry in groupCounts.entries) {
      final group = decision.optionGroups
          .cast<OptionGroup?>()
          .firstWhere((g) => g?.name == entry.key, orElse: () => null);

      if (group != null &&
          group.latitude != null &&
          group.longitude != null &&
          group.radiusMeters != null) {
        clusters.add(LocationCluster(
          optionGroupName: entry.key,
          latitude: group.latitude!,
          longitude: group.longitude!,
          radiusMeters: group.radiusMeters!,
          locationLabel: group.locationLabel,
          frequency: entry.value,
        ));
      }
    }

    clusters.sort((a, b) => b.frequency.compareTo(a.frequency));
    return clusters;
  }

  List<HistoryRecord> _deduplicateRecords(List<HistoryRecord> records) {
    if (records.isEmpty) return [];

    final List<HistoryRecord> result = [records.first];
    for (var i = 1; i < records.length; i++) {
      final current = records[i];
      final previous = result.last;
      if (current.createdAt.difference(previous.createdAt) > _dedupeWindow) {
        result.add(current);
      }
    }
    return result;
  }
}
