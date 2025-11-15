import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class StorageService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _selectedDeviceKey = 'selected_device';
  static const String _themeKey = 'theme_mode';

  StorageService._(this._prefs);

  static Future<StorageService> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService._(prefs);
  }

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _secureStorage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  Future<void> saveUser(User user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  User? getUser() {
    final userData = _prefs.getString(_userKey);
    if (userData == null) {
      return null;
    }
    try {
      final Map<String, dynamic> json =
          jsonDecode(userData) as Map<String, dynamic>;
      return User.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteUser() async {
    await _prefs.remove(_userKey);
  }

  Future<void> saveSelectedDevice(String deviceId) async {
    await _prefs.setString(_selectedDeviceKey, deviceId);
  }

  String? getSelectedDevice() {
    return _prefs.getString(_selectedDeviceKey);
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeKey, mode.toString());
  }

  ThemeMode getThemeMode() {
    final modeStr = _prefs.getString(_themeKey);
    if (modeStr == 'ThemeMode.dark') {
      return ThemeMode.dark;
    }
    if (modeStr == 'ThemeMode.light') {
      return ThemeMode.light;
    }
    return ThemeMode.system;
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs.clear();
  }
}
