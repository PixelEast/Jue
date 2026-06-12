enum WeightMode { lowerWeight, nextRemove }

class OptionData {
  String name;
  double weight;
  double currentWeight;
  OptionData({required this.name, this.weight = 1.0, double? currentWeight})
    : currentWeight = currentWeight ?? weight;
}

class OptionGroupData {
  String name;
  List<OptionData> options;
  bool dynamicWeightEnabled;
  WeightMode weightMode;
  String conditionSummary;
  int? startHour;
  int? endHour;
  double? latitude;
  double? longitude;
  double? radiusMeters;
  bool isDefaultGroup;
  String locationLabel;

  OptionGroupData({
    required this.name,
    required this.options,
    this.dynamicWeightEnabled = true,
    this.weightMode = WeightMode.lowerWeight,
    this.conditionSummary = '',
    this.startHour,
    this.endHour,
    this.latitude,
    this.longitude,
    this.radiusMeters,
    this.isDefaultGroup = false,
    this.locationLabel = '',
  });
}
