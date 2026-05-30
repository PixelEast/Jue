import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/models/app_models.dart';
import '../../../data/repositories/decision_repository.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../core/utils/algorithms.dart';
import '../../../core/utils/app_events.dart';
import '../../widgets/app_slogan_footer.dart';
import '../../widgets/frosted_back_button.dart';
import '../create/create_decision_page.dart';
import '../history/history_page.dart';

class ExecutePage extends StatefulWidget {
  final Decision decision;

  const ExecutePage({super.key, required this.decision});

  @override
  State<ExecutePage> createState() => _ExecutePageState();
}

class _ExecutePageState extends State<ExecutePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

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
    _animationController.forward(from: 0);
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
    final titleCenter = Offset(size.width / 2, _titleTop + (_titleFontSize / 2));
    final subtitleCenter = Offset(
      size.width / 2,
      _titleTop + _titleFontSize + _subtitleSpacing + (_subtitleFontSize / 2),
    );
    final footerCenter = Offset(
      size.width / 2,
      size.height - _footerBottom - (_footerApproxHeight / 2),
    );
    final isBlueState = _isExecuting || _showResult;
    final titleTextColor = isBlueState
        ? Colors.white
        : _colorFromCoverage(
            baseColor: Colors.black,
            targetColor: Colors.white,
            targetCenter: titleCenter,
          );
    final secondaryTextColor = isBlueState
        ? Colors.white.withValues(alpha: 0.86)
        : _colorFromCoverage(
            baseColor: const Color(0xFF5E5E5E),
            targetColor: Colors.white.withValues(alpha: 0.86),
            targetCenter: subtitleCenter,
          );
    final footerTextColor = isBlueState
        ? Colors.white.withValues(alpha: 0.86)
        : _colorFromCoverage(
            baseColor: const Color(0xFF5E5E5E),
            targetColor: Colors.white.withValues(alpha: 0.86),
            targetCenter: footerCenter,
          );

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) {
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
                          center: _buttonCenter!,
                          screenSize: size,
                          cornerRadius: _buttonRadius,
                        ),
                      ),
                    ),
                  ),
                SafeArea(
                  child: Stack(
                    children: [
                      if (!_isExecuting || _showResult)
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              FrostedBackButton(onTap: () => Navigator.pop(context)),
                              if (_showResult)
                                FrostedBackButton(
                                  icon: Icons.history,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const HistoryPage(),
                                      ),
                                    );
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
                            const SizedBox(height: 12),
                            Text(
                              '即刻判决 享受当下',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: secondaryTextColor,
                                letterSpacing: 10,
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
                              if (!_isExecuting) ...[
                                const SizedBox(height: 140),
                                GestureDetector(
                                  onTapDown:
                                      (widget.decision.logicConditionType ==
                                              'location' &&
                                          !_locationAvailable)
                                      ? null
                                      : (_) {
                                          _captureButtonCenter();
                                          _startExecution(false);
                                        },
                                  onTapUp: (_) {},
                                  onLongPressStart:
                                      (widget.decision.logicConditionType ==
                                              'location' &&
                                          !_locationAvailable)
                                      ? null
                                      : (_) {
                                          _captureButtonCenter();
                                          _startExecution(true);
                                        },
                                  onLongPressEnd:
                                      (widget.decision.logicConditionType ==
                                              'location' &&
                                          !_locationAvailable)
                                      ? null
                                      : (_) => _endLongPress(),
                                  child: KeyedSubtree(
                                    key: _buttonKey,
                                    child: _buildDecisionButton(
                                      opacity: 1 - Curves.easeOut.transform(
                                        _animationController.value,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else if (!_showResult) ...[
                                const SizedBox(height: 130),
                                const Text(
                                  '即将判决',
                                  style: TextStyle(
                                    fontSize: 45,
                                    fontWeight: FontWeight.w800,
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
                                const SizedBox(height: 50),
                                Text(
                                  _result,
                                  style: const TextStyle(
                                    fontSize: 45,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 3.6,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                   '已记录至历史决定',
                                   style: TextStyle(
                                     fontSize: 15,
                                     fontWeight: FontWeight.w400,
                                     letterSpacing: 3.6,
                                     color: Colors.white,
                                   ),
                                 ),
                                const Spacer(),
                                 Container(
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
  }) {
    if (_buttonCenter == null) return baseColor;

    final progress = Curves.easeInOutCubic.transform(_animationController.value);
    final maxRadius = <double>[
      (_buttonCenter! - const Offset(0, 0)).distance,
      (_buttonCenter! - Offset(MediaQuery.sizeOf(context).width, 0)).distance,
      (_buttonCenter! - Offset(0, MediaQuery.sizeOf(context).height)).distance,
      (_buttonCenter! - MediaQuery.sizeOf(context).bottomRight(Offset.zero)).distance,
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
  final Offset center;
  final Size screenSize;
  final double cornerRadius;

  const _ExpandingDecisionBackgroundPainter({
    required this.progress,
    required this.center,
    required this.screenSize,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final maxRadius = <double>[
      (center - const Offset(0, 0)).distance,
      (center - Offset(screenSize.width, 0)).distance,
      (center - Offset(0, screenSize.height)).distance,
      (center - Offset(screenSize.width, screenSize.height)).distance,
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

    final lightColor = Color.lerp(
      const Color(0xFF5075FF),
      const Color(0xFF4D74FF),
      progress,
    )!;
    final darkColor = Color.lerp(
      const Color(0xFF2D5BFF),
      const Color(0xFF2E4699),
      progress,
    )!;

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: lerpDouble(0.9, 1.45, progress)!,
        colors: [lightColor, darkColor],
        stops: const [0.0, 1.0],
        transform: GradientRotation(lerpDouble(0, 0.78539816339, progress)!),
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _ExpandingDecisionBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.center != center ||
        oldDelegate.screenSize != screenSize;
  }
}
