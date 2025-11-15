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

      Map<String, dynamic>? json;
      final data = res.data;
      if (data is Map<String, dynamic>) {
        json = data;
      } else if (data is Map) {
        json = Map<String, dynamic>.from(data);
      } else if (data is Map<String, dynamic> && data['data'] is Map) {
        json = Map<String, dynamic>.from(data['data'] as Map);
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

  Future<void> fetchReadings(String deviceId, {int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await ApiService.getInstance();
      final res = await api.getReadings(deviceId, page: page);

      if (!res.success || res.data == null) {
        _error = res.message ?? 'Failed to load readings';
        return;
      }

      final data = res.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic> && data['data'] is List) {
        list = (data['data'] as List).toList();
      } else {
        list = <dynamic>[];
      }

      final items = list.map((item) {
        if (item is Map<String, dynamic>) {
          return Reading.fromJson(item);
        }
        if (item is Map) {
          return Reading.fromJson(Map<String, dynamic>.from(item));
        }
        return null;
      }).whereType<Reading>().toList();

      if (page == 1) {
        _readings
          ..clear()
          ..addAll(items);
      } else {
        _readings.addAll(items);
      }
    } catch (_) {
      _error = 'Failed to load readings';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStatistics(String deviceId, {int hours = 24}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await ApiService.getInstance();
      final res = await api.getStatistics(deviceId, hours: hours);

      if (!res.success || res.data == null) {
        _error = res.message ?? 'Failed to load statistics';
        return;
      }

      if (res.data is Map<String, dynamic>) {
        _statistics = res.data as Map<String, dynamic>;
      } else if (res.data is Map) {
        _statistics = Map<String, dynamic>.from(res.data as Map);
      } else {
        _statistics = null;
      }
    } catch (_) {
      _error = 'Failed to load statistics';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
