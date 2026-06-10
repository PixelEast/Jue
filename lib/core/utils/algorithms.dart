import 'dart:math';
import '../../data/models/app_models.dart';

class WeightCalculator {
  static final Random _random = Random();
  static const int _maxRecoverySteps = 5;

  Map<String, double> calculateProbabilities(OptionGroup group) {
    final totalWeight = group.options.fold<double>(
      0,
      (sum, option) => sum + option.currentWeight,
    );

    if (totalWeight == 0) {
      return {
        for (var option in group.options) option.id: 1.0 / group.options.length,
      };
    }

    return {
      for (var option in group.options)
        option.id: option.currentWeight / totalWeight,
    };
  }

  Option selectOption(OptionGroup group) {
    if (group.options.isEmpty) {
      throw StateError('选项组为空');
    }

    final probabilities = calculateProbabilities(group);
    final randomValue = _random.nextDouble();

    var cumulative = 0.0;
    for (var option in group.options) {
      cumulative += probabilities[option.id]!;
      if (randomValue <= cumulative) {
        return option;
      }
    }

    return group.options.last;
  }

  void applyDynamicWeight(Option selectedOption, OptionGroup group) {
    if (!group.dynamicWeightEnabled) return;

    // First advance recovery for all other options based on one execution cycle.
    for (final option in group.options) {
      if (option.id == selectedOption.id) continue;
      _advanceRecovery(option);
    }

    switch (group.dynamicWeightMode) {
      case 'lowerWeight':
        selectedOption.currentWeight = selectedOption.baseWeight * 0.4;
        selectedOption.pendingRecovery = false;
        selectedOption.recoveryStepsRemaining = _maxRecoverySteps;
        selectedOption.timesSelected++;
        selectedOption.lastSelectedAt = DateTime.now();
        break;
      case 'nextRemove':
        if (group.options.length == 1) {
          selectedOption.currentWeight = selectedOption.baseWeight * 0.4;
          selectedOption.pendingRecovery = false;
          selectedOption.recoveryStepsRemaining = _maxRecoverySteps;
        } else {
          selectedOption.currentWeight = 0;
          selectedOption.pendingRecovery = true;
          selectedOption.recoveryStepsRemaining = _maxRecoverySteps;
        }
        selectedOption.timesSelected++;
        selectedOption.lastSelectedAt = DateTime.now();
        break;
      default:
        selectedOption.timesSelected++;
        selectedOption.lastSelectedAt = DateTime.now();
    }
  }

  void recoverWeights(OptionGroup group) {
    // Recovery now advances on each subsequent execution in applyDynamicWeight.
  }

  void _advanceRecovery(Option option) {
    final recoveryTarget = (option.baseWeight + option.feedbackBias).clamp(0.1, 3.0);

    if (option.pendingRecovery) {
      option.currentWeight = option.baseWeight * 0.4;
      option.pendingRecovery = false;
      if (option.recoveryStepsRemaining > 0) {
        option.recoveryStepsRemaining -= 1;
      }
      return;
    }

    if (option.recoveryStepsRemaining > 0) {
      final completed = _maxRecoverySteps - option.recoveryStepsRemaining + 1;
      final t = (completed / _maxRecoverySteps).clamp(0.0, 1.0);
      option.currentWeight = _lerpDouble(
        option.baseWeight * 0.4,
        recoveryTarget,
        t,
      ).clamp(0.1, 3.0);
      option.recoveryStepsRemaining -= 1;
      if (option.recoveryStepsRemaining <= 0) {
        option.currentWeight = recoveryTarget;
        option.recoveryStepsRemaining = 0;
      }
    }
  }

  double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  void applyFeedback(Option option, String feedback, OptionGroup group) {
    switch (feedback) {
      case 'like':
        option.feedbackBias += 0.3;
        option.currentWeight = (option.currentWeight + 0.3).clamp(0.1, 3.0);
        break;
      case 'dislike':
        option.feedbackBias -= 0.33;
        option.currentWeight = (option.currentWeight * 0.67).clamp(0.1, 3.0);
        break;
      case 'removed':
        group.options.removeWhere((o) => o.id == option.id);
        break;
    }
  }
}

