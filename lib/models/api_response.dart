class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;
  final Map<String, dynamic>? meta;
  final dynamic raw;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
    this.meta,
    this.raw,
  });

  bool get hasData => data != null;

  bool get hasError => !success;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final statusField = json['success'] ?? json['ok'] ?? json['status'];
    bool success;
    if (statusField is bool) {
      success = statusField;
    } else if (statusField is String) {
      success = statusField.toLowerCase() == 'success';
    } else {
      success = true;
    }

    final meta = json['meta'] ?? json['pagination'];

    return ApiResponse<T>(
      success: success,
      message: json['message']?.toString(),
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      statusCode: json['statusCode'] as int? ?? json['code'] as int?,
      meta: meta is Map<String, dynamic>
          ? meta
          : meta is Map
              ? meta.map((key, value) => MapEntry(key.toString(), value))
              : null,
      raw: json,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
      data: null,
      meta: null,
      raw: null,
    );
  }

  ApiResponse<R> map<R>(R Function(T value) transform) {
    if (data == null) {
      return ApiResponse<R>(
        success: success,
        message: message,
        data: null,
        statusCode: statusCode,
        meta: meta,
        raw: raw,
      );
    }

    return ApiResponse<R>(
      success: success,
      message: message,
      data: transform(data as T),
      statusCode: statusCode,
      meta: meta,
      raw: raw,
    );
  }
}
