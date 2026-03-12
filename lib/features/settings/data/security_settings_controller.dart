import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/auth/biometric_service.dart';

class SecuritySettingsController extends ChangeNotifier {
  static const _keyRememberMe = 'security_remember_me';
  static const _keyFaceId = 'security_face_id';
  static const _keyBiometricId = 'security_biometric_id';
  static const _keyGoogleAuth = 'security_google_auth';
  static const _keyPin = 'security_pin';

  final SharedPreferences _prefs;
  final BiometricService _biometricService;

  SecuritySettingsController._(this._prefs, this._biometricService) {
    _rememberMe = _prefs.getBool(_keyRememberMe) ?? true;
    _faceId = _prefs.getBool(_keyFaceId) ?? true;
    _biometricId = _prefs.getBool(_keyBiometricId) ?? true;
    _googleAuth = _prefs.getBool(_keyGoogleAuth) ?? false;
    _pin = _prefs.getString(_keyPin) ?? '';
  }

  static Future<SecuritySettingsController> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SecuritySettingsController._(prefs, BiometricService());
  }

  late bool _rememberMe;
  late bool _faceId;
  late bool _biometricId;
  late bool _googleAuth;
  late String _pin;

  bool get rememberMe => _rememberMe;
  bool get faceId => _faceId;
  bool get biometricId => _biometricId;
  bool get googleAuth => _googleAuth;
  String get pin => _pin;

  void setRememberMe(bool value) {
    _rememberMe = value;
    _prefs.setBool(_keyRememberMe, value);
    notifyListeners();
  }

  Future<bool> setBiometricId(bool value) async {
    if (value) {
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to enable Biometric ID',
      );
      if (!authenticated) return false;
    }
    _biometricId = value;
    await _prefs.setBool(_keyBiometricId, value);
    notifyListeners();
    return true;
  }

  Future<bool> setFaceId(bool value) async {
    if (value) {
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to enable Face ID',
      );
      if (!authenticated) return false;
    }
    _faceId = value;
    await _prefs.setBool(_keyFaceId, value);
    notifyListeners();
    return true;
  }

  void setGoogleAuth(bool value) {
    _googleAuth = value;
    _prefs.setBool(_keyGoogleAuth, value);
    notifyListeners();
  }

  Future<void> setPin(String value) async {
    _pin = value;
    await _prefs.setString(_keyPin, value);
    notifyListeners();
  }
}
