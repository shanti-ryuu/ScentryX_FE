class Alert {
  final String id;
  final String deviceId;
  final String alertType;
  final int gasLevelPpm;
  final String message;
  final bool isAcknowledged;
  final DateTime? acknowledgedAt;
  final DateTime timestamp;

  String? deviceName;
  String? location;

  Alert({
    required this.id,
    required this.deviceId,
    required this.alertType,
    required this.gasLevelPpm,
    required this.message,
    required this.isAcknowledged,
    this.acknowledgedAt,
    required this.timestamp,
    this.deviceName,
    this.location,
  });

  bool get isDanger => alertType.toLowerCase() == 'danger';

  bool get isWarning => alertType.toLowerCase() == 'warning';

  bool get isSafe => alertType.toLowerCase() == 'safe';

  factory Alert.fromJson(Map<String, dynamic> json) {
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

    final acknowledgedAtValue = json['acknowledgedAt'];
    DateTime? acknowledgedAt;
    if (acknowledgedAtValue is String) {
      acknowledgedAt = DateTime.tryParse(acknowledgedAtValue)?.toLocal();
    } else if (acknowledgedAtValue is int) {
      acknowledgedAt = DateTime.fromMillisecondsSinceEpoch(acknowledgedAtValue,
              isUtc: true)
          .toLocal();
    }

    final typeValue = json['alertType'] ?? json['type'];
    final gasValue =
        json['gasLevelPpm'] ?? json['ppm'] ?? json['gas_level_ppm'];

    return Alert(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      deviceId:
          (json['deviceId'] ?? json['device_id'] ?? json['device'] ?? '').toString(),
      alertType: (typeValue ?? '').toString(),
      gasLevelPpm: (gasValue as num?)?.toInt() ?? 0,
      message: (json['message'] ?? '').toString(),
      isAcknowledged:
          (json['isAcknowledged'] ?? json['acknowledged'] ?? false) == true,
      acknowledgedAt: acknowledgedAt,
      timestamp: timestamp,
      deviceName: json['deviceName']?.toString(),
      location: json['location']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'deviceId': deviceId,
      'alertType': alertType,
      'gasLevelPpm': gasLevelPpm,
      'message': message,
      'isAcknowledged': isAcknowledged,
      'acknowledgedAt': acknowledgedAt?.toUtc().toIso8601String(),
      'timestamp': timestamp.toUtc().toIso8601String(),
      'deviceName': deviceName,
      'location': location,
    };
  }
}
