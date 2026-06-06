import 'dart:math';
import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import '../../../main.dart';
import '../../../data/models/app_models.dart';
import '../../../data/repositories/decision_repository.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../core/utils/algorithms.dart';
import '../../../core/utils/app_events.dart';
import '../../widgets/app_slogan_footer.dart';
import '../../widgets/frosted_back_button.dart';
import '../create/create_decision_page.dart';

class ExecutePage extends StatefulWidget {
  final Decision decision;

  const ExecutePage({super.key, required this.decision});

  @override
  State<ExecutePage> createState() => _ExecutePageState();
}

class _ExecutePageState extends State<ExecutePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _shakeController;
  late AnimationController _darkCornerController;
  late AnimationController _resultFadeController;
  late Animation<double> _buttonFadeOut;
  late Animation<double> _textFadeIn;
  late Animation<double> _resultFadeIn;
  Timer? _hapticTimer;

  static const double _buttonWidth = 255;
  static const double _buttonHeight = 200;
  static const double _buttonRadius = 36;

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

  static const double _titleTop = 116;
  static const double _titleFontSize = 50;
  static const double _subtitleFontSize = 14;
  static const double _subtitleSpacing = 12;
  static const double _footerBottom = 73;
  static const double _footerApproxHeight = 40;

  final GlobalKey _buttonKey = GlobalKey();
  Offset? _buttonCenter;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _darkCornerController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _resultFadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _buttonFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
    _textFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeIn),
      ),
    );
    _resultFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _resultFadeController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          mounted &&
          _isExecuting &&
          !_showResult) {
        _darkCornerController.forward(from: 0);
      }
    });
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
    _hapticTimer?.cancel();
    _resultFadeController.dispose();
    _darkCornerController.dispose();
    _shakeController.dispose();
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
    _animationController.forward(from: 0);
    _darkCornerController.reset();
    _resultFadeController.reset();
    _shakeController.repeat();
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      HapticFeedback.lightImpact();
    });
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

  void _captureButtonCenter() {
    final context = _buttonKey.currentContext;
    if (context == null) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    setState(() {
      _buttonCenter = renderBox.localToGlobal(renderBox.size.center(Offset.zero));
    });
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
    _hapticTimer?.cancel();
    _shakeController.stop();
    _resultFadeController.forward(from: 0);
    _darkCornerController.animateTo(
      0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );
    HapticFeedback.mediumImpact();
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
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: Listenable.merge([_animationController, _darkCornerController, _resultFadeController]),
        builder: (context, _) {
          final titleCenter = Offset(size.width / 2, _titleTop + (_titleFontSize / 2));
          final subtitleCenter = Offset(
            size.width / 2,
            _titleTop + _titleFontSize + _subtitleSpacing + (_subtitleFontSize / 2),
          );
          final footerCenter = Offset(
            size.width / 2,
            size.height - _footerBottom - (_footerApproxHeight / 2),
          );
          final isResult = _showResult;
          final titleTextColor = isResult
              ? Colors.white
              : _colorFromCoverage(
                  baseColor: Colors.black,
                  targetColor: Colors.white,
                  targetCenter: titleCenter,
                  animationValue: _animationController.value,
                  screenSize: size,
                );
          final secondaryTextColor = isResult
              ? Colors.white.withValues(alpha: 0.86)
              : _colorFromCoverage(
                  baseColor: const Color(0xFF5E5E5E),
                  targetColor: Colors.white.withValues(alpha: 0.86),
                  targetCenter: subtitleCenter,
                  animationValue: _animationController.value,
                  screenSize: size,
                );
          final footerTextColor = isResult
              ? Colors.white.withValues(alpha: 0.86)
              : _colorFromCoverage(
                  baseColor: const Color(0xFF5E5E5E),
                  targetColor: Colors.white.withValues(alpha: 0.86),
                  targetCenter: footerCenter,
                  animationValue: _animationController.value,
                  screenSize: size,
                );
          return Container(
            color: const Color(0xFFF9F9F9),
            child: Stack(
              children: [
                  if (_buttonCenter != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ExpandingDecisionBackgroundPainter(
                          progress: Curves.easeInOutCubic.transform(
                            _animationController.value,
                          ),
                          darkCornerProgress: _darkCornerController.value,
                          startCenter: _buttonCenter!,
                          endCenter: Offset(size.width / 2, size.height / 2),
                          screenSize: size,
                          cornerRadius: _buttonRadius,
                        ),
                      ),
                    ),
                  ),
                SafeArea(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Opacity(
                          opacity: _showResult
                              ? _resultFadeIn.value
                              : _isExecuting
                                  ? _buttonFadeOut.value
                                  : 1.0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              FrostedBackButton(onTap: () => Navigator.pop(context)),
                              if (_showResult)
                                FrostedBackButton(
                                  icon: Icons.history,
                                  onTap: () {
                                    MainScreen.switchToTab(1);
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  },
                                )
                              else
                                FrostedBackButton(
                                  icon: Icons.edit,
                                  onTap: () async {
                                    final navigator = Navigator.of(context);
                                    final updated = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CreateDecisionPage(
                                          initialDecision: widget.decision,
                                          isEditing: true,
                                        ),
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
                      ),
                      Positioned(
                        top: 116,
                        left: 24,
                        right: 24,
                        child: Column(
                          children: [
                            Text(
                              widget.decision.theme,
                              style: TextStyle(
                                fontSize: 50,
                                fontWeight: FontWeight.w800,
                                color: titleTextColor,
                                height: 1,
                                fontFamilyFallback: const [
                                  'Noto Sans SC',
                                  'PingFang SC',
                                  'Microsoft YaHei',
                                  'sans-serif',
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '即刻判决 享受当下',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: secondaryTextColor,
                                letterSpacing: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (!_showResult) ...[
                                const Spacer(),
                                if (_isExecuting && _isLongPress) ...[
                                  const SizedBox(height: 50),
                                  AnimatedBuilder(
                                    animation: Listenable.merge([
                                      _shakeController,
                                      _animationController,
                                    ]),
                                    builder: (context, child) {
                                      final p = _animationController.value.clamp(0.0, 1.0);
                                      final amplitude = p * 3.0;
                                      final freq = 2.0 + p * 6.0;
                                      final offset = sin(_shakeController.value * pi * 2 * freq) * amplitude;
                                      return Opacity(
                                        opacity: _textFadeIn.value,
                                        child: Transform.translate(
                                          offset: Offset(offset, 0),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      '松开手指\n获得判决',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 45,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.2,
                                        fontFamilyFallback: [
                                          'Noto Sans SC',
                                          'PingFang SC',
                                          'Microsoft YaHei',
                                          'sans-serif',
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    '${(_pressDuration / 1000).toStringAsFixed(1)}s',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                                if (_isExecuting && !_isLongPress) ...[
                                  const SizedBox(height: 213),
                                  AnimatedBuilder(
                                    animation: Listenable.merge([
                                      _shakeController,
                                      _animationController,
                                    ]),
                                    builder: (context, child) {
                                      final p = _animationController.value.clamp(0.0, 1.0);
                                      final amplitude = p * 3.0;
                                      final freq = 2.0 + p * 6.0;
                                      final offset = sin(_shakeController.value * pi * 2 * freq) * amplitude;
                                      return Opacity(
                                        opacity: _textFadeIn.value,
                                        child: Transform.translate(
                                          offset: Offset(offset, 0),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      '即将判决',
                                      style: TextStyle(
                                        fontSize: 45,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        fontFamilyFallback: [
                                          'Noto Sans SC',
                                          'PingFang SC',
                                          'Microsoft YaHei',
                                          'sans-serif',
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                if (!_isExecuting) const SizedBox(height: 50),
                                const Spacer(),
                                SizedBox(
                                  height: _buttonHeight,
                                  width: _buttonWidth,
                                  child: GestureDetector(
                                    onTapDown:
                                        (_isExecuting ||
                                            (widget.decision.logicConditionType ==
                                                    'location' &&
                                                !_locationAvailable))
                                        ? null
                                        : (_) {
                                            _captureButtonCenter();
                                            _startExecution(false);
                                          },
                                    onTapUp: (_) {},
                                    onLongPressStart:
                                        (_isExecuting ||
                                            (widget.decision.logicConditionType ==
                                                    'location' &&
                                                !_locationAvailable))
                                        ? null
                                        : (_) {
                                            _captureButtonCenter();
                                            _startExecution(true);
                                          },
                                    onLongPressEnd:
                                        (_isExecuting ||
                                            (widget.decision.logicConditionType ==
                                                    'location' &&
                                                !_locationAvailable))
                                        ? null
                                        : (_) => _endLongPress(),
                                    child: KeyedSubtree(
                                      key: _buttonKey,
                                      child: _buildDecisionButton(
                                        opacity: _isExecuting ? _buttonFadeOut.value : 1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 190),
                              ] else ...[
                                const Spacer(),
                                const SizedBox(height: 50),
                                Opacity(
                                  opacity: _resultFadeIn.value,
                                  child: Text(
                                    _result,
                                    style: const TextStyle(
                                      fontSize: 45,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 3.6,
                                      color: Colors.white,
                                      fontFamilyFallback: [
                                        'Noto Sans SC',
                                        'PingFang SC',
                                        'Microsoft YaHei',
                                        'sans-serif',
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Opacity(
                                  opacity: _resultFadeIn.value,
                                  child: const Text(
                                    '已记录至决定历史',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 3.6,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Opacity(
                                  opacity: _resultFadeIn.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 12,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(
                                          context,
                                        ).popUntil((route) => route.isFirst);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        fixedSize: const Size(342, 68),
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: const Text(
                                        '返回主页',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 125),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 73,
                        child: AppSloganFooter(
                          showDivider: false,
                          textColor: footerTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDecisionButton({required double opacity}) {
    final isDisabled =
        widget.decision.logicConditionType == 'location' && !_locationAvailable;

    return Opacity(
      opacity: opacity,
      child: Container(
        width: _buttonWidth,
        height: _buttonHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_buttonRadius),
          border: Border.all(
            color: isDisabled
                ? const Color(0xFFD4D4D4)
                : const Color(0xFF577CFF),
            width: 2,
          ),
          gradient: isDisabled
              ? const LinearGradient(
                  colors: [Color(0xFFD5D5D5), Color(0xFFC6C6C6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [Color(0xFF5075FF), Color(0xFF2D5BFF)],
                ),
          boxShadow: [
            BoxShadow(
              color: (isDisabled
                      ? const Color(0xFFC6C6C6)
                      : const Color(0xFF2D5BFF))
                  .withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: opacity,
                child: SvgPicture.asset(
                  'figma_exports/icons/lightning.svg',
                  width: 64,
                  height: 64,
                ),
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: opacity,
                child: const Text(
                  '即刻判决',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3.6,
                    color: Colors.white,
                    height: 1,
                    fontFamilyFallback: [
                      'Noto Sans SC',
                      'PingFang SC',
                      'Microsoft YaHei',
                      'sans-serif',
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

  Color _colorFromCoverage({
    required Color baseColor,
    required Color targetColor,
    required Offset targetCenter,
    required double animationValue,
    required Size screenSize,
  }) {
    if (_buttonCenter == null) return baseColor;

    final progress = Curves.easeInOutCubic.transform(animationValue);
    final maxRadius = <double>[
      (_buttonCenter! - const Offset(0, 0)).distance,
      (_buttonCenter! - Offset(screenSize.width, 0)).distance,
      (_buttonCenter! - Offset(0, screenSize.height)).distance,
      (_buttonCenter! - screenSize.bottomRight(Offset.zero)).distance,
    ].reduce((a, b) => a > b ? a : b);

    final currentRadius = lerpDouble(_buttonWidth / 2, maxRadius * 1.18, progress)!;
    final distanceToText = (_buttonCenter! - targetCenter).distance;
    final blendRange = 300.0;
    final coverage = ((currentRadius - distanceToText + blendRange * 0.5) / blendRange)
        .clamp(0.0, 1.0);

    return Color.lerp(baseColor, targetColor, coverage)!;
  }
}

class _ExpandingDecisionBackgroundPainter extends CustomPainter {
  final double progress;
  final double darkCornerProgress;
  final Offset startCenter;
  final Offset endCenter;
  final Size screenSize;
  final double cornerRadius;

  const _ExpandingDecisionBackgroundPainter({
    required this.progress,
    required this.darkCornerProgress,
    required this.startCenter,
    required this.endCenter,
    required this.screenSize,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset.lerp(startCenter, endCenter, progress)!;
    final maxRadius = <double>[
      (startCenter - const Offset(0, 0)).distance,
      (startCenter - Offset(screenSize.width, 0)).distance,
      (startCenter - Offset(0, screenSize.height)).distance,
      (startCenter - Offset(screenSize.width, screenSize.height)).distance,
    ].reduce((a, b) => a > b ? a : b);

    final currentWidth = lerpDouble(
      _ExecutePageState._buttonWidth,
      maxRadius * 2.35,
      progress,
    )!;
    final currentHeight = lerpDouble(
      _ExecutePageState._buttonHeight,
      maxRadius * 2.35,
      progress,
    )!;
    final currentRadius = lerpDouble(
      cornerRadius,
      0,
      progress,
    )!.clamp(0.0, 9999.0);

    final rect = Rect.fromCenter(
      center: center,
      width: currentWidth,
      height: currentHeight,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(currentRadius));

    final lightColor = const Color(0xFF5075FF);
    final darkEdgeColor = Color.lerp(
      const Color(0xFF1E3D85),
      const Color(0xFF1A3578),
      darkCornerProgress,
    )!;

    final curvedDark = Curves.easeIn.transform(darkCornerProgress);
    final outerStop = lerpDouble(0.35, 0.28, curvedDark)!;

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [lightColor, lightColor, darkEdgeColor],
        stops: [0.0, 0.08, outerStop],
        transform: GradientRotation(lerpDouble(0, 0.78539816339, progress)!),
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _ExpandingDecisionBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.darkCornerProgress != darkCornerProgress ||
        oldDelegate.startCenter != startCenter ||
        oldDelegate.endCenter != endCenter ||
        oldDelegate.screenSize != screenSize;
  }
}
