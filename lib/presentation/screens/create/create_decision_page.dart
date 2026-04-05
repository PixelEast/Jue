import 'package:flutter/material.dart';
import 'dart:math';
import '../../../data/models/app_models.dart';
import '../../../data/repositories/decision_repository.dart';
import '../../../data/local/app_storage.dart';
import '../condition/condition_time_page.dart';
import '../condition/condition_location_page.dart';

class CreateDecisionPage extends StatefulWidget {
  const CreateDecisionPage({super.key});
  @override
  State<CreateDecisionPage> createState() => _CreateDecisionPageState();
}

class _CreateDecisionPageState extends State<CreateDecisionPage> {
  final TextEditingController _themeController = TextEditingController();
  final List<OptionGroupData> _optionGroups = [];
  final List<bool> _groupDeleting = [];
  bool _showLogicCondition = false;
  final DecisionRepository _decisionRepo = DecisionRepository();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _groupKeys = {};

  @override
  void initState() {
    super.initState();
    _optionGroups.add(
      OptionGroupData(
        name: '选项组 1',
        options: [OptionData(name: '选项 1')],
      ),
    );
    _groupDeleting.add(false);
    _checkDraft();
  }

  Future<void> _checkDraft() async {
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
        for (var group in draft.optionGroups) {
          _optionGroups.add(
            OptionGroupData(
              name: group.name,
              options: group.options
                  .map((o) => OptionData(name: o.name, weight: o.baseWeight))
                  .toList(),
              dynamicWeightEnabled: group.dynamicWeightEnabled,
              weightMode: group.dynamicWeightMode == 'nextRemove'
                  ? WeightMode.nextRemove
                  : WeightMode.lowerWeight,
            ),
          );
          _groupDeleting.add(false);
        }
        if (_optionGroups.length >= 2) _showLogicCondition = true;
        setState(() {});
      } else {
        await _decisionRepo.clearDraft();
      }
    }
  }

  Future<void> _saveDraft() async {
    if (_themeController.text.trim().isEmpty &&
        _optionGroups.length <= 1 &&
        _optionGroups.first.options.length <= 1) {
      return;
    }
    final decision = Decision(
      id: 'draft',
      theme: _themeController.text.trim(),
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
                      currentWeight: o.weight,
                    ),
                  )
                  .toList(),
              dynamicWeightEnabled: g.dynamicWeightEnabled,
              dynamicWeightMode: g.weightMode.name,
            ),
          )
          .toList(),
    );
    await _decisionRepo.saveDecision(decision);
  }

  @override
  void dispose() {
    _themeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addGroup() {
    if (_optionGroups.length < 6) {
      final newIndex = _optionGroups.length;
      setState(() {
        _optionGroups.add(
          OptionGroupData(
            name: '选项组 ${_optionGroups.length + 1}',
            options: [OptionData(name: '选项 1')],
          ),
        );
        _groupDeleting.add(false);
        _groupKeys[newIndex] = GlobalKey();
        if (_optionGroups.length >= 2) _showLogicCondition = true;
      });
      _saveDraft();
    }
  }

  void _addGroupAndScroll() {
    if (_optionGroups.length < 6) {
      final newIndex = _optionGroups.length;
      setState(() {
        _optionGroups.add(
          OptionGroupData(
            name: '选项组 ${_optionGroups.length + 1}',
            options: [OptionData(name: '选项 1')],
          ),
        );
        _groupDeleting.add(false);
        _groupKeys[newIndex] = GlobalKey();
        if (_optionGroups.length >= 2) _showLogicCondition = true;
      });
      _saveDraft();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _groupKeys[newIndex];
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

  void _removeGroupAnimated(int index) {
    if (_optionGroups.length > 1) {
      setState(() => _groupDeleting[index] = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _optionGroups.removeAt(index);
          _groupDeleting.removeAt(index);
          if (_optionGroups.length < 2) _showLogicCondition = false;
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

  void _addOption(int groupIndex) {
    setState(() {
      _optionGroups[groupIndex].options.add(
        OptionData(name: '选项 ${_optionGroups[groupIndex].options.length + 1}'),
      );
    });
    _saveDraft();
  }

  void _removeOption(int groupIndex, int optionIndex) {
    if (_optionGroups[groupIndex].options.length > 1) {
      setState(() {
        _optionGroups[groupIndex].options.removeAt(optionIndex);
      });
      _saveDraft();
    }
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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      theme: _themeController.text.trim(),
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
                      currentWeight: o.weight,
                    ),
                  )
                  .toList(),
              dynamicWeightEnabled: g.dynamicWeightEnabled,
              dynamicWeightMode: g.weightMode.name,
            ),
          )
          .toList(),
    );
    await _decisionRepo.saveDecision(decision);
    await _decisionRepo.clearDraft();
    if (mounted) Navigator.pop(context, true);
  }

  void _navigateToCondition() {
    final groupNames = _optionGroups.map((g) => g.name).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConditionTimePage(
          optionGroupNames: groupNames,
          onSwitchToLocation: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ConditionLocationPage(
                  optionGroupNames: groupNames,
                  onSwitchToTime: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConditionTimePage(
                          optionGroupNames: groupNames,
                          onSwitchToLocation: () {},
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
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
                const SizedBox(height: 8),
                const Text(
                  '创建新"决定"',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '创建一个你需要我们帮你决定的主题，并添加你的选项等。',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF5E5E5E),
                  ),
                ),
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
                ..._optionGroups
                    .asMap()
                    .entries
                    .map(
                      (entry) => KeyedSubtree(
                        key: _groupKeys[entry.key] ?? GlobalKey(),
                        child: _buildOptionGroupCard(entry.key, entry.value),
                      ),
                    )
                    ,
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
                  ),
                  child: const Text(
                    '保存决定',
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
    final nameFocusNode = FocusNode();
    final isFocused = ValueNotifier<bool>(false);
    final nameController = TextEditingController(text: group.name);

    nameFocusNode.addListener(() {
      isFocused.value = nameFocusNode.hasFocus;
      if (nameFocusNode.hasFocus) {
        nameController.text = group.name;
        nameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: nameController.text.length,
        );
      }
    });

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      opacity: _groupDeleting[groupIndex] ? 0.0 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
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
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        '动态权重',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5E5E5E),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 40,
                        height: 24,
                        child: Switch(
                          value: group.dynamicWeightEnabled,
                          onChanged: (value) {
                            setState(() => group.dynamicWeightEnabled = value);
                            _saveDraft();
                          },
                          activeTrackColor: Colors.black,
                          inactiveTrackColor: const Color(0xFFC6C6C6),
                          activeThumbColor: Colors.white,
                          inactiveThumbColor: Colors.white,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  if (group.dynamicWeightEnabled) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(
                                  () =>
                                      group.weightMode = WeightMode.lowerWeight,
                                );
                                _saveDraft();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      group.weightMode == WeightMode.lowerWeight
                                      ? Colors.black
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '降低权重',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
                                  () =>
                                      group.weightMode = WeightMode.nextRemove,
                                );
                                _saveDraft();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      group.weightMode == WeightMode.nextRemove
                                      ? Colors.black
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '下次剔除',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
                    const SizedBox(height: 12),
                  ],
                  ...group.options
                      .asMap()
                      .entries
                      .map(
                        (entry) => _buildOptionItem(
                          groupIndex,
                          entry.key,
                          entry.value,
                        ),
                      )
                      ,
                  TextButton.icon(
                    onPressed: () => _addOption(groupIndex),
                    icon: const Icon(
                      Icons.add,
                      size: 18,
                      color: Color(0xFF002FA7),
                    ),
                    label: const Text(
                      '添加选项',
                      style: TextStyle(color: Color(0xFF002FA7)),
                    ),
                  ),
                ],
              ),
            ),
            if (_optionGroups.length > 1)
              Positioned(
                top: 24,
                right: 24,
                child: _DeleteButton(
                  onTap: () => _removeGroupAnimated(groupIndex),
                ),
              ),
          ],
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
      final defaultName = '选项组 ${groupIndex + 1}';
      controller.text = defaultName;
      group.name = defaultName;
    } else {
      group.name = trimmed;
    }
    _saveDraft();
  }

  Widget _buildOptionItem(int groupIndex, int optionIndex, OptionData option) {
    final optionFocusNode = FocusNode();
    final optionNameController = TextEditingController(text: option.name);
    final isOptionFocused = ValueNotifier<bool>(false);

    optionFocusNode.addListener(() {
      isOptionFocused.value = optionFocusNode.hasFocus;
      if (optionFocusNode.hasFocus) {
        optionNameController.text = option.name;
        optionNameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: optionNameController.text.length,
        );
      }
    });

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ValueListenableBuilder<bool>(
              valueListenable: isOptionFocused,
              builder: (context, focused, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IntrinsicWidth(
                      child: TextField(
                        controller: optionNameController,
                        focusNode: optionFocusNode,
                        onEditingComplete: () {
                          final trimmed = optionNameController.text.trim();
                          option.name = trimmed.isEmpty ? '选项' : trimmed;
                          optionFocusNode.unfocus();
                          _saveDraft();
                        },
                        onTapOutside: (_) {
                          final trimmed = optionNameController.text.trim();
                          option.name = trimmed.isEmpty ? '选项' : trimmed;
                          optionFocusNode.unfocus();
                          _saveDraft();
                        },
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: focused
                              ? const Color(0xFFBCBCBC)
                              : const Color(0xFF1B1B1B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    GestureDetector(
                      onTap: () {
                        optionFocusNode.requestFocus();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: Color(0xFF5E5E5E),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Text(
                  option.weight.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5E5E5E),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: const Color(0xFF004EE8),
                      inactiveTrackColor: const Color(0xFFEEEEEE),
                      thumbColor: Colors.black,
                    ),
                    child: Slider(
                      value: option.weight,
                      min: 0.1,
                      max: 3.0,
                      divisions: 29,
                      onChanged: (value) {
                        setState(
                          () => option.weight = double.parse(
                            value.toStringAsFixed(1),
                          ),
                        );
                        _saveDraft();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_optionGroups[groupIndex].options.length > 1)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Color(0xFF5E5E5E)),
              onPressed: () => _removeOption(groupIndex, optionIndex),
            ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatefulWidget {
  final VoidCallback onTap;
  const _DeleteButton({required this.onTap});
  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 16,
        height: 18,
        child: CustomPaint(
          size: const Size(16, 18),
          painter: _DeleteIconPainter(
            color: _isPressed
                ? const Color(0xFFFF6B6B)
                : const Color(0xFF5E5E5E),
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

class OptionGroupData {
  String name;
  List<OptionData> options;
  bool dynamicWeightEnabled;
  WeightMode weightMode;
  OptionGroupData({
    required this.name,
    required this.options,
    this.dynamicWeightEnabled = true,
    this.weightMode = WeightMode.lowerWeight,
  });
}

class OptionData {
  String name;
  double weight;
  OptionData({required this.name, this.weight = 1.0});
}

enum WeightMode { lowerWeight, nextRemove }
