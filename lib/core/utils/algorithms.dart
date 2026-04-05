import 'dart:math';
import '../../data/models/app_models.dart';

class WeightCalculator {
  static final Random _random = Random();

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

    switch (group.dynamicWeightMode) {
      case 'lowerWeight':
        selectedOption.currentWeight = selectedOption.baseWeight * 0.4;
        selectedOption.timesSelected++;
        selectedOption.lastSelectedAt = DateTime.now();
        break;
      case 'nextRemove':
        selectedOption.currentWeight = 0;
        selectedOption.pendingRecovery = true;
        selectedOption.timesSelected++;
        selectedOption.lastSelectedAt = DateTime.now();
        break;
      default:
        selectedOption.timesSelected++;
        selectedOption.lastSelectedAt = DateTime.now();
    }
  }

  void recoverWeights(OptionGroup group) {
    for (var option in group.options) {
      if (option.pendingRecovery) {
        option.currentWeight = option.baseWeight * 0.4;
        option.pendingRecovery = false;
      }

      final recoveryFactor = min(1.0, option.timesSelected * 0.1);
      option.currentWeight = _lerpDouble(
        option.currentWeight,
        option.baseWeight,
        recoveryFactor,
      ).clamp(0.1, 3.0);
    }
  }

  double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  void applyFeedback(Option option, String feedback, OptionGroup group) {
    switch (feedback) {
      case 'like':
        option.baseWeight = (option.baseWeight * 1.1).clamp(0.1, 3.0);
        option.currentWeight = option.baseWeight;
        break;
      case 'dislike':
        option.baseWeight = (option.baseWeight * 0.67).clamp(0.1, 3.0);
        option.currentWeight = option.baseWeight;
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
  OptionGroup? getActiveGroup(Decision decision) {
    if (!decision.isLogicConditionEnabled || decision.optionGroups.isEmpty) {
      return decision.optionGroups.isNotEmpty
          ? decision.optionGroups.first
          : null;
    }

    switch (decision.logicConditionType) {
      case 'time':
        return _getGroupByTime(decision);
      case 'location':
        return _getGroupByLocation(decision);
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

  OptionGroup? _getGroupByLocation(Decision decision) {
    if (decision.optionGroups.isEmpty) return null;

    final defaultGroup = decision.optionGroups.firstWhere(
      (g) => g.isDefaultGroup,
      orElse: () => decision.optionGroups.first,
    );

    return defaultGroup;
  }
}
