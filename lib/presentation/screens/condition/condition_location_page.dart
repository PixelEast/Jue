import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

class ConditionLocationPage extends StatefulWidget {
  final List<String> optionGroupNames;
  final VoidCallback? onSwitchToTime;

  const ConditionLocationPage({
    super.key,
    required this.optionGroupNames,
    this.onSwitchToTime,
  });

  @override
  State<ConditionLocationPage> createState() => _ConditionLocationPageState();
}

class _ConditionLocationPageState extends State<ConditionLocationPage> {
  int _selectedDefaultGroupIndex = 0;
  final Map<int, LocationData> _locations = {};
  final Map<int, MapController> _mapControllers = {};
  final Map<int, LatLng> _mapCenters = {};

  @override
  void initState() {
    super.initState();
    _initializeLocations();
    _requestLocationPermission();
  }

  void _initializeLocations() {
    // 默认位置（北京天安门）
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
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      // 获取当前位置并更新所有地图中心
      // 这里简化处理，实际应该使用geolocator
    }
  }

  // 根据半径计算缩放级别
  double _getZoomLevel(double radiusInMeters) {
    // 半径越大，缩放级别越小（地图越缩小）
    // 200m -> zoom 16
    // 400m -> zoom 15
    // 50m -> zoom 18
    if (radiusInMeters <= 50) return 18;
    if (radiusInMeters >= 400) return 15;
    return 16 - (radiusInMeters - 200) / 200;
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
          // Header
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
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onSwitchToTime ?? () {},
                          child: const Center(
                            child: Text(
                              '时间范围',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              '位置范围',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
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
          const SizedBox(height: 16),
          // Default group selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
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
                      fillColor: Colors.white,
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
                    style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Location cards list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: widget.optionGroupNames.length,
              itemBuilder: (context, index) => _buildLocationCard(index),
            ),
          ),
          // Apply button
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: _applyConditions,
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

  Widget _buildLocationCard(int index) {
    final location = _locations[index]!;
    final groupName = widget.optionGroupNames[index];
    final color = _getGroupColor(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map
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
                // Location info (bottom left)
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
                // Current location button (bottom right)
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
          // Info and controls
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
                      style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
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
                            // Update map zoom
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
    // 这里应该使用geolocator获取真实位置
    // 简化处理：显示一个提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在获取当前位置...'),
        duration: Duration(seconds: 1),
      ),
    );

    // 模拟获取位置（实际应该使用geolocator）
    await Future.delayed(const Duration(milliseconds: 500));

    // 示例：移动到北京的一个位置
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

  void _applyConditions() {
    final result = <String, String>{};
    for (int i = 0; i < widget.optionGroupNames.length; i++) {
      final loc = _locations[i];
      result[widget.optionGroupNames[i]] =
          '位置范围: 半径 ${loc?.radius.toStringAsFixed(0) ?? 200}m';
    }
    Navigator.pop(context, result);
  }

  @override
  void dispose() {
    for (var controller in _mapControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
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
