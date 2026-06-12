import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors_helper.dart';
import '../../../core/utils/widget_service.dart';
import '../../../data/models/app_models.dart';
import '../../../data/repositories/decision_repository.dart';
import '../../../core/utils/algorithms.dart';
import '../../../core/utils/app_events.dart';
import '../../widgets/app_slogan_footer.dart';
import '../executer/execute_page.dart';
import '../create/create_decision_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DecisionRepository _decisionRepo = DecisionRepository();
  final DecisionSorter _sorter = DecisionSorter();
  List<Decision> _decisions = [];
  bool _isGridView = false;
  bool _displayGridView = false;
  bool _isLoading = true;
  bool _isSwitchAnimating = false;
  bool _contentVisible = true;

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    _loadDecisions();
    AppEvents.decisionsChanged.addListener(_loadDecisions);
  }

  @override
  void dispose() {
    AppEvents.decisionsChanged.removeListener(_loadDecisions);
    super.dispose();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final isGrid = prefs.getBool('isGridView') ?? false;
    setState(() {
      _isGridView = isGrid;
      _displayGridView = isGrid;
    });
  }

  Future<void> _saveViewMode(bool isGrid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGridView', isGrid);
  }

  Future<void> _loadDecisions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final decisions = await _decisionRepo.getAllDecisions();
    final nonDraftDecisions = decisions.where((d) => !d.isDraft).toList();
    final sorted = _sorter.sortDecisions(nonDraftDecisions);
    if (!mounted) return;
    setState(() {
      _decisions = sorted;
      _isLoading = false;
    });
  }

  void _navigateToCreate() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CreateDecisionPage()),
    );
    if (result == true) _loadDecisions();
  }

  void _navigateToExecute(Decision decision) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExecutePage(decision: decision)),
    ).then((_) => _loadDecisions());
  }

  void _showWidgetMenu(Decision decision) {
    final isDark = AppColorsHelper.isDark(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                decision.theme,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColorsHelper.primaryText(context),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.widgets_outlined,
                color: AppColorsHelper.primaryText(context),
              ),
              title: Text(
                '添加到桌面小组件',
                style: TextStyle(
                  color: AppColorsHelper.primaryText(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '在桌面快速执行此决定',
                style: TextStyle(
                  color: AppColorsHelper.secondaryText(context),
                  fontSize: 12,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final messenger = ScaffoldMessenger.of(context);
                await WidgetService().updateWidgetData(
                  decisionId: decision.id,
                  decisionTheme: decision.theme,
                );
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('已将"${decision.theme}"添加到桌面小组件'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                color: AppColorsHelper.primaryText(context),
              ),
              title: Text(
                '编辑此决定',
                style: TextStyle(
                  color: AppColorsHelper.primaryText(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateDecisionPage(
                      initialDecision: decision,
                      isEditing: true,
                    ),
                  ),
                ).then((_) => _loadDecisions());
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _animateToggleViewMode() async {
    if (_isSwitchAnimating) return;

    final nextMode = !_isGridView;
    setState(() {
      _isSwitchAnimating = true;
      _isGridView = nextMode;
      _contentVisible = false;
    });
    await _saveViewMode(nextMode);

    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    setState(() {
      _displayGridView = nextMode;
    });

    await Future.delayed(const Duration(milliseconds: 20));
    if (!mounted) return;

    setState(() {
      _contentVisible = true;
    });

    await Future.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;

    setState(() {
      _isSwitchAnimating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColorsHelper.scaffoldBackground(context);
    final primaryTextColor = AppColorsHelper.primaryText(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Container(color: bgColor),
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.8),
                radius: 0.8,
                colors: [
                  Colors.black.withValues(alpha: 0.03),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Scrollable content (includes decorative elements)
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Stack(
                    children: [
                      // Decorative elements that scroll with content
                      Positioned(
                        top: 80,
                        left: 0,
                        right: 0,
                        child: _buildHLine(Colors.black),
                      ),
                      Positioned(
                        top: 192,
                        left: 0,
                        right: 0,
                                child: _buildHLine(AppColorsHelper.brandColor),
                      ),
                      Positioned(
                        top: -40,
                        right: 17,
                        child: Container(
                          width: 255,
                          height: 255,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.05),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      // Main content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 130, 32, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '决 ${AppConstants.appVersion}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColorsHelper.brandColorSoft(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '即刻判决',
                              style: TextStyle(
                                fontSize: 61,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                                letterSpacing: 1,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '享受当下',
                              style: TextStyle(
                                fontSize: 61,
                                fontWeight: FontWeight.bold,
                                color: AppColorsHelper.brandColorSoft(context),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '当他人还在为吃什么等问题烦恼时，你已经继续前行，专注于你的生活吧！把琐碎的决定交给我们！',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF5E5E5E),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 36),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '我的决定',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextColor,
                                  ),
                                ),
                                _buildToggleSwitch(),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_isLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 160),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                                child: _contentVisible
                                    ? KeyedSubtree(
                                        key: ValueKey(
                                          _displayGridView
                                              ? 'grid-view'
                                              : 'list-view',
                                        ),
                                        child: _displayGridView
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _buildGridView(),
                                                  const SizedBox(height: 32),
                                                  const AppSloganFooter(),
                                                ],
                                              )
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _buildListView(),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 16,
                                                        ),
                                                    child:
                                                        _buildListCreateCard(),
                                                  ),
                                                  const SizedBox(height: 32),
                                                  const AppSloganFooter(),
                                                ],
                                              ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHLine(Color color) => Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ),
    ),
  );

  Widget _buildToggleSwitch() {
    final isDark = AppColorsHelper.isDark(context);
    return GestureDetector(
      onTap: _animateToggleViewMode,
      child: Container(
        width: 74,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: _isGridView
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.all(5),
                alignment: Alignment.center,
                child: Icon(
                  Icons.view_list,
                  size: 18,
                  color: _isGridView
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.black : Colors.white),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.all(5),
                alignment: Alignment.center,
                child: Icon(
                  Icons.grid_view,
                  size: 18,
                  color: _isGridView
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      children: _decisions
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(32),
                child: InkWell(
                  onTap: () => _navigateToExecute(entry.value),
                  onLongPress: () => _showWidgetMenu(entry.value),
                  borderRadius: BorderRadius.circular(32),
                  splashColor: Colors.black.withValues(alpha: 0.05),
                  highlightColor: Colors.black.withValues(alpha: 0.02),
                  child: _buildListCard(entry.value),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildListCard(Decision decision) {
    final isDark = AppColorsHelper.isDark(context);
    final primaryTextColor = AppColorsHelper.primaryText(context);
    return Ink(
      width: double.infinity,
      height: 106,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColorsHelper.iconBackground(context),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
              ),
              child: Icon(Icons.bolt,
                  color: AppColorsHelper.iconForeground(context), size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    decision.theme,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${decision.optionGroups.length} 个选项组',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.white : const Color(0xFF1B1B1B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCreateCard() {
    final isDark = AppColorsHelper.isDark(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        onTap: _navigateToCreate,
        borderRadius: BorderRadius.circular(32),
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.04),
        child: Ink(
          width: double.infinity,
          height: 106,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.black,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(25),
            child: Row(
              children: [
                _CreateIconBox(),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    '创建新决定',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFFC6C6C6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.95,
      children: [
        ..._decisions.map(
          (d) => Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(32),
            child: InkWell(
              onTap: () => _navigateToExecute(d),
              onLongPress: () => _showWidgetMenu(d),
              borderRadius: BorderRadius.circular(32),
              splashColor: Colors.black.withValues(alpha: 0.05),
              highlightColor: Colors.black.withValues(alpha: 0.02),
              child: _buildGridCard(d),
            ),
          ),
        ),
        _buildGridCreateCard(),
      ],
    );
  }

  Widget _buildGridCard(Decision decision) {
    final isDark = AppColorsHelper.isDark(context);
    final primaryTextColor = AppColorsHelper.primaryText(context);
    return Ink(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColorsHelper.iconBackground(context),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Icon(Icons.bolt,
                  color: AppColorsHelper.iconForeground(context), size: 24),
            ),
            const SizedBox(height: 20),
            Text(
              decision.theme,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${decision.optionGroups.length} 个选项组',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCreateCard() {
    final isDark = AppColorsHelper.isDark(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        onTap: _navigateToCreate,
        borderRadius: BorderRadius.circular(32),
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.black,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _CreateIconBox(),
                const SizedBox(height: 20),
                const Text(
                  '创建新决定',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateIconBox extends StatelessWidget {
  const _CreateIconBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: const Center(
        child: Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}
