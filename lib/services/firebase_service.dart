import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/reading.dart';
import 'api_service.dart';
import 'notification_service.dart';

class FirebaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<Reading?>? _liveReadingSubscription;

  Future<void> initializeFCM() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await _messaging.getToken();
      if (token != null) {
        final api = await ApiService.getInstance();
        await api.updateFCMToken(token);
      }
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    _messaging.onTokenRefresh.listen((newToken) async {
      final api = await ApiService.getInstance();
      await api.updateFCMToken(newToken);
    });
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
    final _ = message.data;
  }

  Stream<Reading?> subscribeToLiveReading(String deviceId) {
    final ref = _database.ref('live_readings/$deviceId');
    final stream = ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        final data = Map<String, dynamic>.from(value);
        return Reading.fromFirebase(data);
      }
      return null;
    });

    _liveReadingSubscription?.cancel();
    _liveReadingSubscription = stream.listen((_) {});

    return stream;
  }

  Stream<Map<String, dynamic>?> subscribeToDeviceStatus(String deviceId) {
    final ref = _database.ref('devices/$deviceId');
    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return null;
    });
  }

  Future<void> dispose() async {
    await _liveReadingSubscription?.cancel();
    _liveReadingSubscription = null;
  }
}
