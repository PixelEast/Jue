import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'dart:ui';

class ConditionPage extends StatefulWidget {
  final List<String> optionGroupNames;
  final Map<String, String> existingConditions;
  final Map<String, Map<String, dynamic>> existingGroupData;
  final String initialMode;

  const ConditionPage({
    super.key,
    required this.optionGroupNames,
    this.existingConditions = const {},
    this.existingGroupData = const {},
    this.initialMode = 'time',
  });

  @override
  State<ConditionPage> createState() => _ConditionPageState();
}

class _ConditionPageState extends State<ConditionPage>
    with TickerProviderStateMixin {
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
  final Map<int, String> _placeLabels = {};
  bool _locationModeReady = false;
  final Map<int, AnimationController> _zoomControllers = {};
  final Map<int, double> _animatedZooms = {};
  final GlobalKey _defaultGroupFieldKey = GlobalKey();
  final ValueNotifier<bool> _defaultGroupDropdownOpen = ValueNotifier(false);
  OverlayEntry? _defaultGroupDropdownEntry;
  late final AnimationController _defaultGroupDropdownController;

  final GlobalKey _timelineKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  static const Color _primary = Color(0xFF000000);
  static const Color _surface = Color(0xFFF9F9F9);
  static const Color _secondary = Color(0xFF5E5E5E);
  static const Color _outlineVariant = Color(0xFFC6C6C6);

  @override
  void initState() {
    super.initState();
    _defaultGroupDropdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _selectedMode = widget.initialMode == 'location' ? 1 : 0;
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
      final groupData = widget.existingGroupData[range.name];
      if (groupData != null) {
        final start = groupData['startHour'] as int?;
        final end = groupData['endHour'] as int?;
        if (start != null && end != null) {
          range.startHour = start;
          range.endHour = end;
          continue;
        }
      }
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
    const defaultRadius = 200.0;
    var hasAnySavedLocation = false;

    for (int i = 0; i < widget.optionGroupNames.length; i++) {
      _locations[i] = LocationData(
        latitude: 0,
        longitude: 0,
        radius: defaultRadius,
      );
      _mapCenters[i] = const LatLng(0, 0);
      _mapControllers[i] = MapController();
      _zoomControllers[i] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 180),
      );
      _animatedZooms[i] = _getZoomLevel(defaultRadius);
      _placeLabels[i] = '获取中';
    }

    // Restore existing location conditions
    for (int i = 0; i < widget.optionGroupNames.length; i++) {
      final groupName = widget.optionGroupNames[i];
      final groupData = widget.existingGroupData[groupName];
      if (groupData != null) {
        final latitude = (groupData['latitude'] as num?)?.toDouble();
        final longitude = (groupData['longitude'] as num?)?.toDouble();
        final radius = (groupData['radiusMeters'] as num?)?.toDouble();
        final isDefault = groupData['isDefaultGroup'] as bool? ?? false;

        if (latitude != null && longitude != null && radius != null) {
          hasAnySavedLocation = true;
          _locations[i] = LocationData(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
          );
          _mapCenters[i] = LatLng(latitude, longitude);
          _animatedZooms[i] = _getZoomLevel(radius);
        }
        if (isDefault) {
          _selectedDefaultGroupIndex = i;
        }
        continue;
      }

      final existing = widget.existingConditions[groupName];
      if (existing != null && existing.startsWith('位置范围')) {
        final radiusStr = existing
            .replaceAll('位置范围: 半径 ', '')
            .replaceAll('m', '');
        final radius = double.tryParse(radiusStr);
        if (radius != null) {
          _locations[i] = LocationData(
            latitude: 0,
            longitude: 0,
            radius: radius,
          );
          _animatedZooms[i] = _getZoomLevel(radius);
        }
      }
    }

    if (hasAnySavedLocation) {
      _locationModeReady = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshAllPlaceLabelsSequentially();
      });
    } else {
      _locationModeReady = false;
      _initializeCurrentLocationDefaults();
    }
  }

  Future<void> _initializeCurrentLocationDefaults() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      for (int i = 0; i < widget.optionGroupNames.length; i++) {
        _placeLabels[i] = '请开启定位';
      }
      _locationModeReady = true;
      if (mounted) setState(() {});
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      for (int i = 0; i < widget.optionGroupNames.length; i++) {
        _placeLabels[i] = '定位未授权';
      }
      _locationModeReady = true;
      if (mounted) setState(() {});
      return;
    }

    try {
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final lat = position.latitude;
      final lng = position.longitude;

      for (int i = 0; i < widget.optionGroupNames.length; i++) {
        final existing = _locations[i]!;
        final hasSavedCustomCenter =
            existing.latitude != 0 || existing.longitude != 0;
        _locations[i] = LocationData(
          latitude: hasSavedCustomCenter ? existing.latitude : lat,
          longitude: hasSavedCustomCenter ? existing.longitude : lng,
          radius: existing.radius,
        );
        _mapCenters[i] = LatLng(
          hasSavedCustomCenter ? existing.latitude : lat,
          hasSavedCustomCenter ? existing.longitude : lng,
        );
      }

      _locationModeReady = true;
      if (mounted) {
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _refreshAllPlaceLabelsSequentially();
        });
      }
    } catch (_) {
      for (int i = 0; i < widget.optionGroupNames.length; i++) {
        _placeLabels[i] = '当前位置';
      }
      _locationModeReady = true;
      if (mounted) setState(() {});
    }
  }

  Future<void> _refreshAllPlaceLabelsSequentially() async {
    for (int i = 0; i < widget.optionGroupNames.length; i++) {
      await _refreshPlaceLabel(i);
    }
  }

  Future<void> _refreshPlaceLabel(int index) async {
    final location = _locations[index];
    if (location == null) return;
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final label = _bestPlaceLabelFromPlacemark(place);
        if (mounted) {
          setState(() {
            _placeLabels[index] = label;
          });
        }
        return;
      }
    } catch (_) {}

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${location.latitude}&lon=${location.longitude}',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'jue-condition-page/1.0'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final address = json['address'] as Map<String, dynamic>?;
        final label = _bestPlaceLabelFromNominatim(json, address);
        if (mounted) {
          setState(() {
            _placeLabels[index] = label;
          });
        }
      } else if (mounted) {
        setState(() {
          _placeLabels[index] = '当前位置';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _placeLabels[index] = '当前位置';
        });
      }
    }
  }

  String _bestPlaceLabelFromPlacemark(Placemark place) {
    final candidates = <String>[
      if ((place.name ?? '').trim().isNotEmpty) place.name!.trim(),
      if ((place.street ?? '').trim().isNotEmpty) place.street!.trim(),
      if ((place.subLocality ?? '').trim().isNotEmpty)
        place.subLocality!.trim(),
      if ((place.locality ?? '').trim().isNotEmpty) place.locality!.trim(),
      if ((place.subAdministrativeArea ?? '').trim().isNotEmpty)
        place.subAdministrativeArea!.trim(),
    ];

    final preferred = _pickMostSpecificLabel(candidates);
    if (preferred != null) return _trimAdministrativePrefix(preferred);

    final street = (place.street ?? '').trim();
    final subLocality = (place.subLocality ?? '').trim();
    if (street.isNotEmpty && subLocality.isNotEmpty && street != subLocality) {
      return _trimAdministrativePrefix('$street · $subLocality');
    }

    return candidates.isNotEmpty
        ? _trimAdministrativePrefix(candidates.first)
        : '当前位置';
  }

  String _bestPlaceLabelFromNominatim(
    Map<String, dynamic> json,
    Map<String, dynamic>? address,
  ) {
    final candidates = <String>[
      if ((address?['building'] ?? '').toString().trim().isNotEmpty)
        (address?['building'] ?? '').toString().trim(),
      if ((address?['amenity'] ?? '').toString().trim().isNotEmpty)
        (address?['amenity'] ?? '').toString().trim(),
      if ((address?['leisure'] ?? '').toString().trim().isNotEmpty)
        (address?['leisure'] ?? '').toString().trim(),
      if ((address?['road'] ?? '').toString().trim().isNotEmpty)
        (address?['road'] ?? '').toString().trim(),
      if ((address?['neighbourhood'] ?? '').toString().trim().isNotEmpty)
        (address?['neighbourhood'] ?? '').toString().trim(),
      if ((address?['suburb'] ?? '').toString().trim().isNotEmpty)
        (address?['suburb'] ?? '').toString().trim(),
      if ((json['name'] ?? '').toString().trim().isNotEmpty)
        (json['name'] ?? '').toString().trim(),
    ];

    final picked = _pickMostSpecificLabel(candidates);
    return picked != null ? _trimAdministrativePrefix(picked) : '当前位置';
  }

  String _trimAdministrativePrefix(String input) {
    var text = input.trim();
    if (text.isEmpty) return '当前位置';

    text = text.replaceAll(RegExp(r'[（(][^）)]*[）)]$'), '').trim();
    text = text.replaceAll(RegExp(r'(东|西|南|北)\d+米$'), '').trim();
    text = text.replaceAll(RegExp(r'(东|西|南|北)$'), '').trim();

    final cnParenIndex = text.indexOf('（');
    final enParenIndex = text.indexOf('(');
    int parenIndex = -1;
    if (cnParenIndex >= 0 && enParenIndex >= 0) {
      parenIndex = cnParenIndex < enParenIndex ? cnParenIndex : enParenIndex;
    } else if (cnParenIndex >= 0) {
      parenIndex = cnParenIndex;
    } else if (enParenIndex >= 0) {
      parenIndex = enParenIndex;
    }
    final plainPart = parenIndex >= 0 ? text.substring(0, parenIndex) : text;

    final segments = plainPart
        .split(RegExp(r'[,/·\-]|\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    String candidate = plainPart;
    if (segments.isNotEmpty) {
      candidate = segments.last;
    }

    final compactParts = plainPart
        .split(RegExp(r'省|市|区|县'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (compactParts.isNotEmpty) {
      candidate = compactParts.last;
    }

    candidate = candidate.trim();
    return candidate.isEmpty ? text : candidate;
  }

  String? _pickMostSpecificLabel(List<String> rawCandidates) {
    final candidates = rawCandidates
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .where((e) => !_isDirectionOnly(e))
        .toSet()
        .toList();
    if (candidates.isEmpty) return null;

    const preferredKeywords = [
      '小区',
      '家园',
      '花园',
      '大厦',
      '广场',
      '公园',
      '苑',
      '城',
      '园',
      '厦',
      '府',
      '路',
      '街',
      '道',
    ];

    for (final keyword in preferredKeywords) {
      final match = candidates.where((e) => e.contains(keyword)).toList();
      if (match.isNotEmpty) {
        match.sort((a, b) => b.length.compareTo(a.length));
        return match.first;
      }
    }

    final filtered = candidates.where((e) {
      return !(e.endsWith('省') ||
          e.endsWith('市') ||
          e.endsWith('区') ||
          e.endsWith('县'));
    }).toList();

    if (filtered.isNotEmpty) {
      filtered.sort((a, b) => b.length.compareTo(a.length));
      return filtered.first;
    }

    candidates.sort((a, b) => b.length.compareTo(a.length));
    return candidates.first;
  }

  bool _isDirectionOnly(String text) {
    const directionOnly = {
      '东',
      '西',
      '南',
      '北',
      '东北',
      '东南',
      '西北',
      '西南',
      '东门',
      '西门',
      '南门',
      '北门',
    };
    return directionOnly.contains(text.trim());
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

  void _animateMapZoom(int index, LatLng center, double targetZoom) {
    final controller = _zoomControllers[index];
    final mapController = _mapControllers[index];
    if (controller == null || mapController == null) return;

    final currentZoom = _animatedZooms[index] ?? _getZoomLevel(200);
    if ((currentZoom - targetZoom).abs() < 0.01) {
      _animatedZooms[index] = targetZoom;
      mapController.move(center, targetZoom);
      return;
    }

    controller.stop();
    controller.reset();
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    final tween = Tween<double>(begin: currentZoom, end: targetZoom);

    void listener() {
      final zoom = tween.evaluate(curved);
      _animatedZooms[index] = zoom;
      mapController.move(center, zoom);
    }

    controller.addListener(listener);
    controller.forward().whenCompleteOrCancel(() {
      controller.removeListener(listener);
    });
  }

  @override
  void dispose() {
    _removeDefaultGroupDropdown(immediate: true);
    _defaultGroupDropdownController.dispose();
    _defaultGroupDropdownOpen.dispose();
    _scrollController.dispose();
    for (var controller in _mapControllers.values) {
      controller.dispose();
    }
    for (var controller in _zoomControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleDefaultGroupDropdown() {
    _defaultGroupDropdownController.stop();
    if (_defaultGroupDropdownEntry == null) {
      _showDefaultGroupDropdown();
    } else {
      _removeDefaultGroupDropdown(immediate: true);
    }
  }

  void _showDefaultGroupDropdown() {
    final overlay = Overlay.of(context);
    final renderBox =
        _defaultGroupFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final fieldSize = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _defaultGroupDropdownOpen.value = true;
    _defaultGroupDropdownEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: Stack(
            children: [
              Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) =>
                    _removeDefaultGroupDropdown(immediate: true),
                child: const SizedBox.expand(),
              ),
              Positioned(
                left: offset.dx,
                top: offset.dy + fieldSize.height + 4,
                width: fieldSize.width,
                child: Material(
                  color: Colors.transparent,
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _defaultGroupDropdownController,
                      curve: Curves.easeOutCubic,
                    ),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _defaultGroupDropdownController,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      alignment: Alignment.topCenter,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.68),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _outlineVariant.withValues(alpha: 0.18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: widget.optionGroupNames
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    final isSelected =
                                        entry.key == _selectedDefaultGroupIndex;
                                    final isLast =
                                        entry.key ==
                                        widget.optionGroupNames.length - 1;
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedDefaultGroupIndex =
                                              entry.key;
                                        });
                                        _removeDefaultGroupDropdown(
                                          immediate: true,
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.black.withValues(
                                                  alpha: 0.04,
                                                )
                                              : Colors.transparent,
                                          border: !isLast
                                              ? Border(
                                                  bottom: BorderSide(
                                                    color: _outlineVariant
                                                        .withValues(
                                                          alpha: 0.12,
                                                        ),
                                                  ),
                                                )
                                              : null,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                entry.value,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color: _primary,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              const Icon(
                                                Icons.check,
                                                size: 18,
                                                color: _primary,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_defaultGroupDropdownEntry!);
    _defaultGroupDropdownController.forward(from: 0);
  }

  void _removeDefaultGroupDropdown({bool immediate = false}) {
    final entry = _defaultGroupDropdownEntry;
    if (entry == null) return;

    _defaultGroupDropdownOpen.value = false;
    if (immediate) {
      entry.remove();
      _defaultGroupDropdownEntry = null;
      return;
    }

    _defaultGroupDropdownController.reverse().whenCompleteOrCancel(() {
      if (_defaultGroupDropdownEntry == entry) {
        entry.remove();
        _defaultGroupDropdownEntry = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _applyConditions();
        }
      },
      child: Scaffold(
        backgroundColor: _surface,
        body: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: _applyConditions,
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
                  child: const Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: _primary,
                  ),
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
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
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
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
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
            if (_defaultGroupDropdownEntry != null)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _removeDefaultGroupDropdown,
                  child: Builder(
                    builder: (context) {
                      final renderBox =
                          _defaultGroupFieldKey.currentContext
                                  ?.findRenderObject()
                              as RenderBox?;
                      if (renderBox == null) return const SizedBox.expand();
                      final offset = renderBox.localToGlobal(Offset.zero);
                      final size = renderBox.size;

                      return Stack(
                        children: [
                          Positioned(
                            left: offset.dx,
                            top: offset.dy + size.height + 4,
                            width: size.width,
                            child: Material(
                              color: Colors.transparent,
                              child: AnimatedOpacity(
                                opacity: 1,
                                duration: const Duration(milliseconds: 180),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.96, end: 1.0),
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      alignment: Alignment.topCenter,
                                      child: child,
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 14,
                                        sigmaY: 14,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.68,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _outlineVariant.withValues(
                                              alpha: 0.18,
                                            ),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: widget.optionGroupNames
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                                final isSelected =
                                                    entry.key ==
                                                    _selectedDefaultGroupIndex;
                                                final isLast =
                                                    entry.key ==
                                                    widget
                                                            .optionGroupNames
                                                            .length -
                                                        1;
                                                return InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedDefaultGroupIndex =
                                                          entry.key;
                                                    });
                                                    _removeDefaultGroupDropdown();
                                                  },
                                                  child: Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 14,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? Colors.black
                                                                .withValues(
                                                                  alpha: 0.04,
                                                                )
                                                          : Colors.transparent,
                                                      border: !isLast
                                                          ? Border(
                                                              bottom: BorderSide(
                                                                color: _outlineVariant
                                                                    .withValues(
                                                                      alpha:
                                                                          0.12,
                                                                    ),
                                                              ),
                                                            )
                                                          : null,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            entry.value,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  isSelected
                                                                  ? FontWeight
                                                                        .w700
                                                                  : FontWeight
                                                                        .w500,
                                                              color: _primary,
                                                            ),
                                                          ),
                                                        ),
                                                        if (isSelected)
                                                          const Icon(
                                                            Icons.check,
                                                            size: 18,
                                                            color: _primary,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              })
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationContent() {
    if (!_locationModeReady) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 16),
            Text(
              '正在获取当前位置...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _secondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primary),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '注意：如果所在位置在多个选项组的位置范围内，则会选择距离中心点最近的选项组为目标；若与多个选项组的距离相等，则会在这些选项组内随机选择一个作为抽选目标。',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E2E2).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error_outline, size: 20, color: _primary),
                  SizedBox(width: 8),
                  Text(
                    '默认组',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '这个逻辑条件的默认选项组，在所有条件都不符合的情况下，会优先选定这个选项组作为抽选目标。',
                style: TextStyle(
                  fontSize: 12,
                  color: _secondary,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                key: _defaultGroupFieldKey,
                child: GestureDetector(
                  onTap: _toggleDefaultGroupDropdown,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _outlineVariant.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.optionGroupNames[_selectedDefaultGroupIndex],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _primary,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _defaultGroupDropdownEntry != null ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(
                            Icons.expand_more,
                            color: _primary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(
          widget.optionGroupNames.length,
          (index) => _buildLocationCard(
            index,
            isLast: index == widget.optionGroupNames.length - 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(int index, {required bool isLast}) {
    final location = _locations[index]!;
    final groupName = widget.optionGroupNames[index];
    final placeLabel = (_placeLabels[index]?.trim().isNotEmpty ?? false)
        ? _placeLabels[index]!
        : '当前位置';

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF4F4F4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                Positioned.fill(
                  child: Container(color: const Color(0xFFF0F0F0)),
                ),
                FlutterMap(
                  mapController: _mapControllers[index],
                  options: MapOptions(
                    center:
                        _mapCenters[index] ?? const LatLng(39.9042, 116.4074),
                    zoom:
                        _animatedZooms[index] ?? _getZoomLevel(location.radius),
                    minZoom: 13,
                    maxZoom: 19,
                    enableScrollWheel: false,
                    enableMultiFingerGestureRace: false,
                    interactiveFlags: InteractiveFlag.drag,
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
                    onMapEvent: (event) {
                      if (event.source == MapEventSource.dragEnd) {
                        _refreshPlaceLabel(index);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.jue',
                    ),
                  ],
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _MapGridPainter()),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: SizedBox(
                        width: 128,
                        height: 128,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _DashedCirclePainter(
                                  fillColor: Colors.black.withValues(
                                    alpha: 0.05,
                                  ),
                                  strokeColor: Colors.black.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                            ),
                            const Center(
                              child: SizedBox(
                                width: 6,
                                height: 6,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Text(
                      placeLabel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                        letterSpacing: 1.1,
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.navigation_outlined,
                        color: _primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Expanded(
                          child: Text(
                            '范围距离(半径)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _secondary,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        Text(
                          '${location.radius.toInt()}m',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        trackShape: const _FullWidthRoundedTrackShape(),
                        activeTrackColor: const Color(0xFF5E5E5E),
                        inactiveTrackColor: const Color(0xFFE2E2E2),
                        thumbColor: _primary,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 9.6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                        showValueIndicator: ShowValueIndicator.never,
                        tickMarkShape: SliderTickMarkShape.noTickMark,
                        activeTickMarkColor: Colors.transparent,
                        inactiveTickMarkColor: Colors.transparent,
                        overlayColor: _primary.withValues(alpha: 0.08),
                      ),
                      child: Slider(
                        value: location.radius,
                        min: 50,
                        max: 400,
                        divisions: 35,
                        onChanged: (value) {
                          final stepped =
                              (((value - 50) / 10).round() * 10) + 50;
                          final radius = stepped.clamp(50, 400).toDouble();
                          setState(() {
                            _locations[index] = LocationData(
                              latitude: location.latitude,
                              longitude: location.longitude,
                              radius: radius,
                            );
                            _animateMapZoom(
                              index,
                              _mapCenters[index] ??
                                  const LatLng(39.9042, 116.4074),
                              _getZoomLevel(radius),
                            );
                          });
                        },
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

  Future<void> _setToCurrentLocation(int index) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      messenger.showSnackBar(const SnackBar(content: Text('请先开启系统定位服务')));
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      messenger.showSnackBar(const SnackBar(content: Text('定位权限未开启')));
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final newLat = position.latitude;
      final newLng = position.longitude;
      setState(() {
        _mapCenters[index] = LatLng(newLat, newLng);
        _locations[index] = LocationData(
          latitude: newLat,
          longitude: newLng,
          radius: _locations[index]!.radius,
        );
        _animateMapZoom(
          index,
          LatLng(newLat, newLng),
          _getZoomLevel(_locations[index]!.radius),
        );
        _placeLabels[index] = '获取中';
      });
      _refreshPlaceLabel(index);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('获取当前位置失败'),
          duration: Duration(seconds: 1),
        ),
      );
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
      child: AnimatedContainer(
        duration: isDragging
            ? Duration.zero
            : const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
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
                  child: AnimatedOpacity(
                    duration: isDragging
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    opacity: 0.4,
                    child: AnimatedSwitcher(
                      duration: isDragging
                          ? Duration.zero
                          : const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Icon(
                        Icons.drag_indicator,
                        key: ValueKey<Color>(isDark ? Colors.white : _primary),
                        size: 26,
                        color: isDark ? Colors.white : _primary,
                      ),
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
                  AnimatedDefaultTextStyle(
                    duration: isDragging
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : _primary,
                      letterSpacing: 0.2,
                      height: 1.2,
                    ),
                    child: Text(
                      range.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: isDragging
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : _secondary,
                      letterSpacing: 1.5,
                      height: 1.1,
                    ),
                    child: Text(
                      '${range.startHour.toString().padLeft(2, '0')}:00 — ${range.endHour.toString().padLeft(2, '0')}:00',
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
    final summaries = <String, String>{};
    final groupData = <String, Map<String, dynamic>>{};
    if (_selectedMode == 0) {
      for (var range in _timeRanges) {
        final summary =
            '时间范围 ${range.startHour.toString().padLeft(2, '0')}:00 - ${range.endHour.toString().padLeft(2, '0')}:00';
        summaries[range.name] = summary;
        groupData[range.name] = {
          'startHour': range.startHour,
          'endHour': range.endHour,
          'latitude': null,
          'longitude': null,
          'radiusMeters': null,
          'isDefaultGroup': false,
          'conditionSummary': summary,
        };
      }
    } else {
      for (int i = 0; i < widget.optionGroupNames.length; i++) {
        final loc = _locations[i];
        final summary = '位置范围: 半径 ${loc?.radius.toStringAsFixed(0) ?? 200}m';
        final groupName = widget.optionGroupNames[i];
        summaries[groupName] = summary;
        groupData[groupName] = {
          'startHour': null,
          'endHour': null,
          'latitude': loc?.latitude,
          'longitude': loc?.longitude,
          'radiusMeters': loc?.radius,
          'isDefaultGroup': i == _selectedDefaultGroupIndex,
          'conditionSummary': summary,
        };
      }
    }
    Navigator.pop(context, {
      'summaries': summaries,
      'groupData': groupData,
      'selectedMode': _selectedMode == 0 ? 'time' : 'location',
    });
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

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0D000000)
      ..strokeWidth = 1;

    const gap = 20.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedCirclePainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;

  _DashedCirclePainter({required this.fillColor, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashWidth = 6.0;
    const dashGap = 4.0;
    final circumference = 2 * 3.141592653589793 * radius;
    final dashCount = (circumference / (dashWidth + dashGap)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startAngle =
          (i * (dashWidth + dashGap) / circumference) * 2 * 3.141592653589793;
      final sweepAngle = (dashWidth / circumference) * 2 * 3.141592653589793;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 0.5),
        startAngle,
        sweepAngle,
        false,
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}

class _FullWidthRoundedTrackShape extends RoundedRectSliderTrackShape {
  const _FullWidthRoundedTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 4;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(
      offset.dx,
      trackTop,
      parentBox.size.width,
      trackHeight,
    );
  }
}
