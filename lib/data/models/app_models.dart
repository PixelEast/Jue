class Option {
  String id;
  String name;
  double baseWeight;
  double currentWeight;
  int timesSelected;
  DateTime? lastSelectedAt;
  bool pendingRecovery;
  int recoveryStepsRemaining;

  Option({
    required this.id,
    required this.name,
    this.baseWeight = 1.0,
    this.currentWeight = 1.0,
    this.timesSelected = 0,
    this.lastSelectedAt,
    this.pendingRecovery = false,
    this.recoveryStepsRemaining = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseWeight': baseWeight,
    'currentWeight': currentWeight,
    'timesSelected': timesSelected,
    'lastSelectedAt': lastSelectedAt?.toIso8601String(),
    'pendingRecovery': pendingRecovery,
    'recoveryStepsRemaining': recoveryStepsRemaining,
  };

  factory Option.fromJson(Map<String, dynamic> json) => Option(
    id:
        json['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    name: json['name'] as String? ?? '选项',
    baseWeight: (json['baseWeight'] as num?)?.toDouble() ?? 1.0,
    currentWeight: (json['currentWeight'] as num?)?.toDouble() ?? 1.0,
    timesSelected: json['timesSelected'] as int? ?? 0,
    lastSelectedAt: json['lastSelectedAt'] != null
        ? DateTime.tryParse(json['lastSelectedAt'] as String)
        : null,
    pendingRecovery: json['pendingRecovery'] as bool? ?? false,
    recoveryStepsRemaining: json['recoveryStepsRemaining'] as int? ?? 0,
  );
}

class OptionGroup {
  String id;
  String name;
  List<Option> options;
  bool dynamicWeightEnabled;
  String dynamicWeightMode;
  int? startHour;
  int? endHour;
  double? latitude;
  double? longitude;
  double? radiusMeters;
  bool isDefaultGroup;
  String conditionSummary;
  String locationLabel;

  OptionGroup({
    required this.id,
    required this.name,
    required this.options,
    this.dynamicWeightEnabled = true,
    this.dynamicWeightMode = 'lowerWeight',
    this.startHour,
    this.endHour,
    this.latitude,
    this.longitude,
    this.radiusMeters,
    this.isDefaultGroup = false,
    this.conditionSummary = '',
    this.locationLabel = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'options': options.map((o) => o.toJson()).toList(),
    'dynamicWeightEnabled': dynamicWeightEnabled,
    'dynamicWeightMode': dynamicWeightMode,
    'startHour': startHour,
    'endHour': endHour,
    'latitude': latitude,
    'longitude': longitude,
    'radiusMeters': radiusMeters,
    'isDefaultGroup': isDefaultGroup,
    'conditionSummary': conditionSummary,
    'locationLabel': locationLabel,
  };

  factory OptionGroup.fromJson(Map<String, dynamic> json) => OptionGroup(
    id: json['id'] as String,
    name: json['name'] as String,
    options: (json['options'] as List)
        .map((o) => Option.fromJson(o as Map<String, dynamic>))
        .toList(),
    dynamicWeightEnabled: json['dynamicWeightEnabled'] as bool? ?? true,
    dynamicWeightMode: json['dynamicWeightMode'] as String? ?? 'lowerWeight',
    startHour: json['startHour'] as int?,
    endHour: json['endHour'] as int?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    radiusMeters: (json['radiusMeters'] as num?)?.toDouble(),
    isDefaultGroup: json['isDefaultGroup'] as bool? ?? false,
    conditionSummary: json['conditionSummary'] as String? ?? '',
    locationLabel: json['locationLabel'] as String? ?? '',
  );
}

class Decision {
  String id;
  String theme;
  DateTime createdAt;
  int usageCount;
  DateTime? lastUsedAt;
  int timeSlotUsageCount;
  List<OptionGroup> optionGroups;
  bool isLogicConditionEnabled;
  String logicConditionType;
  bool isDraft;
  DateTime? draftUpdatedAt;

  Decision({
    required this.id,
    required this.theme,
    DateTime? createdAt,
    this.usageCount = 0,
    this.lastUsedAt,
    this.timeSlotUsageCount = 0,
    this.optionGroups = const [],
    this.isLogicConditionEnabled = false,
    this.logicConditionType = 'none',
    this.isDraft = false,
    this.draftUpdatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'theme': theme,
    'createdAt': createdAt.toIso8601String(),
    'usageCount': usageCount,
    'lastUsedAt': lastUsedAt?.toIso8601String(),
    'timeSlotUsageCount': timeSlotUsageCount,
    'optionGroups': optionGroups.map((g) => g.toJson()).toList(),
    'isLogicConditionEnabled': isLogicConditionEnabled,
    'logicConditionType': logicConditionType,
    'isDraft': isDraft,
    'draftUpdatedAt': draftUpdatedAt?.toIso8601String(),
  };

  factory Decision.fromJson(Map<String, dynamic> json) => Decision(
    id: json['id'] as String,
    theme: json['theme'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    usageCount: json['usageCount'] as int? ?? 0,
    lastUsedAt: json['lastUsedAt'] != null
        ? DateTime.parse(json['lastUsedAt'] as String)
        : null,
    timeSlotUsageCount: json['timeSlotUsageCount'] as int? ?? 0,
    optionGroups:
        (json['optionGroups'] as List?)
            ?.map((g) => OptionGroup.fromJson(g as Map<String, dynamic>))
            .toList() ??
        [],
    isLogicConditionEnabled: json['isLogicConditionEnabled'] as bool? ?? false,
    logicConditionType: json['logicConditionType'] as String? ?? 'none',
    isDraft: json['isDraft'] as bool? ?? false,
    draftUpdatedAt: json['draftUpdatedAt'] != null
        ? DateTime.parse(json['draftUpdatedAt'] as String)
        : null,
  );
}

class HistoryRecord {
  String id;
  String decisionId;
  String decisionTheme;
  String result;
  String optionGroupName;
  DateTime createdAt;
  String feedback;
  DateTime dateOnly;

  HistoryRecord({
    required this.id,
    required this.decisionId,
    required this.decisionTheme,
    required this.result,
    required this.optionGroupName,
    DateTime? createdAt,
    this.feedback = 'none',
    DateTime? dateOnly,
  }) : createdAt = createdAt ?? DateTime.now(),
       dateOnly =
           dateOnly ??
           DateTime(
             (createdAt ?? DateTime.now()).year,
             (createdAt ?? DateTime.now()).month,
             (createdAt ?? DateTime.now()).day,
           );

  Map<String, dynamic> toJson() => {
    'id': id,
    'decisionId': decisionId,
    'decisionTheme': decisionTheme,
    'result': result,
    'optionGroupName': optionGroupName,
    'createdAt': createdAt.toIso8601String(),
    'feedback': feedback,
    'dateOnly': dateOnly.toIso8601String(),
  };

  factory HistoryRecord.fromJson(Map<String, dynamic> json) => HistoryRecord(
    id: json['id'] as String,
    decisionId: json['decisionId'] as String,
    decisionTheme: json['decisionTheme'] as String,
    result: json['result'] as String,
    optionGroupName: json['optionGroupName'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    feedback: json['feedback'] as String? ?? 'none',
    dateOnly: DateTime.parse(json['dateOnly'] as String),
  );
}

class NotificationSettings {
  bool enabled;
  bool reminderEnabled;
  bool dndEnabled;
  int dndStartHour;
  int dndStartMinute;
  int dndEndHour;
  int dndEndMinute;

  NotificationSettings({
    this.enabled = true,
    this.reminderEnabled = true,
    this.dndEnabled = true,
    this.dndStartHour = 22,
    this.dndStartMinute = 30,
    this.dndEndHour = 7,
    this.dndEndMinute = 30,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'reminderEnabled': reminderEnabled,
    'dndEnabled': dndEnabled,
    'dndStartHour': dndStartHour,
    'dndStartMinute': dndStartMinute,
    'dndEndHour': dndEndHour,
    'dndEndMinute': dndEndMinute,
  };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        enabled: json['enabled'] as bool? ?? true,
        reminderEnabled: json['reminderEnabled'] as bool? ?? true,
        dndEnabled: json['dndEnabled'] as bool? ?? true,
        dndStartHour: json['dndStartHour'] as int? ?? 22,
        dndStartMinute: json['dndStartMinute'] as int? ?? 30,
        dndEndHour: json['dndEndHour'] as int? ?? 7,
        dndEndMinute: json['dndEndMinute'] as int? ?? 30,
      );
}

class TimeSlot {
  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  double frequency;

  TimeSlot({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.frequency = 0,
  });

  Map<String, dynamic> toJson() => {
    'startHour': startHour,
    'startMinute': startMinute,
    'endHour': endHour,
    'endMinute': endMinute,
    'frequency': frequency,
  };

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
    startHour: json['startHour'] as int,
    startMinute: json['startMinute'] as int,
    endHour: json['endHour'] as int,
    endMinute: json['endMinute'] as int,
    frequency: (json['frequency'] as num?)?.toDouble() ?? 0,
  );

  bool contains(DateTime time) {
    final minute = time.hour * 60 + time.minute;
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    if (start <= end) {
      return minute >= start && minute <= end;
    }
    return minute >= start || minute <= end;
  }

  int get midpointMinute {
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    if (start <= end) {
      return (start + end) ~/ 2;
    }
    final total = (24 * 60 - start) + end;
    return (start + total ~/ 2) % (24 * 60);
  }
}

class LocationCluster {
  String optionGroupName;
  double latitude;
  double longitude;
  double radiusMeters;
  String locationLabel;
  int frequency;

  LocationCluster({
    required this.optionGroupName,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.locationLabel = '',
    this.frequency = 0,
  });

  Map<String, dynamic> toJson() => {
    'optionGroupName': optionGroupName,
    'latitude': latitude,
    'longitude': longitude,
    'radiusMeters': radiusMeters,
    'locationLabel': locationLabel,
    'frequency': frequency,
  };

  factory LocationCluster.fromJson(Map<String, dynamic> json) =>
      LocationCluster(
        optionGroupName: json['optionGroupName'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeters: (json['radiusMeters'] as num).toDouble(),
        locationLabel: json['locationLabel'] as String? ?? '',
        frequency: json['frequency'] as int? ?? 0,
      );
}

class DecisionUsagePattern {
  String decisionId;
  int totalExecutions;
  double executionsPerWeek;
  List<TimeSlot> frequentSlots;
  List<LocationCluster> frequentLocations;
  List<int> frequentWeekdays;
  double priority;
  DateTime lastAnalyzedAt;
  DateTime? lastNotifiedAt;
  int todayNotifyCount;
  DateTime? todayNotifyDate;

  DecisionUsagePattern({
    required this.decisionId,
    this.totalExecutions = 0,
    this.executionsPerWeek = 0,
    this.frequentSlots = const [],
    this.frequentLocations = const [],
    this.frequentWeekdays = const [],
    this.priority = 0,
    DateTime? lastAnalyzedAt,
    this.lastNotifiedAt,
    this.todayNotifyCount = 0,
    this.todayNotifyDate,
  }) : lastAnalyzedAt = lastAnalyzedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'decisionId': decisionId,
    'totalExecutions': totalExecutions,
    'executionsPerWeek': executionsPerWeek,
    'frequentSlots': frequentSlots.map((s) => s.toJson()).toList(),
    'frequentLocations': frequentLocations.map((l) => l.toJson()).toList(),
    'frequentWeekdays': frequentWeekdays,
    'priority': priority,
    'lastAnalyzedAt': lastAnalyzedAt.toIso8601String(),
    'lastNotifiedAt': lastNotifiedAt?.toIso8601String(),
    'todayNotifyCount': todayNotifyCount,
    'todayNotifyDate': todayNotifyDate?.toIso8601String(),
  };

  factory DecisionUsagePattern.fromJson(Map<String, dynamic> json) =>
      DecisionUsagePattern(
        decisionId: json['decisionId'] as String,
        totalExecutions: json['totalExecutions'] as int? ?? 0,
        executionsPerWeek:
            (json['executionsPerWeek'] as num?)?.toDouble() ?? 0,
        frequentSlots: (json['frequentSlots'] as List?)
            ?.map((s) => TimeSlot.fromJson(s as Map<String, dynamic>))
            .toList() ?? [],
        frequentLocations: (json['frequentLocations'] as List?)
            ?.map((l) => LocationCluster.fromJson(l as Map<String, dynamic>))
            .toList() ?? [],
        frequentWeekdays: (json['frequentWeekdays'] as List?)
            ?.map((w) => w as int)
            .toList() ?? [],
        priority: (json['priority'] as num?)?.toDouble() ?? 0,
        lastAnalyzedAt: json['lastAnalyzedAt'] != null
            ? DateTime.parse(json['lastAnalyzedAt'] as String)
            : DateTime.now(),
        lastNotifiedAt: json['lastNotifiedAt'] != null
            ? DateTime.tryParse(json['lastNotifiedAt'] as String)
            : null,
        todayNotifyCount: json['todayNotifyCount'] as int? ?? 0,
        todayNotifyDate: json['todayNotifyDate'] != null
            ? DateTime.tryParse(json['todayNotifyDate'] as String)
            : null,
      );
}
