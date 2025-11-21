import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/reading.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';

class ReadingProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;

  ReadingProvider(this._firebaseService);

  Reading? _latestReading;
  final List<Reading> _readings = <Reading>[];
  Map<String, dynamic>? _statistics;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Reading?>? _liveSubscription;

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

  void subscribeToLiveReadings(String deviceId) {
    _liveSubscription?.cancel();
    _liveSubscription = _firebaseService
        .subscribeToLiveReading(deviceId)
        .listen((reading) {
      _latestReading = reading;
      if (reading != null) {
        _readings.insert(0, reading);
      }
      notifyListeners();
    }, onError: (_) {
      _error = 'Live updates error';
      notifyListeners();
    });
  }

  void unsubscribeFromLiveReadings() {
    _liveSubscription?.cancel();
    _liveSubscription = null;
  }

  @override
  void dispose() {
    _liveSubscription?.cancel();
    super.dispose();
  }
}
