import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'presentation/screens/home/home_page.dart';
import 'presentation/screens/history/history_page.dart';
import 'presentation/screens/settings/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  runApp(const JueApp());
}

class JueApp extends StatelessWidget {
  const JueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '决',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: const Color(0xFF002FA7),
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          displayMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Color(0xFF002FA7),
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.black,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF8E8E93),
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: Color(0xFF8E8E93),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [HomePage(), HistoryPage(), SettingsPage()];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bottomInset + 120,
            child: Container(color: Colors.white),
          ),
          ...List.generate(_pages.length, (index) {
            final isActive = index == _currentIndex;
            final inactiveOffset = isActive
                ? Offset.zero
                : (index < _currentIndex
                      ? const Offset(-0.04, 0)
                      : const Offset(0.04, 0));

            return IgnorePointer(
              ignoring: !isActive,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                opacity: isActive ? 1 : 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  offset: isActive ? Offset.zero : inactiveOffset,
                  child: KeyedSubtree(
                    key: ValueKey('main_page_$index'),
                    child: _pages[index],
                  ),
                ),
              ),
            );
          }),
          // Floating nav bar - uses IgnorePointer around it to prevent blocking page content
          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: _buildBottomNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 50,
                offset: const Offset(0, 25),
              ),
            ],
          ),
          // Use Material + InkWell for better touch response
          child: Material(
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home,
                  label: '主页',
                  isActive: _currentIndex == 0,
                  onTap: () => _onTabTapped(0),
                ),
                _buildNavItem(
                  icon: _currentIndex == 1
                      ? Icons.history
                      : Icons.history_outlined,
                  label: '历史',
                  isActive: _currentIndex == 1,
                  onTap: () => _onTabTapped(1),
                ),
                _buildNavItem(
                  icon: Icons.settings,
                  label: '设置',
                  isActive: _currentIndex == 2,
                  onTap: () => _onTabTapped(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.black : const Color(0xFF8E8E93),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.black : const Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
