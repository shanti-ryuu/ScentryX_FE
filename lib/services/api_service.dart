import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/constants.dart';
import '../models/api_response.dart';
import 'storage_service.dart';

class ApiService {
  final Dio _dio;

  ApiService._(this._dio) {
    _setupInterceptors();
  }

  static ApiService? _instance;

  static Future<ApiService> getInstance() async {
    if (_instance != null) {
      return _instance!;
    }

    final envValue = dotenv.env['API_BASE_URL'];
    final baseUrl = AppConstants.resolveApiBaseUrl(envValue);

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(minutes: 2),
        headers: <String, dynamic>{
          'Content-Type': 'application/json',
        },
      ),
    );

    final service = ApiService._(dio);
    _instance = service;
    return service;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final storage = await StorageService.getInstance();
          final token = await storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  ApiResponse<dynamic> _handleResponse(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final normalized = Map<String, dynamic>.from(body);
      normalized['data'] ??=
          normalized['device'] ??
              normalized['devices'] ??
              normalized['alert'] ??
              normalized['alerts'] ??
              normalized['result'];
      return ApiResponse<dynamic>.fromJson(normalized, (obj) => obj);
    }

    final ok = response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300;

    return ApiResponse<dynamic>(
      success: ok,
      message: null,
      data: body,
      statusCode: response.statusCode,
      meta: null,
      raw: body,
    );
  }

  ApiResponse<dynamic> _handleError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return ApiResponse<dynamic>.error(
        'Server is taking too long to respond. Please try again in a moment.',
        statusCode: statusCode,
      );
    }

    if (response != null && response.data is Map<String, dynamic>) {
      final map = Map<String, dynamic>.from(response.data as Map<String, dynamic>);
      final message = map['message']?.toString() ??
          error.message ??
          'Request failed';

      final metaRaw = map['meta'] ?? map['pagination'];
      Map<String, dynamic>? meta;
      if (metaRaw is Map<String, dynamic>) {
        meta = metaRaw;
      } else if (metaRaw is Map) {
        meta = metaRaw.map((key, value) => MapEntry(key.toString(), value));
      }

      return ApiResponse<dynamic>(
        success: false,
        message: message,
        data: map['data'] ?? map['result'],
        statusCode: statusCode,
        meta: meta,
        raw: map,
      );
    }

    return ApiResponse<dynamic>.error(
      error.message ?? 'Network error',
      statusCode: statusCode,
    );
  }

  Future<ApiResponse<dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
  }) async {
    try {
      Response<dynamic> response;
      switch (method) {
        case 'GET':
          response =
              await _dio.get<dynamic>(path, queryParameters: query);
          break;
        case 'POST':
          response = await _dio.post<dynamic>(
            path,
            data: data,
            queryParameters: query,
          );
          break;
        case 'PUT':
          response = await _dio.put<dynamic>(
            path,
            data: data,
            queryParameters: query,
          );
          break;
        case 'DELETE':
          response = await _dio.delete<dynamic>(
            path,
            data: data,
            queryParameters: query,
          );
          break;
        default:
          response = await _dio.request<dynamic>(
            path,
            data: data,
            queryParameters: query,
            options: Options(method: method),
          );
      }
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return ApiResponse<dynamic>.error('Unexpected error');
    }
  }

  Future<ApiResponse<dynamic>> register(Map<String, dynamic> data) {
    return _request('POST', '/api/auth/register', data: data);
  }

  Future<ApiResponse<dynamic>> login(Map<String, dynamic> data) {
    return _request('POST', '/api/auth/login', data: data);
  }

  Future<ApiResponse<dynamic>> verifyEmail(String token) {
    return _request('POST', '/api/auth/verify-email/$token');
  }

  Future<ApiResponse<dynamic>> resendVerification(String email) {
    return _request('POST', '/api/auth/resend-verification', data: {'email': email});
  }

  Future<ApiResponse<dynamic>> getProfile() {
    return _request('GET', '/api/auth/profile');
  }

  Future<ApiResponse<dynamic>> updateProfile(Map<String, dynamic> data) {
    return _request('PUT', '/api/auth/profile', data: data);
  }

  Future<ApiResponse<dynamic>> updateFCMToken(String token, {String? userId}) async {
    if (userId == null) {
      // Try to get the user ID from storage
      final storage = await StorageService.getInstance();
      final user = storage.getUser();
      if (user == null || user.id == null) {
        return ApiResponse<dynamic>.error('User ID is required');
      }
      userId = user.id;
    }

    return _request(
      'POST',
      '/api/auth/fcm-token',
      data: {
        'token': token,
        'userId': userId,
      },
    );
  }

  Future<ApiResponse<dynamic>> registerDevice(Map<String, dynamic> data) {
    return _request('POST', '/api/devices', data: data);
  }

  Future<ApiResponse<dynamic>> getDevices() {
    return _request('GET', '/api/devices');
  }

  Future<ApiResponse<dynamic>> getDevice(String deviceId) {
    return _request('GET', '/api/devices/$deviceId');
  }

  Future<ApiResponse<dynamic>> updateDevice(
    String deviceId,
    Map<String, dynamic> data,
  ) {
    return _request('PUT', '/api/devices/$deviceId', data: data);
  }

  Future<ApiResponse<dynamic>> deleteDevice(String deviceId) {
    return _request('DELETE', '/api/devices/$deviceId');
  }

  Future<ApiResponse<dynamic>> getReadings(String deviceId) {
    return _request('GET', '/api/gas/$deviceId');
  }

  Future<ApiResponse<dynamic>> getLatestReading(String deviceId) {
    return _request('GET', '/api/gas/$deviceId');
  }

  Future<ApiResponse<dynamic>> getStatistics(String deviceId) {
    return _request('GET', '/api/gas/$deviceId');
  }

  Future<ApiResponse<dynamic>> getAllGasReadings() {
    return _request('GET', '/api/gas');
  }

  Future<ApiResponse<dynamic>> createGasReading(Map<String, dynamic> data) {
    return _request('POST', '/api/gas', data: data);
  }

  Future<ApiResponse<dynamic>> getAlerts({
    String? deviceId,
    String? alertType,
    int page = 1,
  }) {
    final query = <String, dynamic>{'page': page};
    if (deviceId != null) {
      query['deviceId'] = deviceId;
    }
    if (alertType != null) {
      query['alertType'] = alertType;
    }
    return _request('GET', '/api/alerts', query: query);
  }

  Future<ApiResponse<dynamic>> getUnreadCount() {
    return _request('GET', '/api/alerts/unread-count');
  }

  Future<ApiResponse<dynamic>> acknowledgeAlert(String alertId) async {
    final response = await _request(
      'POST',
      '/api/alerts/acknowledge',
      data: {'alertId': alertId},
    );

    if (!response.success) {
      final missingRoute = response.statusCode == 404 ||
          (response.message?.toLowerCase().contains('not found') ?? false);
      if (missingRoute) {
        return _request('POST', '/api/alerts/$alertId/acknowledge');
      }
    }

    return response;
  }

  Future<ApiResponse<dynamic>> deleteAlert(String alertId) {
    return _request('DELETE', '/api/alerts/$alertId');
  }
}
