import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls the app-wide theme mode. Persists selection via SharedPreferences.
class ThemeController extends ChangeNotifier {
  static const _prefKey = 'app_theme_mode';
  static const _colorPrefKey = 'app_primary_color_index';

  static const List<Color> availableColors = [
    Color(0xFF1E3BEA), // Default Blue
    Color(0xFF1BA462), // Green
    Color(0xFF7C4DFF), // Purple
    Color(0xFFFF8A00), // Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF00ACC1), // Cyan
    Color(0xFF5D4037), // Brown
  ];

  ThemeController._(this._mode, this._colorIndex);

  ThemeMode _mode;
  int _colorIndex;

  /// Creates a [ThemeController] and loads the persisted theme mode and color.
  static Future<ThemeController> create() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_prefKey);
    final savedColor = prefs.getInt(_colorPrefKey) ?? 0;

    ThemeMode mode;
    if (savedMode == 'dark') {
      mode = ThemeMode.dark;
    } else if (savedMode == 'light') {
      mode = ThemeMode.light;
    } else {
      mode = ThemeMode.system;
    }
    return ThemeController._(mode, savedColor % availableColors.length);
  }

  ThemeMode get themeMode => _mode;
  int get colorIndex => _colorIndex;
  Color get currentPrimaryColor => availableColors[_colorIndex];

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String value;
    if (mode == ThemeMode.dark) {
      value = 'dark';
    } else if (mode == ThemeMode.light) {
      value = 'light';
    } else {
      value = 'system';
    }
    await prefs.setString(_prefKey, value);
  }

  Future<void> setPrimaryColorIndex(int index) async {
    if (_colorIndex == index) return;
    _colorIndex = index % availableColors.length;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorPrefKey, _colorIndex);
  }

  Future<void> toggle() =>
      setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
}
