import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/app_models.dart';
import '../../../data/repositories/decision_repository.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../core/utils/algorithms.dart';

class ExecutePage extends StatefulWidget {
  final Decision decision;

  const ExecutePage({super.key, required this.decision});

  @override
  State<ExecutePage> createState() => _ExecutePageState();
}

class _ExecutePageState extends State<ExecutePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _isExecuting = false;
  bool _isLongPress = false;
  bool _showResult = false;
  String _result = '';
  int _pressDuration = 0;

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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 50.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startExecution(bool isLongPress) {
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
    final activeGroup = _logicEngine.getActiveGroup(widget.decision);
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
                        onPressed: () {},
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
                          onTapDown: (_) => _startExecution(false),
                          onTapUp: (_) {},
                          onLongPressStart: (_) => _startExecution(true),
                          onLongPressEnd: (_) => _endLongPress(),
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Container(
                                width: 200,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF002FA7),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF002FA7,
                                      ).withOpacity(0.3),
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
