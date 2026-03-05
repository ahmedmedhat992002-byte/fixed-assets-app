import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls the app-wide theme mode. Persists selection via SharedPreferences.
class ThemeController extends ChangeNotifier {
  static const _prefKey = 'app_theme_mode';

  ThemeController._(this._mode);

  ThemeMode _mode;

  /// Creates a [ThemeController] and loads the persisted theme mode.
  /// Call this after [WidgetsFlutterBinding.ensureInitialized()].
  static Future<ThemeController> create() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    ThemeMode mode;
    if (saved == 'dark') {
      mode = ThemeMode.dark;
    } else if (saved == 'light') {
      mode = ThemeMode.light;
    } else {
      mode = ThemeMode.system;
    }
    return ThemeController._(mode);
  }

  ThemeMode get themeMode => _mode;

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

  Future<void> toggle() =>
      setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
}
