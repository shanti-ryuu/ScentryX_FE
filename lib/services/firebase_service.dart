import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/reading.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class FirebaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _latestToken;
  bool _pendingSync = false;

  Future<void> initializeFCM() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await _messaging.getToken();
        if (token != null) {
          _latestToken = token;
          await _sendTokenToBackend(token);
        }
      }

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      _messaging.onTokenRefresh.listen((newToken) async {
        _latestToken = newToken;
        final storage = await StorageService.getInstance();
        final user = storage.getUser();
        if (user != null) {
          await _sendTokenToBackend(newToken);
        } else {
          _pendingSync = true;
        }
      });
    } catch (e) {
      print('[FirebaseService] Error initializing FCM: $e');
      rethrow;
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final storage = await StorageService.getInstance();
      final authToken = await storage.getToken();
      final user = storage.getUser();

      if (authToken == null || authToken.isEmpty || user == null) {
        print('[FirebaseService] Missing auth context, deferring FCM sync');
        _pendingSync = true;
        return;
      }

      print('[FirebaseService] Sending FCM token for user ${user.id}');
      final api = await ApiService.getInstance();
      final res = await api.updateFCMToken(token, userId: user.id);

      if (!res.success) {
        print('[FirebaseService] Failed to update FCM token: ${res.message}');
        _pendingSync = true;
      } else {
        print('[FirebaseService] FCM token synced successfully');
        _pendingSync = false;
      }
    } catch (e) {
      print('[FirebaseService] Error in _sendTokenToBackend: $e');
      _pendingSync = true;
      rethrow;
    }
  }

  Future<void> syncTokenWithBackend() async {
    if (_latestToken == null || !_pendingSync) {
      return;
    }

    await _sendTokenToBackend(_latestToken!);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    NotificationService().showNotification(
      title: notification?.title ?? 'Alert',
      body: notification?.body ?? '',
      payload: message.data,
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final data = message.data;
    print('[FirebaseService] Notification opened with data: $data');
  }

  Stream<Reading?> subscribeToLiveReading(String deviceId) {
    if (deviceId.isEmpty) {
      print('[FirebaseService] subscribeToLiveReading called with empty deviceId');
      return Stream.value(null);
    }

    final controller = StreamController<Reading?>();
    StreamSubscription<DatabaseEvent>? deviceNodeSub;
    StreamSubscription<DatabaseEvent>? fallbackSub;

    Future<void> emit(DatabaseEvent event, String source) async {
      print('[FirebaseService] Live reading update for $deviceId via $source');

      if (!event.snapshot.exists) {
        print('[FirebaseService] No data found for $deviceId on $source');
        return;
      }

      final raw = event.snapshot.value;
      final data = _extractFirstMap(raw);

      if (data == null) {
        print('[FirebaseService] Unable to parse reading payload from $source: $raw');
        return;
      }

      data['deviceId'] ??= deviceId;
      data['gasLevelPpm'] ??= data['gasValue'];
      data['timestamp'] ??= data['lastUpdate'] ?? data['formattedTime'];

      final readingDeviceId = data['deviceId']?.toString();
      if (readingDeviceId != null && readingDeviceId != deviceId) {
        print('[FirebaseService] Device ID mismatch on $source. Expected $deviceId got $readingDeviceId');
        return;
      }

      try {
        final reading = Reading.fromFirebase(Map<String, dynamic>.from(data));
        print('[FirebaseService] Parsed live reading from $source: ${reading.toJson()}');
        controller.add(reading);
      } catch (e) {
        print('[FirebaseService] Error parsing live reading from $source: $e');
      }
    }

    void attachFallback() {
      fallbackSub ??= _database
          .ref('devices/$deviceId/readings')
          .limitToLast(1)
          .onValue
          .listen(
            (event) => emit(event, 'devices/$deviceId/readings (fallback)'),
            onError: (error) {
              print('[FirebaseService] Live reading fallback error: $error');
              controller.addError(error);
            },
          );
    }

    deviceNodeSub = _database
        .ref('devices/$deviceId/current')
        .onValue
        .listen(
          (event) async {
            if (!event.snapshot.exists) {
              print('[FirebaseService] devices/$deviceId/current empty, attaching fallback readings');
              attachFallback();
              return;
            }
            await emit(event, 'devices/$deviceId/current');
          },
          onError: (error) {
            print('[FirebaseService] Live reading current node error: $error');
            controller.addError(error);
            attachFallback();
          },
        );

    controller.onCancel = () async {
      await deviceNodeSub?.cancel();
      await fallbackSub?.cancel();
    };

    return controller.stream;
  }

  Stream<Map<String, dynamic>?> subscribeToDeviceStatus(String deviceId) {
    if (deviceId.isEmpty) {
      print('[FirebaseService] subscribeToDeviceStatus called with empty deviceId');
      return Stream.value(null);
    }

    final ref = _database.ref('devices/$deviceId');

    return ref.onValue.map((event) {
      print('[FirebaseService] Device status update for $deviceId');

      if (!event.snapshot.exists) {
        print('[FirebaseService] No status data found for device: $deviceId');
        return null;
      }

      final raw = event.snapshot.value;
      if (raw is Map) {
        try {
          final data = Map<String, dynamic>.from(raw);
          return data;
        } catch (e) {
          print('[FirebaseService] Error parsing device status: $e');
          return null;
        }
      }

      print('[FirebaseService] Unexpected device status payload: $raw');
      return null;
    });
  }

  Map<String, dynamic>? _extractFirstMap(Object? raw) {
    if (raw == null) {
      return null;
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
      final looksLikeReading = map.containsKey('deviceId') ||
          map.containsKey('gasLevelPpm') ||
          map.containsKey('gasValue');

      if (looksLikeReading) {
        return map;
      }

      for (final entry in map.values) {
        if (entry is Map) {
          return Map<String, dynamic>.from(entry.cast<dynamic, dynamic>());
        }
      }
    }

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          return Map<String, dynamic>.from(item.cast<dynamic, dynamic>());
        }
      }
    }

    return null;
  }

  Future<void> dispose() async {
    // Nothing to dispose yet, but keep for API parity.
    return;
  }
}
