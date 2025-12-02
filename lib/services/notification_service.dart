import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const _androidChannelId = 'gas_alerts';
  static const _androidChannelName = 'Gas Leak Alerts';
  static const _androidChannelDescription =
      'Notifications for gas leak detection alerts';
  static const _warningAndroidSound = 'gas_alert_beep';
  static const _warningIosSound = 'gas_alert_beep.mp3';
  static const _dangerAndroidSound = 'gas_alert_danger';
  static const _dangerIosSound = 'gas_alert_danger.mp3';

  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    const androidChannel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound(_dangerAndroidSound),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    bool isDanger = true,
  }) async {
    final soundAndroid = RawResourceAndroidNotificationSound(
      isDanger ? _dangerAndroidSound : _warningAndroidSound,
    );
    final soundIos = isDanger ? _dangerIosSound : _warningIosSound;

    final androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      sound: soundAndroid,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: soundIos,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (!_initialized) {
      await initialize();
    }

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    final _ = response.payload;
  }
}
