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
  late List<int> _groupOrder;
  int? _draggingBoundaryIndex;

  // Card drag state
  int? _draggingGroupIndex;
  double _dragCardOffsetY = 0;
  double _dragStartGlobalY = 0;
  double _dragOriginalTop = 0;
  int _dragStartOrderIndex = 0;
  bool _hideBoundaries = false;

  final GlobalKey _timelineKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  static const Color _primary = Color(0xFF000000);
  static const Color _surface = Color(0xFFF9F9F9);
  static const Color _secondary = Color(0xFF5E5E5E);
  static const Color _outlineVariant = Color(0xFFC6C6C6);

  final List<Color> _cardColors = [
    Color(0xFF000000),
    Color(0xFF1C1C1E),
    Color(0xFF27272A),
    Color(0xFFE4E4E7),
    Color(0xFFF4F4F5),
    Color(0xFFFAFAFA),
  ];

  @override
  void initState() {
    super.initState();
    _groupOrder = List.generate(widget.optionGroupNames.length, (i) => i);
    _initializeTimeRanges();
  }

  void _initializeTimeRanges() {
    final count = widget.optionGroupNames.length;
    _timeRanges = [];
    int currentHour = 0;
    final hoursPerGroup = 24 ~/ count;
    final remainder = 24 % count;

    for (int i = 0; i < count; i++) {
      final startHour = currentHour;
      currentHour += hoursPerGroup;
      if (i < remainder) currentHour += 1;
      final endHour = i == count - 1 ? 24 : currentHour;
      _timeRanges.add(
        TimeRangeData(
          name: widget.optionGroupNames[i],
          startHour: startHour,
          endHour: endHour,
          colorIndex: i,
        ),
      );
    }
  }

  bool _isDarkCard(int colorIndex) => colorIndex < 3;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: _outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, size: 20, color: _primary),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: _draggingBoundaryIndex != null
                  ? const NeverScrollableScrollPhysics()
                  : null,
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(24, 96, 24, 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    '即刻判决！',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _secondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '设置逻辑条件',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                      letterSpacing: -0.05,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '为你的决定设置逻辑条件，以此在多个选项组存在时，决定每个选项组改在什么情况下启用。',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: _secondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Container(
                      height: 48,
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _primary.withValues(alpha: 0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Center(
                                child: Text(
                                  '时间范围',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onSwitchToLocation ?? () {},
                              child: Container(
                                margin: const EdgeInsets.all(6),
                                child: const Center(
                                  child: Text(
                                    '位置范围',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _secondary,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildTimeline(),
                  const SizedBox(height: 48),
                  _buildFooterButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    const hourIntervalHeight = 60.0;
    const totalHeight = 24 * hourIntervalHeight;
    const timeAxisWidth = 80.0;

    return SizedBox(
      key: _timelineKey,
      height: totalHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: timeAxisWidth,
            height: totalHeight,
            child: _buildTimeAxis(totalHeight),
          ),
          Positioned(
            left: timeAxisWidth,
            top: 0,
            height: totalHeight,
            width: 2,
            child: Container(color: _primary),
          ),
          Positioned(
            left: timeAxisWidth + 2,
            top: 0,
            right: 0,
            height: totalHeight,
            child: Stack(
              children: [
                for (int i = 0; i < _groupOrder.length; i++)
                  _buildCard(i, hourIntervalHeight),
                for (int i = 0; i < _groupOrder.length - 1; i++)
                  _buildBoundary(i, hourIntervalHeight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAxis(double totalHeight) {
    const hourIntervalHeight = 60.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int hour = 0; hour <= 24; hour++)
          SizedBox(
            height: hour == 0 || hour == 24
                ? hourIntervalHeight / 2
                : hourIntervalHeight,
            child: Align(
              alignment: hour == 0
                  ? Alignment.topCenter
                  : (hour == 24 ? Alignment.bottomCenter : Alignment.center),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                  fontSize: hour % 6 == 0 ? 11 : 10,
                  fontWeight: hour % 6 == 0 ? FontWeight.w600 : FontWeight.w500,
                  color: hour % 6 == 0 ? _primary : _secondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCard(int orderIndex, double hourIntervalHeight) {
    final groupIndex = _groupOrder[orderIndex];
    final range = _timeRanges[groupIndex];
    final bgColor = _cardColors[groupIndex % _cardColors.length];
    final isDark = _isDarkCard(groupIndex);
    final cardHeight = (range.endHour - range.startHour) * hourIntervalHeight;
    final baseTopPosition = range.startHour * hourIntervalHeight;
    final isDragging = _draggingGroupIndex == groupIndex;

    return AnimatedPositioned(
      key: ValueKey(groupIndex),
      duration: isDragging ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      top: isDragging ? _dragOriginalTop + _dragCardOffsetY : baseTopPosition,
      left: 0,
      right: 0,
      height: cardHeight,
      child: ClipRect(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: isDragging ? bgColor.withValues(alpha: 0.3) : bgColor,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : _primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: (details) {
                      final currentOrder = _groupOrder.indexOf(groupIndex);
                      setState(() {
                        _draggingGroupIndex = groupIndex;
                        _dragStartGlobalY = details.globalPosition.dy;
                        _dragStartOrderIndex = currentOrder;
                        _dragOriginalTop = baseTopPosition;
                        _dragCardOffsetY = 0;
                      });
                    },
                    onVerticalDragUpdate: (details) {
                      if (_draggingGroupIndex != groupIndex) return;
                      final deltaY =
                          details.globalPosition.dy - _dragStartGlobalY;
                      final avgCardHeight = 1440.0 / _groupOrder.length;
                      final orderShift = (deltaY / avgCardHeight).round();
                      final targetOrder = (_dragStartOrderIndex + orderShift)
                          .clamp(0, _groupOrder.length - 1);
                      final currentOrder = _groupOrder.indexOf(groupIndex);
                      if (targetOrder != currentOrder) {
                        setState(() {
                          final group = _groupOrder.removeAt(currentOrder);
                          _groupOrder.insert(targetOrder, group);
                          final start = targetOrder < currentOrder
                              ? targetOrder
                              : currentOrder;
                          final end = targetOrder > currentOrder
                              ? targetOrder
                              : currentOrder;
                          for (int i = start; i < end; i++) {
                            _swapTimeRanges(i, i + 1);
                          }
                          _hideBoundaries = true;
                          _dragStartOrderIndex = targetOrder;
                          _dragOriginalTop =
                              _timeRanges[groupIndex].startHour *
                              hourIntervalHeight;
                          _dragStartGlobalY = details.globalPosition.dy;
                          _dragCardOffsetY = 0;
                        });
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            setState(() {
                              _hideBoundaries = false;
                            });
                          }
                        });
                      } else {
                        setState(() {
                          _dragCardOffsetY = deltaY;
                        });
                      }
                    },
                    onVerticalDragEnd: (_) {
                      setState(() {
                        _draggingGroupIndex = null;
                        _dragCardOffsetY = 0;
                      });
                    },
                    child: Opacity(
                      opacity: 0.4,
                      child: Icon(
                        Icons.drag_indicator,
                        size: 20,
                        color: isDark ? Colors.white : _primary,
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      range.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : _primary,
                        letterSpacing: 0.2,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${range.startHour.toString().padLeft(2, '0')}:00 — ${range.endHour.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : _secondary,
                        letterSpacing: 1.5,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _swapTimeRanges(int orderIndexA, int orderIndexB) {
    final groupA = _groupOrder[orderIndexA];
    final groupB = _groupOrder[orderIndexB];
    final tempStart = _timeRanges[groupA].startHour;
    final tempEnd = _timeRanges[groupA].endHour;
    _timeRanges[groupA].startHour = _timeRanges[groupB].startHour;
    _timeRanges[groupA].endHour = _timeRanges[groupB].endHour;
    _timeRanges[groupB].startHour = tempStart;
    _timeRanges[groupB].endHour = tempEnd;
  }

  Widget _buildBoundary(int boundaryIndex, double hourIntervalHeight) {
    final prevGroupIndex = _groupOrder[boundaryIndex];
    final range = _timeRanges[prevGroupIndex];
    final isDark = _isDarkCard(prevGroupIndex);
    final boundaryPosition = range.endHour * hourIntervalHeight;

    return Positioned(
      top: boundaryPosition - 10,
      left: 0,
      right: 0,
      height: 20,
      child: AnimatedOpacity(
        opacity: _hideBoundaries ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (details) {
            setState(() {
              _draggingBoundaryIndex = boundaryIndex;
            });
          },
          onVerticalDragUpdate: (details) {
            if (_draggingBoundaryIndex == boundaryIndex) {
              final renderBox =
                  _timelineKey.currentContext?.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final localPos = renderBox.globalToLocal(
                  details.globalPosition,
                );
                final targetHour = (localPos.dy / hourIntervalHeight)
                    .round()
                    .clamp(0, 24);
                final prevCard = _timeRanges[_groupOrder[boundaryIndex]];
                final nextCard = _timeRanges[_groupOrder[boundaryIndex + 1]];
                final minHour = prevCard.startHour + 1;
                final maxHour = nextCard.endHour - 1;
                final clampedHour = targetHour.clamp(minHour, maxHour);
                if (clampedHour != range.endHour) {
                  setState(() {
                    prevCard.endHour = clampedHour;
                    nextCard.startHour = clampedHour;
                  });
                }
              }
            }
          },
          onVerticalDragEnd: (_) =>
              setState(() => _draggingBoundaryIndex = null),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: _draggingBoundaryIndex == boundaryIndex ? 8 : 5,
              width: 72,
              decoration: BoxDecoration(
                color: _draggingBoundaryIndex == boundaryIndex
                    ? (isDark ? Colors.white : _primary)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.8)
                          : _primary.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _applyConditions,
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Text(
              '应用逻辑条件',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _applyConditions() {
    final result = <String, String>{};
    for (var range in _timeRanges) {
      final summary =
          '时间范围 ${range.startHour.toString().padLeft(2, '0')}:00 - ${range.endHour.toString().padLeft(2, '0')}:00';
      result[range.name] = summary;
    }
    Navigator.pop(context, result);
  }
}

class TimeRangeData {
  String name;
  int startHour;
  int endHour;
  int colorIndex;

  TimeRangeData({
    required this.name,
    required this.startHour,
    required this.endHour,
    this.colorIndex = 0,
  });
}
