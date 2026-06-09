import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:ui';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/utils/notification_service.dart';
import 'core/utils/notification_scheduler.dart';
import 'presentation/screens/home/home_page.dart';
import 'presentation/screens/history/history_page.dart';
import 'presentation/screens/settings/settings_page.dart';

final ThemeNotifier themeNotifier = ThemeNotifier();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await NotificationService().init();
  NotificationScheduler().start();

  runApp(const JueApp());
}

class JueApp extends StatefulWidget {
  const JueApp({super.key});

  @override
  State<JueApp> createState() => _JueAppState();
}

class _JueAppState extends State<JueApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
    final brightness = themeNotifier.isDarkMode
        ? Brightness.light
        : Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: brightness,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '决',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const ScrollBehavior().copyWith(physics: const BouncingScrollPhysics()),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        final statusBarBrightness = brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: statusBarBrightness,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: statusBarBrightness,
            systemNavigationBarContrastEnforced: false,
          ),
          child: child!,
        );
      },
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static void switchToTab(int index) {
    _MainScreenState._instance?._onTabTapped(index);
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static _MainScreenState? _instance;
  int _currentIndex = 0;

  final List<Widget> _pages = const [HomePage(), HistoryPage(), SettingsPage()];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _instance = this;
    themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final isDark = themeNotifier.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bottomInset + 120,
            child: Container(color: bgColor),
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
    final isDark = themeNotifier.isDarkMode;
    final navBgColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.80);
    final navBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
    final navShadowColor = isDark
        ? Colors.black.withValues(alpha: 0.40)
        : Colors.black.withValues(alpha: 0.25);
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: navBgColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: navBorderColor),
            boxShadow: [
              BoxShadow(
                color: navShadowColor,
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
    final isDark = themeNotifier.isDarkMode;
    final activeColor = isDark ? Colors.white : Colors.black;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF8E8E93);
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
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
