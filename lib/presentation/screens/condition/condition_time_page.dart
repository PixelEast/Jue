import 'package:flutter/material.dart';

class ConditionTimePage extends StatefulWidget {
  final List<String> optionGroupNames;
  final VoidCallback? onSwitchToLocation;

  const ConditionTimePage({
    super.key,
    required this.optionGroupNames,
    this.onSwitchToLocation,
  });

  @override
  State<ConditionTimePage> createState() => _ConditionTimePageState();
}

class _ConditionTimePageState extends State<ConditionTimePage> {
  late List<TimeRangeData> _timeRanges;

  @override
  void initState() {
    super.initState();
    _timeRanges = widget.optionGroupNames.map((name) {
      return TimeRangeData(
        name: name,
        startHour: 0,
        endHour: 24 ~/ widget.optionGroupNames.length,
      );
    }).toList();
    _redistributeHours();
  }

  void _redistributeHours() {
    final hoursPerGroup = 24 ~/ widget.optionGroupNames.length;
    int currentHour = 0;
    for (int i = 0; i < _timeRanges.length; i++) {
      _timeRanges[i].startHour = currentHour;
      if (i == _timeRanges.length - 1) {
        _timeRanges[i].endHour = 24;
      } else {
        currentHour += hoursPerGroup;
        _timeRanges[i].endHour = currentHour;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '设置逻辑条件',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '根据时间或位置自动切换选项组',
                  style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
                ),
                const SizedBox(height: 20),

                // Mode switcher
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              '时间范围',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onSwitchToLocation ?? () {},
                          child: const Center(
                            child: Text(
                              '位置范围',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8E8E93),
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
          ),
          const SizedBox(height: 24),

          // Time line
          Expanded(child: _buildTimeLine()),

          // Apply button
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '应用逻辑条件',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLine() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _timeRanges.length,
      itemBuilder: (context, index) {
        final range = _timeRanges[index];
        final colors = [
          const Color(0xFF002FA7),
          const Color(0xFF6FA8FF),
          const Color(0xFFB8D4FF),
          const Color(0xFFFF6B6B),
          const Color(0xFFFFB86B),
          const Color(0xFF6BFFB8),
        ];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: colors[index % colors.length].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors[index % colors.length],
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.drag_handle,
                        color: Color(0xFF8E8E93),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        range.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${range.startHour.toString().padLeft(2, '0')}:00 - ${range.endHour.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: range.startHour.toDouble(),
                          min: 0,
                          max: 23,
                          divisions: 23,
                          onChanged: (value) {
                            setState(() {
                              range.startHour = value.toInt();
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: range.endHour.toDouble(),
                          min: 1,
                          max: 24,
                          divisions: 23,
                          onChanged: (value) {
                            setState(() {
                              range.endHour = value.toInt();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class TimeRangeData {
  String name;
  int startHour;
  int endHour;

  TimeRangeData({
    required this.name,
    required this.startHour,
    required this.endHour,
  });
}
