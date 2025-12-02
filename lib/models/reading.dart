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
    print('[Reading] Parsing JSON data: $json');
    
    // Handle timestamp
    DateTime timestamp;
    try {
      final timestampValue = json['timestamp'];
      if (timestampValue is String) {
        timestamp = DateTime.tryParse(timestampValue)?.toLocal() ?? DateTime.now();
      } else if (timestampValue is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue, isUtc: true).toLocal();
      } else if (timestampValue is DateTime) {
        timestamp = timestampValue.toLocal();
      } else {
        timestamp = DateTime.now();
      }
    } catch (e) {
      print('[Reading] Error parsing timestamp: $e');
      timestamp = DateTime.now();
    }

    // Handle gas level
    int gasLevelPpm;
    try {
      final gasValue = json['gasLevelPpm'] ?? json['ppm'] ?? json['gas_level_ppm'];
      gasLevelPpm = (gasValue is num ? gasValue.toInt() : 0);
    } catch (e) {
      print('[Reading] Error parsing gas level: $e');
      gasLevelPpm = 0;
    }

    // Handle status with validation
    String status = 'safe';
    try {
      final statusValue = (json['status'] ?? 'safe').toString().toLowerCase();
      status = ['safe', 'warning', 'danger'].contains(statusValue) 
          ? statusValue 
          : 'safe';
    } catch (e) {
      print('[Reading] Error parsing status: $e');
    }

    final reading = Reading(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      deviceId: (json['deviceId'] ?? json['device_id'] ?? json['device'] ?? '').toString(),
      gasLevelPpm: gasLevelPpm,
      status: status,
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      timestamp: timestamp,
    );
    
    print('[Reading] Created Reading object: ${reading.toJson()}');
    return reading;
  }

  factory Reading.fromFirebase(Map<String, dynamic> json) {
    print('[Reading] Parsing Firebase data: $json');
    
    // Handle Firebase timestamp format
    if (json['timestamp'] is Map && json['timestamp']['_seconds'] != null) {
      final seconds = json['timestamp']['_seconds'] as int;
      json = Map<String, dynamic>.from(json);
      json['timestamp'] = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    }
    
    // Handle different field naming conventions
    final data = {
      'id': json['id'] ?? json['_id'] ?? '',
      'deviceId': json['deviceId'] ?? json['device_id'] ?? json['device'] ?? '',
      'gasLevelPpm': json['gasLevelPpm'] ?? json['ppm'] ?? json['gas_level_ppm'] ?? 0,
      'status': (json['status'] ?? 'safe').toString().toLowerCase(),
      'temperature': json['temperature'] ?? json['temp'],
      'humidity': json['humidity'],
      'timestamp': json['timestamp'],
    };
    
    print('[Reading] Parsed Firebase data: $data');
    return Reading.fromJson(data);
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
