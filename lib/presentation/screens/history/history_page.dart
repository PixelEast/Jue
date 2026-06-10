import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors_helper.dart';
import '../../../data/models/app_models.dart';
import '../../../data/repositories/decision_repository.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../core/utils/app_events.dart';
import '../../../core/utils/algorithms.dart';
import '../../widgets/app_slogan_footer.dart';
import '../create/create_decision_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryRepository _historyRepo = HistoryRepository();
  final DecisionRepository _decisionRepo = DecisionRepository();
  final WeightCalculator _weightCalculator = WeightCalculator();
  final ScrollController _scrollController = ScrollController();
  List<HistoryRecord> _records = [];
  Map<String, bool> _canRemoveByRecordId = {};
  Map<String, bool> _recordOptionExistsById = {};
  int _totalCount = 0;
  Map<String, int> _dailyCounts = {};
  bool _isLoading = true;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    AppEvents.historyChanged.addListener(_loadData);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    AppEvents.historyChanged.removeListener(_loadData);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final records = await _historyRepo.getRecordsPage(0);
    final decisions = await _decisionRepo.getAllDecisions();
    final totalCount = await _historyRepo.getTotalCount();
    final dailyCounts = await _historyRepo.getDailyCounts();

    final canRemoveByRecordId = <String, bool>{};
    final recordOptionExistsById = <String, bool>{};
    _processRecords(records, decisions, canRemoveByRecordId, recordOptionExistsById);

    setState(() {
      _records = records;
      _canRemoveByRecordId = canRemoveByRecordId;
      _recordOptionExistsById = recordOptionExistsById;
      _totalCount = totalCount;
      _dailyCounts = dailyCounts;
      _currentPage = 1;
      _hasMore = records.length >= HistoryRepository.pageSize;
      _isLoading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final newRecords = await _historyRepo.getRecordsPage(_currentPage);
    final decisions = await _decisionRepo.getAllDecisions();
    final canRemoveByRecordId = Map<String, bool>.from(_canRemoveByRecordId);
    final recordOptionExistsById = Map<String, bool>.from(_recordOptionExistsById);
    _processRecords(newRecords, decisions, canRemoveByRecordId, recordOptionExistsById);

    setState(() {
      _records.addAll(newRecords);
      _canRemoveByRecordId = canRemoveByRecordId;
      _recordOptionExistsById = recordOptionExistsById;
      _currentPage++;
      _hasMore = newRecords.length >= HistoryRepository.pageSize;
      _isLoadingMore = false;
    });
  }

  void _processRecords(
    List<HistoryRecord> records,
    List<Decision> decisions,
    Map<String, bool> canRemoveByRecordId,
    Map<String, bool> recordOptionExistsById,
  ) {
    for (final record in records) {
      final decision = decisions.cast<Decision?>().firstWhere(
        (d) => d?.id == record.decisionId,
        orElse: () => null,
      );

      if (decision == null) {
        canRemoveByRecordId[record.id] = false;
        recordOptionExistsById[record.id] = false;
        continue;
      }

      final group = decision.optionGroups.cast<OptionGroup?>().firstWhere(
        (g) => g?.name == record.optionGroupName,
        orElse: () => null,
      );

      if (group == null) {
        canRemoveByRecordId[record.id] = false;
        recordOptionExistsById[record.id] = false;
        continue;
      }

      final matchingOptionCount = group.options
          .where((o) => o.name == record.result)
          .length;
      if (matchingOptionCount == 0) {
        canRemoveByRecordId[record.id] = false;
        recordOptionExistsById[record.id] = false;
        continue;
      }

      recordOptionExistsById[record.id] = true;
      canRemoveByRecordId[record.id] = group.options.length > 1;
    }
  }

  Future<void> _updateFeedback(String id, String feedback) async {
    final record = _records.firstWhere((r) => r.id == id);
    if (record.feedback != 'none') return;

    final decision = await _decisionRepo.getDecisionById(record.decisionId);
    if (decision == null) return;

    final groupIndex = decision.optionGroups.indexWhere(
      (g) => g.name == record.optionGroupName,
    );
    if (groupIndex == -1) return;

    final group = decision.optionGroups[groupIndex];
    final optionIndex = group.options.indexWhere(
      (o) => o.name == record.result,
    );
    if (optionIndex == -1) return;

    if (feedback == 'removed' && group.options.length == 1) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('无法移除'),
          content: const Text('这是此决定中唯一一个剩余的选项了，你不能再移除它了。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateDecisionPage(
                      initialDecision: decision,
                      isEditing: true,
                    ),
                  ),
                );
                if (mounted) {
                  _loadData();
                }
              },
              child: const Text('去编辑'),
            ),
          ],
        ),
      );
      return;
    }

    _weightCalculator.applyFeedback(
      group.options[optionIndex],
      feedback,
      group,
    );
    await _decisionRepo.saveDecision(decision);
    AppEvents.notifyDecisionsChanged();
    await _historyRepo.updateFeedback(id, feedback);
    AppEvents.notifyHistoryChanged();
    _loadData();
  }

  String _formatSavedTime(int count) {
    final hours = count * 10 / 60;
    if (hours < 10) {
      return hours.toStringAsFixed(1);
    }
    return hours.round().toString();
  }

  String _formatRecordTime(DateTime dateTime) {
    return '${dateTime.month}月${dateTime.day}日, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColorsHelper.scaffoldBackground(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 100, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '定睛回看',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColorsHelper.secondaryText(context),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: AppColorsHelper.primaryText(context),
                              letterSpacing: 0,
                              height: 1.1,
                            ),
                            children: const [
                              TextSpan(text: '历史'),
                              TextSpan(text: '决定'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: _buildStatsCard(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: const SizedBox(height: 50),
                ),
                if (_records.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            Icons.history_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无历史记录',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    sliver: SliverList.builder(
                      itemCount: _records.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _records.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        final isLast = index == _records.length - 1 && !_isLoadingMore;
                        return _buildTimelineItem(_records[index], isLast, index);
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                      child: const AppSloganFooter(),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildStatsCard() {
    final isDark = AppColorsHelper.isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFEAEAEA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '累积帮你决定了',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColorsHelper.secondaryText(context),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                          Text(
                            '$_totalCount',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColorsHelper.decisionCardText(context),
                            ),
                          ),
                      Text(
                        '次决定',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColorsHelper.decisionCardText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: const Color(0xFFC6C6C6).withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_formatSavedTime(_totalCount)}小时',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColorsHelper.primaryText(context),
                        ),
                      ),
                      Text(
                        '已节省',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColorsHelper.primaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 60, child: _buildBarChart()),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final now = DateTime.now();
    final days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final counts = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final key = date.toString().substring(0, 10);
      return _dailyCounts[key] ?? 0;
    });
    final maxCount = counts.isEmpty
        ? 1
        : counts.reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final height = maxCount > 0 ? (counts[i] / maxCount) * 40.0 : 0.0;
        final date = now.subtract(Duration(days: 6 - i));
        final isToday =
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
        final distanceFromToday = 6 - i;
        Color barColor;
        if (distanceFromToday == 0) {
          barColor = AppColorsHelper.decisionCardText(context);
        } else if (distanceFromToday == 1) {
          barColor = const Color(0xFF6392EE);
        } else if (distanceFromToday == 2) {
          barColor = const Color(0xFFADC4F3);
        } else {
          barColor = const Color(0xFFEEEEEE);
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 34,
              height: height > 0 ? height : 2,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isToday ? '今天' : days[i],
              style: TextStyle(
                fontSize: 8,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                color: isToday
                    ? const Color(0xFF004EE8)
                    : const Color(0xFF5E5E5E),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTimelineItem(HistoryRecord record, bool isLast, int index) {
    final optionStillExists = _recordOptionExistsById[record.id] ?? true;
    final canAct = record.feedback == 'none' && optionStillExists;
    final canRemove = _canRemoveByRecordId[record.id] ?? false;
    final isLatest = _records.isNotEmpty && identical(record, _records.first);
    final isDark = AppColorsHelper.isDark(context);
    return Stack(
      children: [
        if (!isLast)
          Positioned(
            left: 5,
            top: 12,
            bottom: 0,
            child: Container(
              width: 2,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : const Color(0xFFC6C6C6).withValues(alpha: 0.3),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 50),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black : Colors.white,
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatRecordTime(record.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : const Color(0xFF5E5E5E),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Text(
                      '判决：${record.decisionTheme}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF000000),
                        height: 1.2,
                      ),
                    ),
                    Text(
                      '（${record.optionGroupName}）',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF000000),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252525) : const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFEAEAEA),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '判决结果:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : const Color(0xFF5E5E5E),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        record.result,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isLatest
                              ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF004EE8))
                              : (isDark ? Colors.white : const Color(0xFF1B1B1B)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: const Color(
                                0xFFC6C6C6,
                              ).withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: canAct
                                      ? () => _updateFeedback(record.id, 'like')
                                      : null,
                                  child: SvgPicture.asset(
                                    'figma_exports/icons/Like.svg',
                                    height: 15,
                                    colorFilter: ColorFilter.mode(
                                      record.feedback == 'like'
                                          ? AppColorsHelper.decisionCardText(context)
                                          : (canAct
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF475569)),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 28),
                                GestureDetector(
                                  onTap: canAct
                                      ? () => _updateFeedback(
                                          record.id,
                                          'dislike',
                                        )
                                      : null,
                                  child: SvgPicture.asset(
                                    'figma_exports/icons/Dislike.svg',
                                    height: 15,
                                    colorFilter: ColorFilter.mode(
                                      record.feedback == 'dislike'
                                          ? const Color(0xFFE49B87)
                                          : (canAct
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF475569)),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: canAct && canRemove
                                  ? () => _updateFeedback(record.id, 'removed')
                                  : null,
                              child: SvgPicture.asset(
                                'figma_exports/icons/Remove.svg',
                                height: 15,
                                colorFilter: ColorFilter.mode(
                                  record.feedback == 'removed'
                                      ? const Color(0xFFBA1A1A)
                                      : (canAct && canRemove
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF475569)),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    ],
    );
  }
}
