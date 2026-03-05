import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsController extends ChangeNotifier {
  static const _keyGeneral = 'notif_general';
  static const _keySound = 'notif_sound';
  static const _keyVibrate = 'notif_vibrate';
  static const _keySpecialOffers = 'notif_special_offers';
  static const _keyPromo = 'notif_promo';
  static const _keyAppUpdates = 'notif_app_updates';
  static const _keyNewService = 'notif_new_service';
  static const _keyNewTips = 'notif_new_tips';

  final SharedPreferences _prefs;

  NotificationSettingsController._(this._prefs) {
    _general = _prefs.getBool(_keyGeneral) ?? true;
    _sound = _prefs.getBool(_keySound) ?? true;
    _vibrate = _prefs.getBool(_keyVibrate) ?? true;
    _specialOffers = _prefs.getBool(_keySpecialOffers) ?? false;
    _promoAndDiscount = _prefs.getBool(_keyPromo) ?? false;
    _appUpdates = _prefs.getBool(_keyAppUpdates) ?? true;
    _newService = _prefs.getBool(_keyNewService) ?? false;
    _newTips = _prefs.getBool(_keyNewTips) ?? false;
  }

  static Future<NotificationSettingsController> create() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettingsController._(prefs);
  }

  late bool _general;
  late bool _sound;
  late bool _vibrate;
  late bool _specialOffers;
  late bool _promoAndDiscount;
  late bool _appUpdates;
  late bool _newService;
  late bool _newTips;

  bool get general => _general;
  bool get sound => _sound;
  bool get vibrate => _vibrate;
  bool get specialOffers => _specialOffers;
  bool get promoAndDiscount => _promoAndDiscount;
  bool get appUpdates => _appUpdates;
  bool get newService => _newService;
  bool get newTips => _newTips;

  void setGeneral(bool value) {
    _general = value;
    notifyListeners();
  }

  void setSound(bool value) {
    _sound = value;
    notifyListeners();
  }

  void setVibrate(bool value) {
    _vibrate = value;
    notifyListeners();
  }

  void setSpecialOffers(bool value) {
    _specialOffers = value;
    notifyListeners();
  }

  void setPromo(bool value) {
    _promoAndDiscount = value;
    notifyListeners();
  }

  void setAppUpdates(bool value) {
    _appUpdates = value;
    notifyListeners();
  }

  void setNewService(bool value) {
    _newService = value;
    notifyListeners();
  }

  void setNewTips(bool value) {
    _newTips = value;
    notifyListeners();
  }

  Future<void> saveSettings() async {
    await _prefs.setBool(_keyGeneral, _general);
    await _prefs.setBool(_keySound, _sound);
    await _prefs.setBool(_keyVibrate, _vibrate);
    await _prefs.setBool(_keySpecialOffers, _specialOffers);
    await _prefs.setBool(_keyPromo, _promoAndDiscount);
    await _prefs.setBool(_keyAppUpdates, _appUpdates);
    await _prefs.setBool(_keyNewService, _newService);
    await _prefs.setBool(_keyNewTips, _newTips);
  }
}
