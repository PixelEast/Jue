import 'package:flutter/material.dart';
import '../../data/local/app_storage.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeNotifier() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    _isDarkMode = await AppStorage.getDarkMode();
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await AppStorage.saveDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    await AppStorage.saveDarkMode(_isDarkMode);
    notifyListeners();
  }
}
