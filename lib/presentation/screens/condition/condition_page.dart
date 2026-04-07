import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

class ConditionPage extends StatefulWidget {
  final List<String> optionGroupNames;
  final Map<String, String> existingConditions;

  const ConditionPage({
    super.key,
    required this.optionGroupNames,
    this.existingConditions = const {},
  });

  @override
  State<ConditionPage> createState() => _ConditionPageState();
}

class _ConditionPageState extends State<ConditionPage> {
  int _selectedMode = 0;

  // Time state
  late List<TimeRangeData> _timeRanges;
  late List<int> _groupOrder;
  int? _draggingBoundaryIndex;
  int? _draggingGroupIndex;
  double _dragCardOffsetY = 0;
  double _dragStartGlobalY = 0;
  double _dragOriginalTop = 0;
  int _dragStartOrderIndex = 0;
  bool _hideBoundaries = false;

  // Location state
  int _selectedDefaultGroupIndex = 0;
  final Map<int, LocationData> _locations = {};
  final Map<int, MapController> _mapControllers = {};
  final Map<int, LatLng> _mapCenters = {};

  final GlobalKey _timelineKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  static const Color _primary = Color(0xFF000000);
  static const Color _surface = Color(0xFFF9F9F9);
  static const Color _secondary = Color(0xFF5E5E5E);
  static const Color _outlineVariant = Color(0xFFC6C6C6);

  @override
  void initState() {
    super.initState();
    _initializeTimeRanges();
    _initializeLocations();
  }

  void _initializeTimeRanges() {
    _groupOrder = List.generate(widget.optionGroupNames.length, (i) => i);
    _timeRanges = [];
    int currentHour = 0;
    final count = widget.optionGroupNames.length;
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

    // Restore existing conditions
    for (var range in _timeRanges) {
      final existing = widget.existingConditions[range.name];
      if (existing != null && existing.startsWith('时间范围')) {
        final parts = existing.replaceAll('时间范围 ', '').split(' - ');
        if (parts.length == 2) {
          final start = int.tryParse(parts[0].replaceAll(':00', ''));
          final end = int.tryParse(parts[1].replaceAll(':00', ''));
          if (start != null && end != null) {
            range.startHour = start;
            range.endHour = end;
          }
        }
      }
    }
  }

  void _initializeLocations() {
    const defaultLat = 39.9042;
    const defaultLng = 116.4074;
    const defaultRadius = 200.0;

    for (int i = 0; i < widget.optionGroupNames.length; i++) {
      _locations[i] = LocationData(
        latitude: defaultLat,
        longitude: defaultLng,
        radius: defaultRadius,
      );
      _mapCenters[i] = LatLng(defaultLat, defaultLng);
      _mapControllers[i] = MapController();
    }

    // Restore existing location conditions
    for (int i = 0; i < widget.optionGroupNames.length; i++) {
      final existing = widget.existingConditions[widget.optionGroupNames[i]];
      if (existing != null && existing.startsWith('位置范围')) {
        final radiusStr = existing
            .replaceAll('位置范围: 半径 ', '')
            .replaceAll('m', '');
        final radius = double.tryParse(radiusStr);
        if (radius != null) {
          _locations[i] = LocationData(
            latitude: defaultLat,
            longitude: defaultLng,
            radius: radius,
          );
        }
      }
    }
  }

  bool _isDarkColor(Color color) => color.computeLuminance() < 0.5;

