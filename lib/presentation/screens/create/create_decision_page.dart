import 'package:flutter/material.dart';
import 'dart:math';
import '../../../data/models/app_models.dart';
import '../../../data/repositories/decision_repository.dart';
import '../../../core/utils/app_events.dart';
import '../condition/condition_page.dart';

class CreateDecisionPage extends StatefulWidget {
  final Decision? initialDecision;
  final bool isEditing;

  const CreateDecisionPage({
    super.key,
    this.initialDecision,
    this.isEditing = false,
  });

  @override
  State<CreateDecisionPage> createState() => _CreateDecisionPageState();
}

class _CreateDecisionPageState extends State<CreateDecisionPage> {
  final TextEditingController _themeController = TextEditingController();
  final List<OptionGroupData> _optionGroups = [];
  final List<bool> _groupDeleting = [];
  bool _showLogicCondition = false;
  String _logicConditionType = 'time';
  final DecisionRepository _decisionRepo = DecisionRepository();
  final ScrollController _scrollController = ScrollController();
  final Map<OptionGroupData, GlobalKey> _groupKeys = {};
  final Map<OptionData, bool> _optionVisible = {};
  final Map<OptionGroupData, TextEditingController> _groupNameControllers = {};
  final Map<OptionGroupData, FocusNode> _groupNameFocusNodes = {};
  final Map<OptionGroupData, ValueNotifier<bool>> _groupNameFocused = {};
  final Map<OptionData, TextEditingController> _optionNameControllers = {};
  final Map<OptionData, FocusNode> _optionNameFocusNodes = {};
  final Map<OptionData, ValueNotifier<bool>> _optionNameFocused = {};
  bool _renderHeavySections = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDecision != null) {
      _loadFromDecision(widget.initialDecision!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _renderHeavySections = true;
        });
      });
    } else {
      _optionGroups.add(
        OptionGroupData(
          name: '选项组 1',
          options: [OptionData(name: '选项 1')],
        ),
      );
      _groupDeleting.add(false);
      _groupKeys[_optionGroups.first] = GlobalKey();
      _optionVisible[_optionGroups.first.options.first] = true;
      _renderHeavySections = true;
      _checkDraft();
    }
  }

  TextEditingController _getGroupNameController(OptionGroupData group) {
    return _groupNameControllers.putIfAbsent(
      group,
      () => TextEditingController(text: group.name),
    );
  }

  FocusNode _getGroupNameFocusNode(OptionGroupData group) {
    return _groupNameFocusNodes.putIfAbsent(group, () {
      final node = FocusNode();
      node.addListener(() {
        _getGroupFocusedNotifier(group).value = node.hasFocus;
        if (node.hasFocus) {
          final controller = _getGroupNameController(group);
          controller.text = group.name;
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        }
      });
      return node;
    });
  }

  ValueNotifier<bool> _getGroupFocusedNotifier(OptionGroupData group) {
    return _groupNameFocused.putIfAbsent(
      group,
      () => ValueNotifier<bool>(false),
    );
  }

  TextEditingController _getOptionNameController(OptionData option) {
    return _optionNameControllers.putIfAbsent(
      option,
      () => TextEditingController(text: option.name),
    );
  }

  FocusNode _getOptionNameFocusNode(OptionData option) {
    return _optionNameFocusNodes.putIfAbsent(option, () {
      final node = FocusNode();
      node.addListener(() {
        _getOptionFocusedNotifier(option).value = node.hasFocus;
        if (node.hasFocus) {
          final controller = _getOptionNameController(option);
          controller.text = option.name;
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        }
      });
      return node;
    });
  }

  ValueNotifier<bool> _getOptionFocusedNotifier(OptionData option) {
    return _optionNameFocused.putIfAbsent(
      option,
      () => ValueNotifier<bool>(false),
    );
  }

  void _disposeGroupResources(OptionGroupData group) {
    _groupNameControllers.remove(group)?.dispose();
    _groupNameFocusNodes.remove(group)?.dispose();
    _groupNameFocused.remove(group)?.dispose();
    for (final option in group.options) {
      _disposeOptionResources(option);
    }
  }

  void _disposeOptionResources(OptionData option) {
    _optionNameControllers.remove(option)?.dispose();
    _optionNameFocusNodes.remove(option)?.dispose();
    _optionNameFocused.remove(option)?.dispose();
  }

  void _loadFromDecision(Decision decision) {
    _themeController.text = decision.theme;
    _optionGroups.clear();
    _groupDeleting.clear();
    _groupKeys.clear();
    _optionVisible.clear();

    for (final group in decision.optionGroups) {
      final restoredGroup = OptionGroupData(
        name: group.name,
        options: group.options
            .map(
              (o) => OptionData(
                name: o.name,
                weight: o.baseWeight,
                currentWeight: o.currentWeight,
              ),
            )
            .toList(),
        dynamicWeightEnabled: group.dynamicWeightEnabled,
        weightMode: group.dynamicWeightMode == 'nextRemove'
            ? WeightMode.nextRemove
            : WeightMode.lowerWeight,
        conditionSummary: group.conditionSummary,
        startHour: group.startHour,
        endHour: group.endHour,
        latitude: group.latitude,
        longitude: group.longitude,
        radiusMeters: group.radiusMeters,
        isDefaultGroup: group.isDefaultGroup,
        locationLabel: group.locationLabel,
      );
      _optionGroups.add(restoredGroup);
      _groupDeleting.add(false);
      _groupKeys[restoredGroup] = GlobalKey();
      _getGroupNameController(restoredGroup);
      _getGroupNameFocusNode(restoredGroup);
      _getGroupFocusedNotifier(restoredGroup);
      for (final option in restoredGroup.options) {
        _optionVisible[option] = true;
        _getOptionNameController(option);
        _getOptionNameFocusNode(option);
        _getOptionFocusedNotifier(option);
      }
    }

    _logicConditionType = decision.logicConditionType == 'none'
        ? 'time'
        : decision.logicConditionType;
    _showLogicCondition =
        decision.isLogicConditionEnabled || _optionGroups.length >= 2;
  }

  Future<void> _checkDraft() async {
    if (widget.isEditing) return;
    final draft = await _decisionRepo.getDraft();
    if (draft != null && mounted) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('恢复未保存内容'),
          content: const Text('检测到上次未保存的决定内容，是否恢复？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('不恢复'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('恢复'),
            ),
          ],
        ),
      );
      if (result == true) {
        _themeController.text = draft.theme;
        _optionGroups.clear();
        _groupDeleting.clear();
        _groupKeys.clear();
        _optionVisible.clear();
        for (var group in draft.optionGroups) {
          final restoredGroup = OptionGroupData(
            name: group.name,
            options: group.options
                .map(
                  (o) => OptionData(
                    name: o.name,
                    weight: o.baseWeight,
                    currentWeight: o.currentWeight,
                  ),
                )
                .toList(),
            dynamicWeightEnabled: group.dynamicWeightEnabled,
            weightMode: group.dynamicWeightMode == 'nextRemove'
                ? WeightMode.nextRemove
                : WeightMode.lowerWeight,
            conditionSummary: group.conditionSummary,
            startHour: group.startHour,
            endHour: group.endHour,
            latitude: group.latitude,
            longitude: group.longitude,
            radiusMeters: group.radiusMeters,
            isDefaultGroup: group.isDefaultGroup,
            locationLabel: group.locationLabel,
          );
          _optionGroups.add(restoredGroup);
          _groupDeleting.add(false);
          _groupKeys[restoredGroup] = GlobalKey();
          _getGroupNameController(restoredGroup);
          _getGroupNameFocusNode(restoredGroup);
          _getGroupFocusedNotifier(restoredGroup);
          for (final option in restoredGroup.options) {
            _optionVisible[option] = true;
            _getOptionNameController(option);
            _getOptionNameFocusNode(option);
            _getOptionFocusedNotifier(option);
          }
        }
        _logicConditionType = draft.logicConditionType == 'none'
            ? 'time'
            : draft.logicConditionType;
        if (_optionGroups.length >= 2) _showLogicCondition = true;
        setState(() {});
      } else {
        await _decisionRepo.clearDraft();
      }
    }
  }

  Future<void> _saveDraft() async {
    if (widget.isEditing) return;
    if (_themeController.text.trim().isEmpty &&
        _optionGroups.length <= 1 &&
        _optionGroups.first.options.length <= 1) {
      return;
    }
    final decision = Decision(
      id: 'draft',
      theme: _themeController.text.trim(),
      isLogicConditionEnabled: _showLogicCondition,
      logicConditionType: _logicConditionType,
      isDraft: true,
      draftUpdatedAt: DateTime.now(),
      optionGroups: _optionGroups
          .map(
            (g) => OptionGroup(
              id: Random().nextInt(1000000).toString(),
              name: g.name,
              options: g.options
                  .map(
                    (o) => Option(
                      id: Random().nextInt(1000000).toString(),
                      name: o.name,
                      baseWeight: o.weight,
                      currentWeight: o.currentWeight,
                    ),
                  )
                  .toList(),
              dynamicWeightEnabled: g.dynamicWeightEnabled,
              dynamicWeightMode: g.weightMode.name,
              conditionSummary: g.conditionSummary,
              startHour: g.startHour,
              endHour: g.endHour,
              latitude: g.latitude,
              longitude: g.longitude,
              radiusMeters: g.radiusMeters,
              isDefaultGroup: g.isDefaultGroup,
              locationLabel: g.locationLabel,
            ),
          )
          .toList(),
    );
    await _decisionRepo.saveDecision(decision);
  }

  @override
  void dispose() {
    for (final controller in _groupNameControllers.values) {
      controller.dispose();
    }
    for (final node in _groupNameFocusNodes.values) {
      node.dispose();
    }
    for (final notifier in _groupNameFocused.values) {
      notifier.dispose();
    }
    for (final controller in _optionNameControllers.values) {
      controller.dispose();
    }
    for (final node in _optionNameFocusNodes.values) {
      node.dispose();
    }
    for (final notifier in _optionNameFocused.values) {
      notifier.dispose();
    }
    _themeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addGroupAndScroll() {
    if (_optionGroups.length < 6) {
      final newIndex = _optionGroups.length;
      if (_optionGroups.length + 1 >= 2 && !_showLogicCondition) {
        _showLogicCondition = true;
        if (_logicConditionType == 'time') {
          _redistributeTimeConditions();
        }
      }
      setState(() {
        final shouldInheritLocation =
            _showLogicCondition && _logicConditionType == 'location';
        OptionGroupData? firstLocatedGroup;
        late final OptionGroupData newGroup;
        for (final group in _optionGroups) {
          if (group.latitude != null && group.longitude != null) {
            firstLocatedGroup = group;
            break;
          }
        }
        newGroup = OptionGroupData(
          name: _nextUniqueGroupName(),
          options: [OptionData(name: '选项 1')],
          conditionSummary: _logicConditionType == 'time'
              ? ''
              : (firstLocatedGroup?.conditionSummary.isNotEmpty == true
                    ? firstLocatedGroup!.conditionSummary
                    : '位置范围: 当前位置'),
          latitude: shouldInheritLocation ? firstLocatedGroup?.latitude : null,
          longitude: shouldInheritLocation
              ? firstLocatedGroup?.longitude
              : null,
          radiusMeters: shouldInheritLocation
              ? (firstLocatedGroup?.radiusMeters ?? 200)
              : null,
          isDefaultGroup: false,
        );
        _optionGroups.add(newGroup);
        _groupDeleting.add(false);
        _groupKeys[newGroup] = GlobalKey();
        _getGroupNameController(newGroup);
        _getGroupNameFocusNode(newGroup);
        _getGroupFocusedNotifier(newGroup);
        for (final option in newGroup.options) {
          _getOptionNameController(option);
          _getOptionNameFocusNode(option);
          _getOptionFocusedNotifier(option);
        }
      });
      if (_showLogicCondition && _logicConditionType == 'time') {
        _redistributeTimeConditions();
      }
      _saveDraft();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _groupKeys[_optionGroups[newIndex]];
        if (key != null && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            alignment: 0.1,
          );
        }
      });
    }
  }

  void _redistributeTimeConditions() {
    if (_optionGroups.isEmpty) return;
    final count = _optionGroups.length;
    final hoursPerGroup = 24 ~/ count;
    final remainder = 24 % count;
    int currentHour = 0;
    for (int i = 0; i < count; i++) {
      final startHour = currentHour;
      currentHour += hoursPerGroup;
      if (i < remainder) currentHour += 1;
      final endHour = i == count - 1 ? 24 : currentHour;
      _optionGroups[i].conditionSummary =
          '时间范围 ${startHour.toString().padLeft(2, '0')}:00 - ${endHour.toString().padLeft(2, '0')}:00';
    }
  }

  void _removeGroupAnimated(int index) {
    if (_optionGroups.length > 1) {
      setState(() => _groupDeleting[index] = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          final removedGroup = _optionGroups.removeAt(index);
          _groupDeleting.removeAt(index);
          _groupKeys.remove(removedGroup);
          _disposeGroupResources(removedGroup);
          if (_optionGroups.length < 2) {
            _showLogicCondition = false;
          } else if (_logicConditionType == 'time') {
            _redistributeTimeConditions();
          }
        });
        _saveDraft();
      });
    }
  }

  bool _hasDuplicateName(String name, int excludeIndex) {
    for (int i = 0; i < _optionGroups.length; i++) {
      if (i != excludeIndex && _optionGroups[i].name == name) return true;
    }
    return false;
  }

  String _nextUniqueGroupName() {
    int index = 1;
    while (true) {
      final candidate = '选项组 $index';
      final exists = _optionGroups.any((g) => g.name == candidate);
      if (!exists) return candidate;
      index += 1;
    }
  }

  String _nextUniqueOptionName(int groupIndex) {
    int index = 1;
    while (true) {
      final candidate = '选项 $index';
      final exists = _optionGroups[groupIndex].options.any(
        (o) => o.name == candidate,
      );
      if (!exists) return candidate;
      index += 1;
    }
  }

  void _addOption(int groupIndex) {
    late final OptionData newOption;
    setState(() {
      newOption = OptionData(name: _nextUniqueOptionName(groupIndex));
      _optionGroups[groupIndex].options.add(newOption);
      _optionVisible[newOption] = false;
      _getOptionNameController(newOption);
      _getOptionNameFocusNode(newOption);
      _getOptionFocusedNotifier(newOption);
    });
    _saveDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _optionVisible[newOption] = true;
      });
    });
  }

  void _removeOption(int groupIndex, int optionIndex) {
    if (_optionGroups[groupIndex].options.length > 1) {
      final option = _optionGroups[groupIndex].options[optionIndex];
      setState(() {
        _optionVisible[option] = false;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _optionGroups[groupIndex].options.remove(option);
          _optionVisible.remove(option);
          _disposeOptionResources(option);
        });
        _saveDraft();
      });
    }
  }

  void _reorderOption(int groupIndex, int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _optionGroups[groupIndex].options.removeAt(oldIndex);
      _optionGroups[groupIndex].options.insert(newIndex, item);
    });
    _saveDraft();
  }

  void _saveDecision() async {
    if (_themeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入决定主题')));
      return;
    }
    for (var group in _optionGroups) {
      if (group.options.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${group.name} 至少需要一个选项')));
        return;
      }
    }
    final decision = Decision(
      id:
          widget.initialDecision?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      theme: _themeController.text.trim(),
      createdAt: widget.initialDecision?.createdAt,
      usageCount: widget.initialDecision?.usageCount ?? 0,
      lastUsedAt: widget.initialDecision?.lastUsedAt,
      timeSlotUsageCount: widget.initialDecision?.timeSlotUsageCount ?? 0,
      isLogicConditionEnabled: _showLogicCondition,
      logicConditionType: _logicConditionType,
      optionGroups: _optionGroups
          .map(
            (g) => OptionGroup(
              id: Random().nextInt(1000000).toString(),
              name: g.name,
              options: g.options
                  .map(
                    (o) => Option(
                      id: Random().nextInt(1000000).toString(),
                      name: o.name,
                      baseWeight: o.weight,
                      currentWeight: o.currentWeight,
                    ),
                  )
                  .toList(),
              dynamicWeightEnabled: g.dynamicWeightEnabled,
              dynamicWeightMode: g.weightMode.name,
              conditionSummary: g.conditionSummary,
              startHour: g.startHour,
              endHour: g.endHour,
              latitude: g.latitude,
              longitude: g.longitude,
              radiusMeters: g.radiusMeters,
              isDefaultGroup: g.isDefaultGroup,
              locationLabel: g.locationLabel,
            ),
          )
          .toList(),
    );
    await _decisionRepo.saveDecision(decision);
    AppEvents.notifyDecisionsChanged();
    await _decisionRepo.clearDraft();
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _navigateToCondition() async {
    final groupNames = _optionGroups.map((g) => g.name).toList();
    final existingConditions = <String, String>{};
    final existingGroupData = <String, Map<String, dynamic>>{};
    for (var group in _optionGroups) {
      if (group.conditionSummary.isNotEmpty) {
        existingConditions[group.name] = group.conditionSummary;
      }
      existingGroupData[group.name] = {
        'startHour': group.startHour,
        'endHour': group.endHour,
        'latitude': group.latitude,
        'longitude': group.longitude,
        'radiusMeters': group.radiusMeters,
        'isDefaultGroup': group.isDefaultGroup,
        'locationLabel': group.locationLabel,
      };
    }
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ConditionPage(
          optionGroupNames: groupNames,
          existingConditions: existingConditions,
          existingGroupData: existingGroupData,
          initialMode: _logicConditionType,
        ),
      ),
    );
    if (result != null && mounted) {
      final summaries =
          (result['summaries'] as Map?)?.cast<String, String>() ?? {};
      final groupData =
          (result['groupData'] as Map?)?.cast<String, Map<String, dynamic>>() ??
          {};
      final selectedMode =
          (result['selectedMode'] as String?) ?? _logicConditionType;
      setState(() {
        _logicConditionType = selectedMode;
        for (var entry in summaries.entries) {
          final groupIndex = _optionGroups.indexWhere(
            (g) => g.name == entry.key,
          );
          if (groupIndex != -1) {
            _optionGroups[groupIndex].conditionSummary = entry.value;
            final data = groupData[entry.key];
            if (data != null) {
              _optionGroups[groupIndex].startHour = data['startHour'] as int?;
              _optionGroups[groupIndex].endHour = data['endHour'] as int?;
              _optionGroups[groupIndex].latitude = (data['latitude'] as num?)
                  ?.toDouble();
              _optionGroups[groupIndex].longitude = (data['longitude'] as num?)
                  ?.toDouble();
              _optionGroups[groupIndex].radiusMeters =
                  (data['radiusMeters'] as num?)?.toDouble();
              _optionGroups[groupIndex].isDefaultGroup =
                  data['isDefaultGroup'] as bool? ?? false;
              _optionGroups[groupIndex].locationLabel =
                  data['locationLabel'] as String? ?? '';
            }
          }
        }

        if (_logicConditionType == 'time') {
          for (final group in _optionGroups) {
            group.latitude = null;
            group.longitude = null;
            group.radiusMeters = null;
            group.isDefaultGroup = false;
          }
        }
      });
      _saveDraft();
    }
  }

  String _buildConditionDisplayText(OptionGroupData group) {
    if (_logicConditionType == 'location') {
      final label = group.locationLabel.trim().isNotEmpty
          ? group.locationLabel.trim()
          : '当前位置';
      final radius = (group.radiusMeters ?? 200).round();
      return '位置 $label 半径$radius米内';
    }

    if (group.startHour != null && group.endHour != null) {
      return '时间 ${group.startHour!.toString().padLeft(2, '0')}:00 - ${group.endHour!.toString().padLeft(2, '0')}:00';
    }

    final summary = group.conditionSummary.trim();
    if (summary.startsWith('时间范围 ')) {
      return summary.replaceFirst('时间范围 ', '时间 ');
    }
    return summary.isNotEmpty ? summary : '时间 00:00 - 12:00';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(24, 115, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '即刻判决！',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF5E5E5E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isEditing ? '编辑"决定"' : '创建新"决定"',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
                if (!widget.isEditing) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '创建一个你需要我们帮你决定的主题，并添加你的选项等。',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF5E5E5E),
                    ),
                  ),
                ],
                const SizedBox(height: 38),
                const Text(
                  '此"决定"的主题名称',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF474747),
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _themeController,
                  decoration: InputDecoration(
                    hintText: '例如，接下来该吃什么',
                    hintStyle: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDADADA),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFDADADA),
                        width: 2,
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF002FA7),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 40),
                if (_showLogicCondition) ...[
                  GestureDetector(
                    onTap: _navigateToCondition,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              '逻辑条件',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFFC6C6C6),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '选项组',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B1B1B),
                      ),
                    ),
                    if (_optionGroups.length < 6)
                      GestureDetector(
                        onTap: _addGroupAndScroll,
                        child: Container(
                          width: 140,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '新建选项组',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_renderHeavySections)
                  ..._optionGroups.asMap().entries.map(
                    (entry) => KeyedSubtree(
                      key: _groupKeys[entry.value] ?? GlobalKey(),
                      child: _buildOptionGroupCard(entry.key, entry.value),
                    ),
                  )
                else
                  const SizedBox(height: 1),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveDecision,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                  ),
                  child: const Text(
                    '保存此决定',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF1B1B1B),
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionGroupCard(int groupIndex, OptionGroupData group) {
    final nameFocusNode = _getGroupNameFocusNode(group);
    final isFocused = _getGroupFocusedNotifier(group);
    final nameController = _getGroupNameController(group);

    final isDeleting = _groupDeleting[groupIndex];
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: isDeleting ? 0 : 16),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          opacity: isDeleting ? 0 : 1,
          child: isDeleting
              ? const SizedBox.shrink()
              : Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ValueListenableBuilder<bool>(
                                  valueListenable: isFocused,
                                  builder: (context, focused, child) {
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        IntrinsicWidth(
                                          child: TextField(
                                            controller: nameController,
                                            focusNode: nameFocusNode,
                                            onEditingComplete: () {
                                              _finalizeName(
                                                nameController,
                                                groupIndex,
                                                group,
                                              );
                                              nameFocusNode.unfocus();
                                            },
                                            onTapOutside: (_) {
                                              _finalizeName(
                                                nameController,
                                                groupIndex,
                                                group,
                                              );
                                              nameFocusNode.unfocus();
                                            },
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                              border: InputBorder.none,
                                            ),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: focused
                                                  ? const Color(0xFFBCBCBC)
                                                  : const Color(0xFF1B1B1B),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () {
                                            nameFocusNode.requestFocus();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            child: const Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color: Color(0xFF5E5E5E),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                if (_showLogicCondition) ...[
                                  Text(
                                    '此选项组已开启逻辑条件激活',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF5E5E5E),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEEEEE),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE2E2E2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _logicConditionType == 'location'
                                              ? Icons.location_on_outlined
                                              : Icons.access_time,
                                          size: 20,
                                          color: const Color(0xFF2D5BFF),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '选项组激活条件',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF5E5E5E),
                                                ),
                                              ),
                                              Text(
                                                _buildConditionDisplayText(
                                                  group,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF1B1B1B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: const Color(0xFFE2E2E2),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.balance_outlined,
                                      size: 14,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '动态权重',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const Spacer(),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: SizedBox(
                                        width: 40,
                                        height: 24,
                                        child: Switch(
                                          value: group.dynamicWeightEnabled,
                                          onChanged: (value) {
                                            setState(
                                              () => group.dynamicWeightEnabled =
                                                  value,
                                            );
                                            _saveDraft();
                                          },
                                          activeTrackColor: Colors.black,
                                          inactiveTrackColor: const Color(
                                            0xFFC6C6C6,
                                          ),
                                          activeThumbColor: Colors.white,
                                          inactiveThumbColor: Colors.white,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '通过设置此选项动态调控选项概率',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5E5E5E),
                                  ),
                                ),
                                if (group.dynamicWeightEnabled) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 55,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEEEEE),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE2E2E2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(
                                                () => group.weightMode =
                                                    WeightMode.lowerWeight,
                                              );
                                              _saveDraft();
                                            },
                                            child: Container(
                                              height: double.infinity,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color:
                                                    group.weightMode ==
                                                        WeightMode.lowerWeight
                                                    ? Colors.black
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '降低权重',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1,
                                                  color:
                                                      group.weightMode ==
                                                          WeightMode.lowerWeight
                                                      ? Colors.white
                                                      : const Color(0xFF5E5E5E),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(
                                                () => group.weightMode =
                                                    WeightMode.nextRemove,
                                              );
                                              _saveDraft();
                                            },
                                            child: Container(
                                              height: double.infinity,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color:
                                                    group.weightMode ==
                                                        WeightMode.nextRemove
                                                    ? Colors.black
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '下次剔除',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1,
                                                  color:
                                                      group.weightMode ==
                                                          WeightMode.nextRemove
                                                      ? Colors.white
                                                      : const Color(0xFF5E5E5E),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      group.weightMode == WeightMode.lowerWeight
                                          ? '一旦此选项组有结果产生，它在下次出现的可能性就会自动降低。这能帮你有效降低连续出现同一个结果的情况，保证你的每一次决定都能带来不同的体验。'
                                          : '一旦此选项组有结果产生，会在下次选项组产生结果前，将此选项的权重设置为0，以确保每两次决定执行不会出现同一个结果。',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF5E5E5E),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF7F7F6),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: Color(0xFFE7E7E7),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DragBoundary(
                                  child: ReorderableListView.builder(
                                    itemExtent: 72,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    buildDefaultDragHandles: false,
                                    dragBoundaryProvider: (context) {
                                      return DragBoundary.forRectOf(context);
                                    },
                                    proxyDecorator: (child, index, animation) {
                                      return AnimatedBuilder(
                                        animation: animation,
                                        builder: (context, _) {
                                          final curved = Curves.easeInOutCubic
                                              .transform(animation.value);
                                          return Material(
                                            color: Colors.transparent,
                                            shadowColor: Colors.black
                                                .withValues(
                                                  alpha: 0.08 + (0.08 * curved),
                                                ),
                                            elevation: 2 + (4 * curved),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Transform.scale(
                                              scale: 1 + (0.01 * curved),
                                              child: child,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    itemCount: group.options.length,
                                    onReorder: (oldIndex, newIndex) =>
                                        _reorderOption(
                                          groupIndex,
                                          oldIndex,
                                          newIndex,
                                        ),
                                    itemBuilder: (context, optionIndex) {
                                      final option = group.options[optionIndex];
                                      return Padding(
                                        key: ValueKey(
                                          'group_${groupIndex}_option_${optionIndex}_${option.name}',
                                        ),
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: _buildOptionItem(
                                          groupIndex,
                                          optionIndex,
                                          option,
                                          key: ValueKey(
                                            'group_${groupIndex}_option_inner_${optionIndex}_${option.name}',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: 173,
                                    height: 42,
                                    child: TextButton.icon(
                                      onPressed: () => _addOption(groupIndex),
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        '添加新选项',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      iconAlignment: IconAlignment.start,
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 24,
                        right: 24,
                        child: _DeleteButton(
                          enabled: _optionGroups.length > 1,
                          onTap: () => _removeGroupAnimated(groupIndex),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _finalizeName(
    TextEditingController controller,
    int groupIndex,
    OptionGroupData group,
  ) {
    final trimmed = controller.text.trim();
    if (trimmed.isEmpty || _hasDuplicateName(trimmed, groupIndex)) {
      final defaultName = _nextUniqueGroupName();
      controller.text = defaultName;
      group.name = defaultName;
    } else {
      group.name = trimmed;
    }
    _saveDraft();
  }

  Widget _buildOptionItem(
    int groupIndex,
    int optionIndex,
    OptionData option, {
    required Key key,
  }) {
    final optionFocusNode = _getOptionNameFocusNode(option);
    final optionNameController = _getOptionNameController(option);
    final isOptionFocused = _getOptionFocusedNotifier(option);

    final isVisible = _optionVisible[option] ?? true;

    const optionCardHeight = 64.0;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: isVisible ? 8 : 0),
        child: ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: isVisible ? 1 : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
              opacity: isVisible ? 1 : 0,
              child: Container(
                key: key,
                height: optionCardHeight,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF2F2F2), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      child: ReorderableDragStartListener(
                        index: optionIndex,
                        child: const Icon(
                          Icons.drag_indicator,
                          size: 20,
                          color: Color(0xFF5E5E5E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: Transform.translate(
                          offset: const Offset(0, 2),
                          child: SizedBox(
                            width: 210,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                StatefulBuilder(
                                  builder: (context, localSetState) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ValueListenableBuilder<bool>(
                                          valueListenable: isOptionFocused,
                                          builder: (context, focused, child) {
                                            return Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IntrinsicWidth(
                                                        child: TextField(
                                                          controller:
                                                              optionNameController,
                                                          focusNode:
                                                              optionFocusNode,
                                                          onEditingComplete: () {
                                                            final trimmed =
                                                                optionNameController
                                                                    .text
                                                                    .trim();
                                                            option.name =
                                                                trimmed.isEmpty
                                                                ? _nextUniqueOptionName(
                                                                    groupIndex,
                                                                  )
                                                                : trimmed;
                                                            optionFocusNode
                                                                .unfocus();
                                                            _saveDraft();
                                                          },
                                                          onTapOutside: (_) {
                                                            final trimmed =
                                                                optionNameController
                                                                    .text
                                                                    .trim();
                                                            option.name =
                                                                trimmed.isEmpty
                                                                ? _nextUniqueOptionName(
                                                                    groupIndex,
                                                                  )
                                                                : trimmed;
                                                            optionFocusNode
                                                                .unfocus();
                                                            _saveDraft();
                                                          },
                                                          decoration:
                                                              const InputDecoration(
                                                                isDense: true,
                                                                contentPadding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                border:
                                                                    InputBorder
                                                                        .none,
                                                              ),
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: focused
                                                                ? const Color(
                                                                    0xFFBCBCBC,
                                                                  )
                                                                : const Color(
                                                                    0xFF1B1B1B,
                                                                  ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      GestureDetector(
                                                        onTap: () {
                                                          optionFocusNode
                                                              .requestFocus();
                                                        },
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                4,
                                                              ),
                                                          child: const Icon(
                                                            Icons.edit_outlined,
                                                            size: 12.8,
                                                            color: Color(
                                                              0xFF5E5E5E,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  '权重：${(widget.isEditing ? option.currentWeight : option.weight).toStringAsFixed(1)}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF5E5E5E),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 2),
                                        SizedBox(
                                          height: 28,
                                          width: double.infinity,
                                          child: SliderTheme(
                                            data: SliderThemeData(
                                              trackHeight: 2,
                                              trackShape:
                                                  const _FullWidthSliderTrackShape(),
                                              thumbShape:
                                                  const RoundSliderThumbShape(
                                                    enabledThumbRadius: 7,
                                                  ),
                                              overlayShape:
                                                  const RoundSliderOverlayShape(
                                                    overlayRadius: 12,
                                                  ),
                                              activeTrackColor: const Color(
                                                0xFF5E5E5E,
                                              ),
                                              inactiveTrackColor: const Color(
                                                0xFFE2E2E2,
                                              ),
                                              thumbColor: Colors.black,
                                              tickMarkShape: SliderTickMarkShape
                                                  .noTickMark,
                                              activeTickMarkColor:
                                                  Colors.transparent,
                                              inactiveTickMarkColor:
                                                  Colors.transparent,
                                            ),
                                            child: Slider(
                                              allowedInteraction:
                                                  SliderInteraction.tapAndSlide,
                                              padding: EdgeInsets.zero,
                                              value: widget.isEditing
                                                  ? option.currentWeight
                                                  : option.weight,
                                              min: 0.1,
                                              max: 3.0,
                                              onChanged: (value) {
                                                localSetState(() {
                                                  final parsed = double.parse(
                                                    value.toStringAsFixed(1),
                                                  );
                                                  option.weight = parsed;
                                                  option.currentWeight = parsed;
                                                });
                                              },
                                              onChangeEnd: (value) {
                                                final parsed = double.parse(
                                                  value.toStringAsFixed(1),
                                                );
                                                option.weight = parsed;
                                                option.currentWeight = parsed;
                                                _saveDraft();
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 20,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _DeleteButton(
                          enabled: _optionGroups[groupIndex].options.length > 1,
                          sizeScale: 0.8,
                          onTap: () => _removeOption(groupIndex, optionIndex),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatefulWidget {
  final bool enabled;
  final double sizeScale;
  final VoidCallback onTap;
  const _DeleteButton({
    required this.enabled,
    required this.onTap,
    this.sizeScale = 1,
  });
  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.enabled) {
          widget.onTap();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 16 * widget.sizeScale,
        height: 18 * widget.sizeScale,
        child: CustomPaint(
          size: Size(16 * widget.sizeScale, 18 * widget.sizeScale),
          painter: _DeleteIconPainter(
            color: !widget.enabled
                ? const Color(0xFFC6C6C6)
                : (_isPressed
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF5E5E5E)),
          ),
        ),
      ),
    );
  }
}

class _DeleteIconPainter extends CustomPainter {
  final Color color;
  _DeleteIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    // M3 18
    path.moveTo(size.width * 3 / 16, size.height);
    // C2.45 18 1.97917 17.8042 1.5875 17.4125
    path.cubicTo(
      size.width * 2.45 / 16,
      size.height,
      size.width * 1.97917 / 16,
      size.height * 17.8042 / 18,
      size.width * 1.5875 / 16,
      size.height * 17.4125 / 18,
    );
    // C1.19583 17.0208 1 16.55 1 16
    path.cubicTo(
      size.width * 1.19583 / 16,
      size.height * 17.0208 / 18,
      size.width / 16,
      size.height * 16.55 / 18,
      size.width / 16,
      size.height * 16 / 18,
    );
    // V3
    path.lineTo(size.width / 16, size.height * 3 / 18);
    // H0
    path.lineTo(0, size.height * 3 / 18);
    // V1
    path.lineTo(0, size.height / 18);
    // H5
    path.lineTo(size.width * 5 / 16, size.height / 18);
    // V0
    path.lineTo(size.width * 5 / 16, 0);
    // H11
    path.lineTo(size.width * 11 / 16, 0);
    // V1
    path.lineTo(size.width * 11 / 16, size.height / 18);
    // H16
    path.lineTo(size.width, size.height / 18);
    // V3
    path.lineTo(size.width, size.height * 3 / 18);
    // H15
    path.lineTo(size.width * 15 / 16, size.height * 3 / 18);
    // V16
    path.lineTo(size.width * 15 / 16, size.height * 16 / 18);
    // C15 16.55 14.8042 17.0208 14.4125 17.4125
    path.cubicTo(
      size.width,
      size.height * 16.55 / 18,
      size.width * 14.8042 / 16,
      size.height * 17.0208 / 18,
      size.width * 14.4125 / 16,
      size.height * 17.4125 / 18,
    );
    // C14.0208 17.8042 13.55 18 13 18
    path.cubicTo(
      size.width * 14.0208 / 16,
      size.height * 17.8042 / 18,
      size.width * 13.55 / 16,
      size.height,
      size.width * 13 / 16,
      size.height,
    );
    // H3Z
    path.lineTo(size.width * 3 / 16, size.height);
    path.close();

    // M13 3
    path.moveTo(size.width * 13 / 16, size.height * 3 / 18);
    // H3
    path.lineTo(size.width * 3 / 16, size.height * 3 / 18);
    // V16
    path.lineTo(size.width * 3 / 16, size.height * 16 / 18);
    // H13
    path.lineTo(size.width * 13 / 16, size.height * 16 / 18);
    // V3Z
    path.lineTo(size.width * 13 / 16, size.height * 3 / 18);
    path.close();

    // M5 14
    path.moveTo(size.width * 5 / 16, size.height * 14 / 18);
    // H7
    path.lineTo(size.width * 7 / 16, size.height * 14 / 18);
    // V5
    path.lineTo(size.width * 7 / 16, size.height * 5 / 18);
    // H5
    path.lineTo(size.width * 5 / 16, size.height * 5 / 18);
    // V14Z
    path.lineTo(size.width * 5 / 16, size.height * 14 / 18);
    path.close();

    // M9 14
    path.moveTo(size.width * 9 / 16, size.height * 14 / 18);
    // H11
    path.lineTo(size.width * 11 / 16, size.height * 14 / 18);
    // V5
    path.lineTo(size.width * 11 / 16, size.height * 5 / 18);
    // H9
    path.lineTo(size.width * 9 / 16, size.height * 5 / 18);
    // V14Z
    path.lineTo(size.width * 9 / 16, size.height * 14 / 18);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DeleteIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _FullWidthSliderTrackShape extends RoundedRectSliderTrackShape {
  const _FullWidthSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 2;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(
      offset.dx,
      trackTop,
      parentBox.size.width,
      trackHeight,
    );
  }
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

class OptionData {
  String name;
  double weight;
  double currentWeight;
  OptionData({required this.name, this.weight = 1.0, double? currentWeight})
    : currentWeight = currentWeight ?? weight;
}

enum WeightMode { lowerWeight, nextRemove }