class DecisionSorter {
  List<Decision> sortDecisions(List<Decision> decisions) {
    final now = DateTime.now();
    final currentHour = now.hour;

    return [...decisions]..sort((a, b) {
      final aTimeScore = _calculateTimeSlotScore(a, currentHour);
      final bTimeScore = _calculateTimeSlotScore(b, currentHour);
      if (aTimeScore != bTimeScore) return bTimeScore.compareTo(aTimeScore);

      if (a.usageCount != b.usageCount) {
        return b.usageCount.compareTo(a.usageCount);
      }

      return b.createdAt.compareTo(a.createdAt);
    });
  }

  int _calculateTimeSlotScore(Decision decision, int currentHour) {
    if (decision.optionGroups.isEmpty) return 0;

    int score = 0;
    for (var group in decision.optionGroups) {
      if (group.startHour != null && group.endHour != null) {
        if (currentHour >= group.startHour! && currentHour < group.endHour!) {
          score += decision.timeSlotUsageCount;
        }
      } else if (group.latitude != null && group.longitude != null) {
        score += decision.usageCount ~/ 2;
      }
    }
    return score;
  }
}

class LogicConditionEngine {
  OptionGroup? getActiveGroup(
    Decision decision, {
    double? currentLatitude,
    double? currentLongitude,
  }) {
    if (!decision.isLogicConditionEnabled || decision.optionGroups.isEmpty) {
      return decision.optionGroups.isNotEmpty
          ? decision.optionGroups.first
          : null;
    }

    switch (decision.logicConditionType) {
      case 'time':
        return _getGroupByTime(decision);
      case 'location':
        return _getGroupByLocation(
          decision,
          currentLatitude: currentLatitude,
          currentLongitude: currentLongitude,
        );
      default:
        return decision.optionGroups.first;
    }
  }

  OptionGroup? _getGroupByTime(Decision decision) {
    final currentHour = DateTime.now().hour;

    for (var group in decision.optionGroups) {
      if (group.startHour != null && group.endHour != null) {
        if (currentHour >= group.startHour! && currentHour < group.endHour!) {
          return group;
        }
      }
    }

    return decision.optionGroups.firstWhere(
      (g) => g.isDefaultGroup,
      orElse: () => decision.optionGroups.first,
    );
  }

  OptionGroup? _getGroupByLocation(
    Decision decision, {
    double? currentLatitude,
    double? currentLongitude,
  }) {
    if (decision.optionGroups.isEmpty) return null;

    final defaultGroup = decision.optionGroups.firstWhere(
      (g) => g.isDefaultGroup,
      orElse: () => decision.optionGroups.first,
    );

    if (currentLatitude == null || currentLongitude == null) {
      return defaultGroup;
    }

    final matchingGroups = <MapEntry<OptionGroup, double>>[];
    for (final group in decision.optionGroups) {
      if (group.latitude == null ||
          group.longitude == null ||
          group.radiusMeters == null) {
        continue;
      }
      final distance = _distanceMeters(
        currentLatitude,
        currentLongitude,
        group.latitude!,
        group.longitude!,
      );
      if (distance <= group.radiusMeters!) {
        matchingGroups.add(MapEntry(group, distance));
      }
    }

    if (matchingGroups.isEmpty) return defaultGroup;

    matchingGroups.sort((a, b) => a.value.compareTo(b.value));
    final closestDistance = matchingGroups.first.value;
    final closestGroups = matchingGroups
        .where((entry) => (entry.value - closestDistance).abs() < 0.001)
        .map((entry) => entry.key)
        .toList();

    if (closestGroups.length == 1) {
      return closestGroups.first;
    }

    return closestGroups[Random().nextInt(closestGroups.length)];
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;
}
