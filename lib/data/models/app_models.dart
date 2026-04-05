class Option {
  String id;
  String name;
  double baseWeight;
  double currentWeight;
  int timesSelected;
  DateTime? lastSelectedAt;
  bool pendingRecovery;

  Option({
    required this.id,
    required this.name,
    this.baseWeight = 1.0,
    this.currentWeight = 1.0,
    this.timesSelected = 0,
    this.lastSelectedAt,
    this.pendingRecovery = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseWeight': baseWeight,
    'currentWeight': currentWeight,
    'timesSelected': timesSelected,
    'lastSelectedAt': lastSelectedAt?.toIso8601String(),
    'pendingRecovery': pendingRecovery,
  };

  factory Option.fromJson(Map<String, dynamic> json) => Option(
    id: json['id'] as String,
    name: json['name'] as String,
    baseWeight: (json['baseWeight'] as num).toDouble(),
    currentWeight: (json['currentWeight'] as num).toDouble(),
    timesSelected: json['timesSelected'] as int,
    lastSelectedAt: json['lastSelectedAt'] != null
        ? DateTime.parse(json['lastSelectedAt'] as String)
        : null,
    pendingRecovery: json['pendingRecovery'] as bool? ?? false,
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
