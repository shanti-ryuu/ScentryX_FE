import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final StorageService _storage;
  final FirebaseService _firebaseService;
  AuthService? _authService;

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  String? _pendingVerificationEmail;
  String? _pendingVerificationToken;
  String? _pendingVerificationVerifyEndpoint;

  AuthProvider(this._storage, this._firebaseService);

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  String? get pendingVerificationToken => _pendingVerificationToken;
  String? get pendingVerificationVerifyEndpoint =>
      _pendingVerificationVerifyEndpoint;

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
    _pendingVerificationEmail = null;
    _pendingVerificationToken = null;
    _pendingVerificationVerifyEndpoint = null;
    notifyListeners();

    try {
      final authService = await _getAuthService();
      final res = await authService.register(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (!res.success || res.data == null) {
        final message = res.message ?? 'Registration failed';
        final inferredEmail = _extractPendingEmail(res.raw);
        final lowerMessage = message.toLowerCase();
        final mentionsVerification =
            lowerMessage.contains('verify') ||
            lowerMessage.contains('verification') ||
            lowerMessage.contains('already registered');

        if (inferredEmail != null) {
          _pendingVerificationEmail = inferredEmail;
        } else if (mentionsVerification) {
          _pendingVerificationEmail = email;
        }

        _error = message;
        return false;
      }

      _user = res.data;
      _token = await _storage.getToken();
      _pendingVerificationEmail = email;
      _storeVerificationInfoFromRaw(res.raw);
      await _firebaseService.syncTokenWithBackend();
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
        _pendingVerificationEmail = _extractPendingEmail(res.raw);
        return false;
      }

      _user = res.data;
      _token = await _storage.getToken();
      _pendingVerificationEmail = null;
      _pendingVerificationToken = null;
      _pendingVerificationVerifyEndpoint = null;
      return true;
    } catch (_) {
      _error = 'Login failed';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyEmail(String token) async {
    if (token.isEmpty) {
      _error = 'Verification token is required';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await ApiService.getInstance();
      final res = await api.verifyEmail(token);

      if (!res.success || res.data == null) {
        _error = res.message ?? 'Verification failed';
        return false;
      }

      final data = res.data;
      if (data is! Map<String, dynamic>) {
        _error = 'Invalid verification response';
        return false;
      }

      final newToken = data['token']?.toString();
      final userMap = data['user'] as Map<String, dynamic>?;

      if (newToken != null && newToken.isNotEmpty) {
        await _storage.saveToken(newToken);
        _token = newToken;
      }

      if (userMap != null) {
        final verifiedUser = User.fromJson(userMap);
        _user = verifiedUser;
        await _storage.saveUser(verifiedUser);
      }

      _pendingVerificationEmail = null;
      _pendingVerificationToken = null;
      _pendingVerificationVerifyEndpoint = null;
      await _firebaseService.syncTokenWithBackend();
      return true;
    } catch (_) {
      _error = 'Verification failed';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resendVerification(String email) async {
    _error = null;
    notifyListeners();

    try {
      final api = await ApiService.getInstance();
      final res = await api.resendVerification(email);

      if (!res.success) {
        _error = res.message ?? 'Failed to resend verification email';
        return false;
      }

      _pendingVerificationEmail ??= email;
      _storeVerificationInfoFromRaw(res.raw ?? res.data);
      return true;
    } catch (_) {
      _error = 'Failed to resend verification email';
      return false;
    } finally {
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
      _pendingVerificationEmail = null;
      _pendingVerificationToken = null;
      _pendingVerificationVerifyEndpoint = null;
    } catch (_) {
      _error = 'Failed to logout';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _extractPendingEmail(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        final requiresVerification =
            data['requiresVerification'] == true;
        if (requiresVerification) {
          return data['email']?.toString();
        }
      }
    }
    return null;
  }

  void _storeVerificationInfoFromRaw(dynamic raw) {
    final info = _extractVerificationInfo(raw);
    if (info == null) {
      return;
    }

    _pendingVerificationToken = info.token;
    _pendingVerificationVerifyEndpoint = info.verifyEndpoint;
  }

  _VerificationInfo? _extractVerificationInfo(dynamic raw) {
    final root = _normalizeMap(raw);
    if (root == null) {
      return null;
    }

    final data = _normalizeMap(root['data']);
    Map<String, dynamic>? info;

    if (data != null) {
      final nestedInfo = _normalizeMap(data['verificationInfo']);
      if (nestedInfo != null) {
        info = nestedInfo;
      } else if (data.containsKey('verificationToken')) {
        info = data;
      }
    }

    info ??= _normalizeMap(root['verificationInfo']);

    if (info == null) {
      return null;
    }

    final tokenValue = info['verificationToken'] ?? info['token'];
    if (tokenValue == null || tokenValue.toString().isEmpty) {
      return null;
    }

    final endpointValue = info['verifyEndpoint'] ?? info['endpoint'];
    return _VerificationInfo(
      tokenValue.toString(),
      endpointValue?.toString(),
    );
  }

  Map<String, dynamic>? _normalizeMap(dynamic source) {
    if (source is Map<String, dynamic>) {
      return source;
    }
    if (source is Map) {
      return source.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}

class _VerificationInfo {
  final String token;
  final String? verifyEndpoint;

  const _VerificationInfo(this.token, this.verifyEndpoint);
}
