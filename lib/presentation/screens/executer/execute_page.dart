import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/models/app_models.dart';
import '../../../data/repositories/decision_repository.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../core/utils/algorithms.dart';
import '../../../core/utils/app_events.dart';
import '../create/edit_decision_page.dart';

class ExecutePage extends StatefulWidget {
  final Decision decision;

  const ExecutePage({super.key, required this.decision});

  @override
  State<ExecutePage> createState() => _ExecutePageState();
}

class _ExecutePageState extends State<ExecutePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  bool _isExecuting = false;
  bool _isLongPress = false;
  bool _showResult = false;
  String _result = '';
  int _pressDuration = 0;
  bool _locationAvailable = true;
  double? _currentLatitude;
  double? _currentLongitude;

  final WeightCalculator _weightCalc = WeightCalculator();
  final LogicConditionEngine _logicEngine = LogicConditionEngine();
  final DecisionRepository _decisionRepo = DecisionRepository();
  final HistoryRepository _historyRepo = HistoryRepository();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _checkLocationAvailability();
  }

  Future<void> _checkLocationAvailability() async {
    if (widget.decision.logicConditionType != 'location') return;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final available =
        serviceEnabled &&
        permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
    if (!available) {
      if (mounted) {
        setState(() {
          _locationAvailable = false;
        });
      }
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (mounted) {
        setState(() {
          _locationAvailable = true;
          _currentLatitude = position.latitude;
          _currentLongitude = position.longitude;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationAvailable = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startExecution(bool isLongPress) {
    if (widget.decision.logicConditionType == 'location' &&
        !_locationAvailable) {
      return;
    }
    setState(() {
      _isExecuting = true;
      _isLongPress = isLongPress;
      _pressDuration = 0;
    });
    _animationController.forward();
    HapticFeedback.heavyImpact();

    if (!isLongPress) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isExecuting) {
          _showResultPage();
        }
      });
    } else {
      _startLongPressTimer();
    }
  }

  void _startLongPressTimer() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _isExecuting && _isLongPress) {
        setState(() {
          _pressDuration += 100;
        });
        if (_pressDuration >= 6000) {
          _showResultPage();
        } else {
          _startLongPressTimer();
        }
      }
    });
  }

  void _endLongPress() {
    if (_isExecuting && _isLongPress && !_showResult) {
      _showResultPage();
    }
  }

  Future<void> _showResultPage() async {
    final activeGroup = _logicEngine.getActiveGroup(
      widget.decision,
      currentLatitude: _currentLatitude,
      currentLongitude: _currentLongitude,
    );
    if (activeGroup == null || activeGroup.options.isEmpty) {
      if (!mounted) return;
      setState(() => _result = '没有可用选项');
      return;
    }

    final selectedOption = _weightCalc.selectOption(activeGroup);
    _weightCalc.applyDynamicWeight(selectedOption, activeGroup);
    _weightCalc.recoverWeights(activeGroup);

    widget.decision.usageCount++;
    widget.decision.lastUsedAt = DateTime.now();
    await _decisionRepo.saveDecision(widget.decision);

    await _historyRepo.addRecord(
      HistoryRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        decisionId: widget.decision.id,
        decisionTheme: widget.decision.theme,
        result: selectedOption.name,
        optionGroupName: activeGroup.name,
      ),
    );
    AppEvents.notifyHistoryChanged();

    if (!mounted) return;
    setState(() {
      _showResult = true;
      _result = selectedOption.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _isExecuting
              ? const LinearGradient(
                  colors: [Color(0xFF001A5E), Color(0xFF002FA7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: _isExecuting ? null : Colors.white,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              if (!_isExecuting)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.black),
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditDecisionPage(decision: widget.decision),
                            ),
                          );
                          if (updated == true && mounted) {
                            navigator.pop(true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isExecuting) ...[
                        Text(
                          widget.decision.theme,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 60),
                        GestureDetector(
                          onTapDown:
                              (widget.decision.logicConditionType ==
                                      'location' &&
                                  !_locationAvailable)
                              ? null
                              : (_) => _startExecution(false),
                          onTapUp: (_) {},
                          onLongPressStart:
                              (widget.decision.logicConditionType ==
                                      'location' &&
                                  !_locationAvailable)
                              ? null
                              : (_) => _startExecution(true),
                          onLongPressEnd:
                              (widget.decision.logicConditionType ==
                                      'location' &&
                                  !_locationAvailable)
                              ? null
                              : (_) => _endLongPress(),
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Container(
                                width: 200,
                                height: 80,
                                decoration: BoxDecoration(
                                  color:
                                      (widget.decision.logicConditionType ==
                                              'location' &&
                                          !_locationAvailable)
                                      ? const Color(0xFFC6C6C6)
                                      : const Color(0xFF002FA7),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          ((widget.decision.logicConditionType ==
                                                          'location' &&
                                                      !_locationAvailable)
                                                  ? const Color(0xFFC6C6C6)
                                                  : const Color(0xFF002FA7))
                                              .withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.bolt,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '即刻判决',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ] else if (!_showResult) ...[
                        const Text(
                          '即将判决',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isLongPress)
                          Text(
                            '${(_pressDuration / 1000).toStringAsFixed(1)}s',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                      ] else ...[
                        const Spacer(),
                        const Text(
                          '判决结果',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _result,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '已记录至历史决定',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF002FA7),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            '返回主页',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
