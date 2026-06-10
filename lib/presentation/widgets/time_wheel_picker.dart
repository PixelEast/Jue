import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors_helper.dart';

class TimeWheelPicker extends StatefulWidget {
  final int initialHour;
  final int initialMinute;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;

  const TimeWheelPicker({
    super.key,
    required this.initialHour,
    required this.initialMinute,
    required this.onHourChanged,
    required this.onMinuteChanged,
  });

  @override
  State<TimeWheelPicker> createState() => _TimeWheelPickerState();
}

class _TimeWheelPickerState extends State<TimeWheelPicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialHour.clamp(0, 23);
    _selectedMinute = widget.initialMinute.clamp(0, 59);
    _hourController = FixedExtentScrollController(
      initialItem: _selectedHour,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: _buildWheel(
              controller: _hourController,
              itemCount: 24,
              itemBuilder: (index) => '${index.toString().padLeft(2, '0')}时',
              onSelectedItemChanged: (index) {
                setState(() => _selectedHour = index);
                widget.onHourChanged(index);
                HapticFeedback.selectionClick();
                SystemSound.play(SystemSoundType.click);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildWheel(
              controller: _minuteController,
              itemCount: 60,
              itemBuilder: (index) =>
                  '${index.toString().padLeft(2, '0')}分',
              onSelectedItemChanged: (index) {
                setState(() => _selectedMinute = index);
                widget.onMinuteChanged(index);
                HapticFeedback.selectionClick();
                SystemSound.play(SystemSoundType.click);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) itemBuilder,
    required ValueChanged<int> onSelectedItemChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 44,
      diameterRatio: 1.5,
      perspective: 0.003,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final isSelected = (controller == _hourController)
              ? index == _selectedHour
              : index == _selectedMinute;

          return Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                fontSize: isSelected ? 22 : 18,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? AppColorsHelper.primaryText(context)
                    : AppColorsHelper.tertiaryText(context),
              ),
              child: Text(itemBuilder(index)),
            ),
          );
        },
      ),
    );
  }
}

class TimeWheelPickerDialog extends StatefulWidget {
  final int initialHour;
  final int initialMinute;
  final String title;

  const TimeWheelPickerDialog({
    super.key,
    required this.initialHour,
    required this.initialMinute,
    this.title = '选择时间',
  });

  static Future<TimeOfDay?> show({
    required BuildContext context,
    required int initialHour,
    required int initialMinute,
    String title = '选择时间',
  }) {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TimeWheelPickerDialog(
        initialHour: initialHour,
        initialMinute: initialMinute,
        title: title,
      ),
    );
  }

  @override
  State<TimeWheelPickerDialog> createState() => _TimeWheelPickerDialogState();
}

class _TimeWheelPickerDialogState extends State<TimeWheelPickerDialog> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialHour;
    _minute = widget.initialMinute;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final isDark = AppColorsHelper.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    '取消',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColorsHelper.tertiaryText(context),
                    ),
                  ),
                ),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColorsHelper.primaryText(context),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(
                    context,
                    TimeOfDay(hour: _hour, minute: _minute),
                  ),
                  child: Text(
                    '确定',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColorsHelper.primaryText(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TimeWheelPicker(
              initialHour: widget.initialHour,
              initialMinute: widget.initialMinute,
              onHourChanged: (hour) => _hour = hour,
              onMinuteChanged: (minute) => _minute = minute,
            ),
          ),
          SizedBox(height: 24 + bottomPadding),
        ],
      ),
    );
  }
}
