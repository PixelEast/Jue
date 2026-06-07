import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/decision_repository.dart';
import '../../data/local/app_storage.dart';
import 'notification_service.dart';
import 'usage_analyzer.dart';

class NotificationScheduler {
  static final NotificationScheduler _instance = NotificationScheduler._();
  factory NotificationScheduler() => _instance;
  NotificationScheduler._();

  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  final UsageAnalyzer _usageAnalyzer = UsageAnalyzer();

  void start() {
    _timer?.cancel();
    _checkAndNotify();
    _timer = Timer.periodic(const Duration(minutes: 30), (_) {
      _checkAndNotify();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkAndNotify() async {
    final settings = await AppStorage.getNotificationSettings();
    if (!settings.enabled || !settings.reminderEnabled) return;
    if (_isDndTime(settings)) return;

    final permission = await _notificationService.checkPermission();
    if (!permission) return;

    await _usageAnalyzer.analyzeAndUpdate();
    final patterns = await AppStorage.getUsagePatterns();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<_Candidate> candidates = [];

    for (final pattern in patterns) {
      if (pattern.priority < 0.1) continue;
      if (_isNotifiedToday(pattern, today)) continue;
      if (_isExecutedToday(pattern, today)) continue;

      final matchingSlot = _findMatchingSlot(pattern, now);
      if (matchingSlot == null) continue;

      if (pattern.frequentLocations.isNotEmpty) {
        final locationMatch = await _checkLocationMatch(pattern);
        if (!locationMatch) continue;
      }

      candidates.add(_Candidate(
        pattern: pattern,
        slot: matchingSlot,
        priority: pattern.priority,
      ));
    }

    if (candidates.isEmpty) return;

    candidates.sort((a, b) => b.priority.compareTo(a.priority));
    final winner = candidates.first;

    final decisions = await DecisionRepository().getAllDecisions();
    final decision = decisions
        .cast<Decision?>()
        .firstWhere((d) => d?.id == winner.pattern.decisionId,
            orElse: () => null);
    if (decision == null) return;

    final nowDate = DateTime(now.year, now.month, now.day);
    winner.pattern.lastNotifiedAt = now;
    if (winner.pattern.todayNotifyDate == null ||
        !_isSameDay(winner.pattern.todayNotifyDate!, nowDate)) {
      winner.pattern.todayNotifyCount = 1;
      winner.pattern.todayNotifyDate = nowDate;
    } else {
      winner.pattern.todayNotifyCount++;
    }
    await AppStorage.saveUsagePattern(winner.pattern);

    await _notificationService.showReminderNotification(
      id: winner.pattern.decisionId.hashCode.abs() % 2147483647,
      decisionTheme: decision.theme,
      decisionId: decision.id,
    );
  }

  bool _isDndTime(NotificationSettings settings) {
    if (!settings.dndEnabled) return false;
    final now = DateTime.now();
    final minute = now.hour * 60 + now.minute;
    final start = settings.dndStartHour * 60 + settings.dndStartMinute;
    final end = settings.dndEndHour * 60 + settings.dndEndMinute;

    if (start <= end) {
      return minute >= start && minute < end;
    }
    return minute >= start || minute < end;
  }

  bool _isNotifiedToday(DecisionUsagePattern pattern, DateTime today) {
    if (pattern.lastNotifiedAt == null) return false;
    return _isSameDay(pattern.lastNotifiedAt!, today);
  }

  bool _isExecutedToday(DecisionUsagePattern pattern, DateTime today) {
    if (pattern.todayNotifyDate != null &&
        _isSameDay(pattern.todayNotifyDate!, today) &&
        pattern.todayNotifyCount > 0) {
      return true;
    }
    return false;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  TimeSlot? _findMatchingSlot(DecisionUsagePattern pattern, DateTime now) {
    for (final slot in pattern.frequentSlots) {
      if (!slot.contains(now)) continue;

      final nowMinute = now.hour * 60 + now.minute;
      final midpoint = slot.midpointMinute;

      final start = slot.startHour * 60 + slot.startMinute;
      final end = slot.endHour * 60 + slot.endMinute;

      bool pastMidpoint;
      if (start <= end) {
        pastMidpoint = nowMinute >= midpoint;
      } else {
        if (nowMinute >= start) {
          pastMidpoint = nowMinute >= midpoint;
        } else {
          final adjustedMidpoint = (midpoint - start + 24 * 60) % (24 * 60);
          final adjustedNow = (nowMinute - start + 24 * 60) % (24 * 60);
          pastMidpoint = adjustedNow >= adjustedMidpoint;
        }
      }

      if (pastMidpoint) return slot;
    }
    return null;
  }

  Future<bool> _checkLocationMatch(DecisionUsagePattern pattern) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      for (final location in pattern.frequentLocations) {
        final distance = _calculateDistance(
          position.latitude,
          position.longitude,
          location.latitude,
          location.longitude,
        );
        if (distance <= location.radiusMeters) return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;
}

class _Candidate {
  final DecisionUsagePattern pattern;
  final TimeSlot slot;
  final double priority;

  _Candidate({
    required this.pattern,
    required this.slot,
    required this.priority,
  });
}
