import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final StorageService _storage;
  AuthService? _authService;

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._storage);

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;

  Future<AuthService> _getAuthService() async {
    return _authService ??= await AuthService.getInstance();
  }

  Future<void> loadUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _token = await _storage.getToken();
      _user = _storage.getUser();

      if (_token != null && _user == null) {
        final authService = await _getAuthService();
        final res = await authService.refreshProfile();
        if (res.success && res.data != null) {
          _user = res.data;
        } else if (!res.success) {
          _error = res.message ?? 'Failed to load profile';
        }
      }
    } catch (_) {
      _error = 'Failed to load user';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(
    String email,
    String password,
    String fullName,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authService = await _getAuthService();
      final res = await authService.register(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (!res.success || res.data == null) {
        _error = res.message ?? 'Registration failed';
        return false;
      }

      _user = res.data;
      _token = await _storage.getToken();
      return true;
    } catch (_) {
      _error = 'Registration failed';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authService = await _getAuthService();
      final res = await authService.login(
        email: email,
        password: password,
      );

      if (!res.success || res.data == null) {
        _error = res.message ?? 'Login failed';
        return false;
      }

      _user = res.data;
      _token = await _storage.getToken();
      return true;
    } catch (_) {
      _error = 'Login failed';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await ApiService.getInstance();
      final res = await api.updateProfile(data);

      if (!res.success || res.data == null) {
        _error = res.message ?? 'Update failed';
        return;
      }

      Map<String, dynamic>? json;
      if (res.data is Map<String, dynamic>) {
        json = res.data as Map<String, dynamic>;
      } else if (res.data is Map) {
        json = Map<String, dynamic>.from(res.data as Map);
      }

      if (json == null) {
        _error = 'Invalid user data';
        return;
      }

      final updatedUser = User.fromJson(json);
      _user = updatedUser;
      await _storage.saveUser(updatedUser);
    } catch (_) {
      _error = 'Update failed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateFCMToken(String fcmToken) async {
    try {
      final api = await ApiService.getInstance();
      await api.updateFCMToken(fcmToken);
    } catch (_) {}
  }

  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authService = await _getAuthService();
      await authService.logout();
      _user = null;
      _token = null;
    } catch (_) {
      _error = 'Failed to logout';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
