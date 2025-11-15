import 'package:flutter/material.dart';

class Reading {
  final String id;
  final String deviceId;
  final int gasLevelPpm;
  final String status; // safe, warning, danger
  final double? temperature;
  final double? humidity;
  final DateTime timestamp;

  const Reading({
    required this.id,
    required this.deviceId,
    required this.gasLevelPpm,
    required this.status,
    this.temperature,
    this.humidity,
    required this.timestamp,
  });

  bool get isSafe => status.toLowerCase() == 'safe';

  bool get isWarning => status.toLowerCase() == 'warning';

  bool get isDanger => status.toLowerCase() == 'danger';

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'safe':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'danger':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  factory Reading.fromJson(Map<String, dynamic> json) {
    final timestampValue = json['timestamp'];
    DateTime timestamp;
    if (timestampValue is String) {
      timestamp =
          DateTime.tryParse(timestampValue)?.toLocal() ?? DateTime.now();
    } else if (timestampValue is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue,
              isUtc: true)
          .toLocal();
    } else {
      timestamp = DateTime.now();
    }

    final gasValue = json['gasLevelPpm'] ?? json['ppm'] ?? json['gas_level_ppm'];

    return Reading(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      deviceId:
          (json['deviceId'] ?? json['device_id'] ?? json['device'] ?? '').toString(),
      gasLevelPpm: (gasValue as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'safe').toString(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      timestamp: timestamp,
    );
  }

  factory Reading.fromFirebase(Map<String, dynamic> json) {
    return Reading.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'deviceId': deviceId,
      'gasLevelPpm': gasLevelPpm,
      'status': status,
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }
}
