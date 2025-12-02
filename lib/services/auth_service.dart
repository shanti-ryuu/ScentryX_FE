import '../models/api_response.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api;
  final StorageService _storage;

  AuthService._(this._api, this._storage);

  static AuthService? _instance;

  static Future<AuthService> getInstance() async {
    if (_instance != null) {
      return _instance!;
    }
    final api = await ApiService.getInstance();
    final storage = await StorageService.getInstance();
    final service = AuthService._(api, storage);
    _instance = service;
    return service;
  }

  Future<ApiResponse<User>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final res = await _api.register(<String, dynamic>{
      'email': email,
      'password': password,
      'name': fullName,
      'fullName': fullName,
    });

    if (!res.success) {
      return ApiResponse<User>.error(
        res.message ?? 'Registration failed',
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final data = res.data;
    if (data is! Map<String, dynamic>) {
      return ApiResponse<User>.error('Invalid response');
    }

    final token = data['token']?.toString();
    final userJson = data['user'] as Map<String, dynamic>?;

    if (token != null && token.isNotEmpty) {
      await _storage.saveToken(token);
    }

    if (userJson == null) {
      return ApiResponse<User>.error('User data missing');
    }

    final user = User.fromJson(userJson);
    await _storage.saveUser(user);

    return ApiResponse<User>(
      success: true,
      message: res.message,
      data: user,
      statusCode: res.statusCode,
      meta: res.meta,
      raw: res.raw,
    );
  }

  Future<ApiResponse<User>> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.login(<String, dynamic>{
      'email': email,
      'password': password,
    });

    if (!res.success) {
      return ApiResponse<User>.error(
        res.message ?? 'Login failed',
        statusCode: res.statusCode,
        raw: res.raw,
      );
    }

    final data = res.data;
    if (data is! Map<String, dynamic>) {
      return ApiResponse<User>.error('Invalid response');
    }

    final token = data['token']?.toString();
    final userJson = data['user'] as Map<String, dynamic>?;

    if (token != null && token.isNotEmpty) {
      await _storage.saveToken(token);
    }

    if (userJson == null) {
      return ApiResponse<User>.error('User data missing');
    }

    final user = User.fromJson(userJson);
    await _storage.saveUser(user);

    return ApiResponse<User>(
      success: true,
      message: res.message,
      data: user,
      statusCode: res.statusCode,
      meta: res.meta,
      raw: res.raw,
    );
  }

  Future<ApiResponse<User>> refreshProfile() async {
    final res = await _api.getProfile();

    if (!res.success) {
      return ApiResponse<User>.error(
        res.message ?? 'Failed to load profile',
        statusCode: res.statusCode,
      );
    }

    final data = res.data;
    if (data is! Map<String, dynamic>) {
      return ApiResponse<User>.error('Invalid response');
    }

    final user = User.fromJson(data);
    await _storage.saveUser(user);

    return ApiResponse<User>(
      success: true,
      message: res.message,
      data: user,
      statusCode: res.statusCode,
      meta: res.meta,
      raw: res.raw,
    );
  }

  Future<void> logout() async {
    await _storage.deleteToken();
    await _storage.deleteUser();
  }

  User? getCurrentUser() {
    return _storage.getUser();
  }
}
