import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/app_models.dart';
import '../../../data/repositories/decision_repository.dart';
import '../../../core/utils/algorithms.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    _loadDecisions();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _isGridView = prefs.getBool('isGridView') ?? false);
  }

  Future<void> _saveViewMode(bool isGrid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGridView', isGrid);
  }

  Future<void> _loadDecisions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final decisions = await _decisionRepo.getAllDecisions();
    final sorted = _sorter.sortDecisions(decisions);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Stack(
        children: [
          // Static background
          Container(color: Colors.white),
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.8),
                radius: 0.8,
                colors: [Colors.black.withOpacity(0.03), Colors.transparent],
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
                        child: _buildHLine(const Color(0xFF2D5BFF)),
                      ),
                      Positioned(
                        top: -40,
                        right: 17,
                        child: Container(
                          width: 255,
                          height: 255,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black.withOpacity(0.05),
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
                            const Text(
                              '决 v0.2 beta',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D5BFF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '即刻判决',
                              style: TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 1,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '享受当下',
                              style: TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D5BFF),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '由逻辑 终结纠结.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF002FA7),
                              ),
                            ),
                            const SizedBox(height: 36),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '我的决定',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
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
                            else if (_isGridView)
                              _buildGridView()
                            else ...[
                              _buildListView(),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildListCreateCard(),
                              ),
                            ],
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
          color.withOpacity(0.05),
          Colors.transparent,
        ],
      ),
    ),
  );

  Widget _buildToggleSwitch() {
    return GestureDetector(
      onTap: () {
        setState(() => _isGridView = !_isGridView);
        _saveViewMode(_isGridView);
      },
      child: Container(
        width: 74,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
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
                decoration: const BoxDecoration(
                  color: Colors.black,
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
                  color: _isGridView ? Colors.black : Colors.white,
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
                  color: _isGridView ? Colors.white : Colors.black,
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
              child: GestureDetector(
                onTap: () => _navigateToExecute(entry.value),
                child: _buildListCard(entry.value),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildListCard(Decision decision) {
    return Container(
      width: double.infinity,
      height: 106,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    decision.theme,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
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
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF1B1B1B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCreateCard() {
    return GestureDetector(
      onTap: _navigateToCreate,
      child: Container(
        width: double.infinity,
        height: 106,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
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
              Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFC6C6C6)),
            ],
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
        ..._decisions
            .map(
              (d) => GestureDetector(
                onTap: () => _navigateToExecute(d),
                child: _buildGridCard(d),
              ),
            )
            ,
        _buildGridCreateCard(),
      ],
    );
  }

  Widget _buildGridCard(Decision decision) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 20),
            Text(
              decision.theme,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${decision.optionGroups.length} 个选项组',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCreateCard() {
    return GestureDetector(
      onTap: _navigateToCreate,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '创建新决定',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateIconBox extends StatelessWidget {
  final bool gridSize;
  const _CreateIconBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: gridSize ? 48 : 56,
      height: gridSize ? 48 : 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Center(
        child: Icon(Icons.add, color: Colors.white, size: gridSize ? 22 : 24),
      ),
    );
  }
}
