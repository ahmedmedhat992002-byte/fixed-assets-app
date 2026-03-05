import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls the app-wide locale. Persists selection via SharedPreferences.
class LocaleController extends ChangeNotifier {
  static const _prefKey = 'app_locale';

  LocaleController._(this._locale);

  Locale _locale;

  /// Creates a [LocaleController] and loads the persisted locale.
  /// Call this after [WidgetsFlutterBinding.ensureInitialized()].
  static Future<LocaleController> create() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    final locale = saved != null ? Locale(saved) : const Locale('en');
    return LocaleController._(locale);
  }

  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }

  Future<void> setLanguageCode(String code) {
    if (code.isEmpty) return Future.value();
    return setLocale(Locale(code));
  }
}
