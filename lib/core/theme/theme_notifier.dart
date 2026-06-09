import 'package:flutter/material.dart';
import '../../data/local/app_storage.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  ThemeNotifier() {
    _loadFromStorage();
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = _onPlatformBrightnessChanged;
  }

  void _onPlatformBrightnessChanged() {
    if (_themeMode == ThemeMode.system) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = null;
    super.dispose();
  }

  Future<void> _loadFromStorage() async {
    final isDark = await AppStorage.getDarkMode();
    _themeMode = isDark ? ThemeMode.system : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool enabled) async {
    _themeMode = enabled ? ThemeMode.system : ThemeMode.light;
    await AppStorage.saveDarkMode(enabled);
    notifyListeners();
  }
}
