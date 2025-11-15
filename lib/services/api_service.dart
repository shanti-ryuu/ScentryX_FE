import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5000/api';

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
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
      return ApiResponse<dynamic>.fromJson(body, (obj) => obj);
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
    if (response != null && response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final message = map['message']?.toString() ??
          error.message ??
          'Request failed';
      final patched = <String, dynamic>{
        ...map,
        'message': message,
      };
      return ApiResponse<dynamic>.fromJson(patched, (obj) => obj);
    }

    return ApiResponse<dynamic>.error(
      error.message ?? 'Network error',
      statusCode: response?.statusCode,
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
    return _request('POST', '/auth/register', data: data);
  }

  Future<ApiResponse<dynamic>> login(Map<String, dynamic> data) {
    return _request('POST', '/auth/login', data: data);
  }

  Future<ApiResponse<dynamic>> getProfile() {
    return _request('GET', '/auth/profile');
  }

  Future<ApiResponse<dynamic>> updateProfile(Map<String, dynamic> data) {
    return _request('PUT', '/auth/profile', data: data);
  }

  Future<ApiResponse<dynamic>> updateFCMToken(String token) {
    return _request(
      'POST',
      '/auth/fcm-token',
      data: <String, dynamic>{'token': token},
    );
  }

  Future<ApiResponse<dynamic>> registerDevice(Map<String, dynamic> data) {
    return _request('POST', '/devices', data: data);
  }

  Future<ApiResponse<dynamic>> getDevices() {
    return _request('GET', '/devices');
  }

  Future<ApiResponse<dynamic>> getDevice(String deviceId) {
    return _request('GET', '/devices/$deviceId');
  }

  Future<ApiResponse<dynamic>> updateDevice(
    String deviceId,
    Map<String, dynamic> data,
  ) {
    return _request('PUT', '/devices/$deviceId', data: data);
  }

  Future<ApiResponse<dynamic>> deleteDevice(String deviceId) {
    return _request('DELETE', '/devices/$deviceId');
  }

  Future<ApiResponse<dynamic>> getReadings(
    String deviceId, {
    int page = 1,
  }) {
    return _request(
      'GET',
      '/readings/$deviceId',
      query: <String, dynamic>{'page': page},
    );
  }

  Future<ApiResponse<dynamic>> getLatestReading(String deviceId) {
    return _request('GET', '/readings/$deviceId/latest');
  }

  Future<ApiResponse<dynamic>> getStatistics(
    String deviceId, {
    int hours = 24,
  }) {
    return _request(
      'GET',
      '/readings/$deviceId/statistics',
      query: <String, dynamic>{'hours': hours},
    );
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
    return _request('GET', '/alerts', query: query);
  }

  Future<ApiResponse<dynamic>> getUnreadCount() {
    return _request('GET', '/alerts/unread-count');
  }

  Future<ApiResponse<dynamic>> acknowledgeAlert(String alertId) {
    return _request('POST', '/alerts/$alertId/acknowledge');
  }

  Future<ApiResponse<dynamic>> deleteAlert(String alertId) {
    return _request('DELETE', '/alerts/$alertId');
  }
}