  Color _getColorForHour(double hour) {
    if (hour <= 13) {
      final t = hour / 13;
      return Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), t)!;
    } else {
      final t = (hour - 13) / 11;
      return Color.lerp(const Color(0xFFFFFFFF), const Color(0xFF000000), t)!;
    }
  }

  Color _getCardColor(TimeRangeData range) {
    final midHour = (range.startHour + range.endHour) / 2;
    return _getColorForHour(midHour);
  }

  double _getZoomLevel(double radiusInMeters) {
    if (radiusInMeters <= 50) return 18;
    if (radiusInMeters >= 400) return 15;
    return 16 - (radiusInMeters - 200) / 200;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var controller in _mapControllers.values) {
      controller.dispose();
    }
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
            child: Column(
              children: [
                Expanded(
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
                        Container(
                          height: 55,
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
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedMode = 0),
                                  child: Container(
                                    margin: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _selectedMode == 0
                                          ? _primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '时间范围',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: _selectedMode == 0
                                              ? Colors.white
                                              : _secondary,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedMode = 1),
                                  child: Container(
                                    margin: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _selectedMode == 1
                                          ? _primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '位置范围',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: _selectedMode == 1
                                              ? Colors.white
                                              : _secondary,
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
                        const SizedBox(height: 32),
                        if (_selectedMode == 0) ...[
                          _buildTimeline(),
                        ] else ...[
                          _buildLocationContent(),
                        ],
                        const SizedBox(height: 48),
                        _buildFooterButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _primary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '默认选项组',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedDefaultGroupIndex,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: widget.optionGroupNames.asMap().entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedDefaultGroupIndex = value!);
                },
              ),
              const SizedBox(height: 8),
              const Text(
                '当不在任何选项组位置范围内时，默认使用此选项组',
                style: TextStyle(fontSize: 12, color: _secondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          widget.optionGroupNames.length,
          (index) => _buildLocationCard(index),
        ),
      ],
    );
  }

  Widget _buildLocationCard(int index) {
    final location = _locations[index]!;
    final groupName = widget.optionGroupNames[index];
    final color = _getGroupColor(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapControllers[index],
                  options: MapOptions(
                    center:
                        _mapCenters[index] ?? const LatLng(39.9042, 116.4074),
                    zoom: _getZoomLevel(location.radius),
                    minZoom: 13,
                    maxZoom: 19,
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture && position.center != null) {
                        setState(() {
                          _mapCenters[index] = position.center!;
                          _locations[index] = LocationData(
                            latitude: position.center!.latitude,
                            longitude: position.center!.longitude,
                            radius: location.radius,
                          );
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.jue',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point:
                              _mapCenters[index] ?? LatLng(39.9042, 116.4074),
                          radius: location.radius,
                          useRadiusInMeter: true,
                          color: color.withValues(alpha: 0.2),
                          borderColor: color,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '纬度: ${location.latitude.toStringAsFixed(4)}\n经度: ${location.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8E8E93),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _setToCurrentLocation(index),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(Icons.my_location, color: color, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      '范围',
                      style: TextStyle(fontSize: 14, color: _secondary),
                    ),
                    Expanded(
                      child: Slider(
                        value: location.radius,
                        min: 50,
                        max: 400,
                        divisions: 35,
                        label: '${location.radius.toInt()}m',
                        onChanged: (value) {
                          setState(() {
                            _locations[index] = LocationData(
                              latitude: location.latitude,
                              longitude: location.longitude,
                              radius: value,
                            );
                            _mapControllers[index]?.move(
                              _mapCenters[index] ?? LatLng(39.9042, 116.4074),
                              _getZoomLevel(value),
                            );
                          });
                        },
                      ),
                    ),
                    Text(
                      '${location.radius.toInt()}m',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getGroupColor(int index) {
    final colors = [
      const Color(0xFF002FA7),
      const Color(0xFF6FA8FF),
      const Color(0xFFB8D4FF),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFB86B),
      const Color(0xFF6BFFB8),
    ];
    return colors[index % colors.length];
  }

  Future<void> _setToCurrentLocation(int index) async {
    final status = await Permission.location.request();
    if (!mounted) return;
    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在获取当前位置...'),
          duration: Duration(seconds: 1),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      const newLat = 39.9142;
      const newLng = 116.4274;
      setState(() {
        _mapCenters[index] = LatLng(newLat, newLng);
        _locations[index] = LocationData(
          latitude: newLat,
          longitude: newLng,
          radius: _locations[index]!.radius,
        );
        _mapControllers[index]?.move(
          LatLng(newLat, newLng),
          _getZoomLevel(_locations[index]!.radius),
        );
      });
    }
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
            width: 4,
            child: Container(color: _primary),
          ),
          Positioned(
            left: timeAxisWidth + 2,
            top: 0,
            right: 0,
            height: totalHeight,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  for (int i = 0; i < _groupOrder.length; i++)
                    _buildCard(i, hourIntervalHeight),
                  for (int i = 0; i < _groupOrder.length - 1; i++)
                    _buildBoundary(i, hourIntervalHeight),
                ],
              ),
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
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Transform.translate(
                  offset: hour == 0
                      ? const Offset(0, -7)
                      : (hour == 24 ? const Offset(0, 7) : Offset.zero),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: TextStyle(
                      fontSize: hour % 6 == 0 ? 13 : 11,
                      fontWeight: hour % 6 == 0
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: hour % 6 == 0 ? _primary : _secondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
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
    final bgColor = _getCardColor(range);
    final isDark = _isDarkColor(bgColor);
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
          children: [
            Positioned(
              left: 8,
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
                      size: 26,
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
    final bgColor = _getCardColor(range);
    final isDark = _isDarkColor(bgColor);
    final boundaryPosition = range.endHour * hourIntervalHeight;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
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
    if (_selectedMode == 0) {
      for (var range in _timeRanges) {
        final summary =
            '时间范围 ${range.startHour.toString().padLeft(2, '0')}:00 - ${range.endHour.toString().padLeft(2, '0')}:00';
        result[range.name] = summary;
      }
    } else {
      for (int i = 0; i < widget.optionGroupNames.length; i++) {
        final loc = _locations[i];
        result[widget.optionGroupNames[i]] =
            '位置范围: 半径 ${loc?.radius.toStringAsFixed(0) ?? 200}m';
      }
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

class LocationData {
  double latitude;
  double longitude;
  double radius;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.radius,
  });
}
