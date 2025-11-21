class Device {
  final String id;
  final String deviceId; // MAC address
  final String deviceName;
  final String deviceType;
  final String location;
  final String status;
  final int alertThreshold;
  final DateTime? lastSeen;
  final bool isOnline;
  final DateTime createdAt;

  Device({
    this.id = '',
    this.deviceId = '',
    this.deviceName = '',
    this.deviceType = 'sensor',
    this.location = '',
    this.status = 'offline',
    this.alertThreshold = 300,
    this.lastSeen,
    this.isOnline = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOffline => !isOnline;

  String get statusLabel => isOnline ? 'Online' : 'Offline';

  String get displayName => deviceName.isNotEmpty ? deviceName : deviceId;

  factory Device.fromJson(Map<String, dynamic> json) {
    final lastSeenValue = json['lastSeen'];
    DateTime? lastSeen;
    if (lastSeenValue is String) {
      lastSeen = DateTime.tryParse(lastSeenValue)?.toLocal();
    } else if (lastSeenValue is int) {
      lastSeen =
          DateTime.fromMillisecondsSinceEpoch(lastSeenValue, isUtc: true).toLocal();
    }

    final createdAtValue = json['createdAt'];
    DateTime createdAt;
    if (createdAtValue is String) {
      createdAt = DateTime.tryParse(createdAtValue)?.toLocal() ?? DateTime.now();
    } else if (createdAtValue is int) {
      createdAt =
          DateTime.fromMillisecondsSinceEpoch(createdAtValue, isUtc: true).toLocal();
    } else {
      createdAt = DateTime.now();
    }

    final status = (json['status'] ?? 'online').toString();
    final isOnlineField = json['isOnline'];
    final bool isOnline = isOnlineField is bool
        ? isOnlineField
        : status.toLowerCase() == 'online';

    return Device(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      deviceId: (json['deviceId'] ?? json['macAddress'] ?? '').toString(),
      deviceName: (json['deviceName'] ?? json['name'] ?? '').toString(),
      deviceType: (json['deviceType'] ?? json['type'] ?? 'sensor').toString(),
      location: (json['location'] ?? '').toString(),
      status: status,
      alertThreshold: (json['alertThreshold'] as num?)?.toInt() ?? 50,
      lastSeen: lastSeen,
      isOnline: isOnline,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'location': location,
      'status': status,
      'alertThreshold': alertThreshold,
      'lastSeen': lastSeen?.toUtc().toIso8601String(),
      'isOnline': isOnline,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }
}
