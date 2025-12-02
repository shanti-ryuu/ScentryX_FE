import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/reading.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class ReadingProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;

  ReadingProvider(this._firebaseService);

  Reading? _latestReading;
  final List<Reading> _readings = <Reading>[];
  Map<String, dynamic>? _statistics;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Reading?>? _liveSubscription;
  int? _alertThreshold;
  String _alertDeviceName = '';
  bool _alertActive = false;

  Reading? get latestReading => _latestReading;
  List<Reading> get readings => List.unmodifiable(_readings);
  Map<String, dynamic>? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLatestReading(String deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await ApiService.getInstance();
      final res = await api.getLatestReading(deviceId);

      if (!res.success || res.data == null) {
        _error = res.message ?? 'Failed to load latest reading';
        return;
      }

      final data = res.data;
      Map<String, dynamic>? json;
      if (data is List && data.isNotEmpty) {
        final item = data.first;
        if (item is Map<String, dynamic>) {
          json = item;
        } else if (item is Map) {
          json = Map<String, dynamic>.from(item);
        }
      } else if (data is Map<String, dynamic>) {
        json = data;
      }

      if (json == null) {
        _error = 'Invalid reading data';
        return;
      }

      _latestReading = Reading.fromJson(json);
      if (_latestReading != null) {
        _handleAlertForReading(_latestReading!);
      }
    } catch (_) {
      _error = 'Failed to load latest reading';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchReadings(String deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await ApiService.getInstance();
      final res = await api.getReadings(deviceId);

      if (!res.success || res.data == null) {
        _error = res.message ?? 'Failed to load readings';
        return;
      }

      final data = res.data;
      final list = data is List ? data : <dynamic>[];

      final items = list.map((item) {
        if (item is Map<String, dynamic>) {
          return Reading.fromJson(item);
        }
        if (item is Map) {
          return Reading.fromJson(Map<String, dynamic>.from(item));
        }
        return null;
      }).whereType<Reading>().toList();

      _readings
        ..clear()
        ..addAll(items);
    } catch (_) {
      _error = 'Failed to load readings';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStatistics(String deviceId) async {
    if (_readings.isEmpty) {
      await fetchReadings(deviceId);
    }

    if (_readings.isEmpty) {
      _statistics = null;
      notifyListeners();
      return;
    }

    final total = _readings.fold<int>(0, (sum, item) => sum + item.gasLevelPpm);
    final average = total / _readings.length;
    final maxReading = _readings.reduce(
      (curr, next) => curr.gasLevelPpm >= next.gasLevelPpm ? curr : next,
    );

    _statistics = <String, dynamic>{
      'averagePpm': average,
      'maxPpm': maxReading.gasLevelPpm,
      'maxTimestamp': maxReading.timestamp.toIso8601String(),
    };
    notifyListeners();
  }

  void configureAlertContext({
    required int threshold,
    String deviceName = '',
  }) {
    _alertThreshold = threshold;
    _alertDeviceName = deviceName;
    _alertActive = false;
  }

  void subscribeToLiveReadings(String deviceId) {
    print('[ReadingProvider] Subscribing to live readings for device: $deviceId');
    
    _liveSubscription?.cancel();
    _liveSubscription = _firebaseService
        .subscribeToLiveReading(deviceId)
        .listen((reading) {
      print('[ReadingProvider] Processing new reading: ${reading?.toJson()}');
      
      _latestReading = reading;
      if (reading != null) {
        _readings.insert(0, reading);
        print('[ReadingProvider] Added new reading. Total readings: ${_readings.length}');
        _handleAlertForReading(reading);
      } else {
        print('[ReadingProvider] Received null reading');
      }
      
      print('[ReadingProvider] Notifying listeners');
      notifyListeners();
    }, onError: (error) {
      print('[ReadingProvider] Error in live reading stream: $error');
      _error = 'Live updates error: $error';
      notifyListeners();
    }, onDone: () {
      print('[ReadingProvider] Live reading stream closed');
    });
    
    print('[ReadingProvider] Successfully subscribed to live readings');
  }

  void unsubscribeFromLiveReadings() {
    print('[ReadingProvider] Unsubscribing from live readings');
    _liveSubscription?.cancel();
    _liveSubscription = null;
    print('[ReadingProvider] Successfully unsubscribed from live readings');
  }

  void _handleAlertForReading(Reading reading) {
    if (_alertThreshold == null) {
      return;
    }

    final threshold = math.max(1, _alertThreshold!);
    final isDanger = reading.gasLevelPpm >= threshold;

    if (isDanger && !_alertActive) {
      NotificationService().showNotification(
        title: 'High gas level detected',
        body:
            '${_alertDeviceName.isNotEmpty ? _alertDeviceName : reading.deviceId} reached ${reading.gasLevelPpm} ppm (threshold: $threshold)',
        payload: {
          'deviceId': reading.deviceId,
          'ppm': reading.gasLevelPpm.toString(),
        },
      );
      _alertActive = true;
      print('[ReadingProvider] Alert triggered for ${reading.deviceId} at ${reading.gasLevelPpm} ppm');
    } else if (!isDanger && _alertActive) {
      _alertActive = false;
      print('[ReadingProvider] Gas level back below threshold, alert reset');
    }
  }

  @override
  void dispose() {
    _liveSubscription?.cancel();
    super.dispose();
  }
}
