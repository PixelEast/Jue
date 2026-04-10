import 'package:flutter/material.dart';
import '../../../data/models/app_models.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../core/utils/app_events.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryRepository _historyRepo = HistoryRepository();
  List<HistoryRecord> _records = [];
  int _totalCount = 0;
  Map<String, int> _dailyCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    AppEvents.historyChanged.addListener(_loadData);
  }

  @override
  void dispose() {
    AppEvents.historyChanged.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final records = await _historyRepo.getAllRecords();
    final totalCount = await _historyRepo.getTotalCount();
    final dailyCounts = await _historyRepo.getDailyCounts();
    setState(() {
      _records = records;
      _totalCount = totalCount;
      _dailyCounts = dailyCounts;
      _isLoading = false;
    });
  }

  Future<void> _updateFeedback(String id, String feedback) async {
    await _historyRepo.updateFeedback(id, feedback);
    _loadData();
  }

  String _formatSavedTime(int count) {
    final hours = count * 10 / 60;
    if (hours < 10) {
      return hours.toStringAsFixed(1);
    }
    return hours.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 79, 32, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '历史决定',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Column(
                  children: [
                    // Stats card (x=32, y=189, w=326, h=211, rx=32)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_totalCount',
                                      style: const TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const Text(
                                      '次决定',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF5E5E5E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 0.61,
                                height: 24,
                                color: const Color(
                                  0xFFC6C6C6,
                                ).withValues(alpha: 0.3),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: _formatSavedTime(_totalCount),
                                            style: const TextStyle(
                                              fontSize: 42,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF004EE8),
                                            ),
                                          ),
                                          const TextSpan(
                                            text: '小时',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF004EE8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Text(
                                      '已节省',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF5E5E5E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(height: 60, child: _buildBarChart()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '决定时间线',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_records.isEmpty)
                      Container(
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
                      )
                    else
                      _buildTimeline(),
                  ],
                ),
            ],
          ),
        ),
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final height = maxCount > 0 ? (counts[i] / maxCount) * 40.0 : 0.0;
        final isToday = i == 6;
        return Column(
          children: [
            Container(
              width: 35.43,
              height: height > 0 ? height : 2,
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFF004EE8)
                    : const Color(0xFFC6C6C6).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              days[i],
              style: TextStyle(
                fontSize: 11,
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

  Widget _buildTimeline() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final isLast = index == _records.length - 1;
        return _buildTimelineItem(_records[index], isLast);
      },
    );
  }

  Widget _buildTimelineItem(HistoryRecord record, bool isLast) {
    final isToday =
        record.dateOnly.day == DateTime.now().day &&
        record.dateOnly.month == DateTime.now().month;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            // Timeline dot (x=42, w=12, h=12, rx=6)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isToday ? Colors.black : const Color(0xFFC6C6C6),
                shape: BoxShape.circle,
              ),
            ),
            // Timeline line (x=48, w=2)
            Container(
              width: 2,
              height: isLast ? 100 : 200,
              decoration: isLast
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFC6C6C6).withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    )
                  : null,
              color: isLast
                  ? null
                  : const Color(0xFFC6C6C6).withValues(alpha: 0.3),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // Record card (x=64, w=294, h≈165, rx=16)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.createdAt.year}-${record.createdAt.month.toString().padLeft(2, '0')}-${record.createdAt.day.toString().padLeft(2, '0')} ${record.createdAt.hour.toString().padLeft(2, '0')}:${record.createdAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5E5E5E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  record.decisionTheme,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '判决：${record.result}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF004EE8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _updateFeedback(
                        record.id,
                        record.feedback == 'like' ? 'none' : 'like',
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.thumb_up_outlined,
                            size: 20,
                            color: record.feedback == 'like'
                                ? const Color(0xFF004EE8)
                                : const Color(0xFF231815),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '点赞',
                            style: TextStyle(
                              fontSize: 11,
                              color: record.feedback == 'like'
                                  ? const Color(0xFF004EE8)
                                  : const Color(0xFF231815),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: () => _updateFeedback(
                        record.id,
                        record.feedback == 'dislike' ? 'none' : 'dislike',
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.thumb_down_outlined,
                            size: 20,
                            color: record.feedback == 'dislike'
                                ? const Color(0xFFE49B87)
                                : const Color(0xFF231815),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '点踩',
                            style: TextStyle(
                              fontSize: 11,
                              color: record.feedback == 'dislike'
                                  ? const Color(0xFFE49B87)
                                  : const Color(0xFF231815),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: () => _updateFeedback(
                        record.id,
                        record.feedback == 'removed' ? 'none' : 'removed',
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.close,
                            size: 20,
                            color: Color(0xFF231815),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '移除',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF231815),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
