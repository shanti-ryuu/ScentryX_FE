import 'package:flutter/foundation.dart';

import '../models/alert.dart';
import '../services/api_service.dart';

class AlertProvider extends ChangeNotifier {
  final List<Alert> _alerts = <Alert>[];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<Alert> get alerts => List.unmodifiable(_alerts);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAlerts({
    String? deviceId,
    String? alertType,
    int page = 1,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await ApiService.getInstance();
      final res = await api.getAlerts(
        deviceId: deviceId,
        alertType: alertType,
        page: page,
      );

      if (!res.success || res.data == null) {
        _error = res.message ?? 'Failed to load alerts';
        return;
      }

      final data = res.data;
      List<dynamic> list = <dynamic>[];

      List<dynamic>? _extractList(dynamic source) {
        if (source is List) {
          return source;
        }
        if (source is Map<String, dynamic>) {
          if (source['data'] is List) return List<dynamic>.from(source['data'] as List);
          if (source['alerts'] is List) return List<dynamic>.from(source['alerts'] as List);
          if (source['items'] is List) return List<dynamic>.from(source['items'] as List);
          if (source['results'] is List) return List<dynamic>.from(source['results'] as List);
        }
        if (source is Map) {
          final map = Map<String, dynamic>.from(source.cast<dynamic, dynamic>());
          return _extractList(map);
        }
        return null;
      }

      list = _extractList(data) ?? <dynamic>[];

      final items = list.map((item) {
        if (item is Map<String, dynamic>) {
          return Alert.fromJson(item);
        }
        if (item is Map) {
          return Alert.fromJson(Map<String, dynamic>.from(item));
        }
        return null;
      }).whereType<Alert>().toList();

      if (page == 1) {
        _alerts
          ..clear()
          ..addAll(items);
      } else {
        _alerts.addAll(items);
      }
    } catch (_) {
      _error = 'Failed to load alerts';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final api = await ApiService.getInstance();
      final res = await api.getUnreadCount();

      if (!res.success || res.data == null) {
        _error = res.message ?? 'Failed to load unread count';
        return;
      }

      final data = res.data;
      if (data is Map<String, dynamic>) {
        _unreadCount = (data['count'] as num?)?.toInt() ?? 0;
      } else if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _unreadCount = (map['count'] as num?)?.toInt() ?? 0;
      }

      notifyListeners();
    } catch (_) {
      _error = 'Failed to load unread count';
      notifyListeners();
    }
  }

  Future<void> acknowledgeAlert(String alertId) async {
    try {
      final api = await ApiService.getInstance();
      final res = await api.acknowledgeAlert(alertId);

      if (!res.success) {
        _error = res.message ?? 'Failed to acknowledge alert';
        notifyListeners();
        return;
      }

      for (var i = 0; i < _alerts.length; i++) {
        final a = _alerts[i];
        if (a.id == alertId) {
          final updated = Alert(
            id: a.id,
            deviceId: a.deviceId,
            alertType: a.alertType,
            gasLevelPpm: a.gasLevelPpm,
            message: a.message,
            isAcknowledged: true,
            acknowledgedAt: a.acknowledgedAt ?? DateTime.now(),
            timestamp: a.timestamp,
            deviceName: a.deviceName,
            location: a.location,
          );
          _alerts[i] = updated;
          break;
        }
      }

      if (_unreadCount > 0) {
        _unreadCount -= 1;
      }
      _error = null;
      notifyListeners();
    } catch (_) {
      _error = 'Failed to acknowledge alert';
      notifyListeners();
    }
  }

  Future<void> deleteAlert(String alertId) async {
    try {
      final api = await ApiService.getInstance();
      final res = await api.deleteAlert(alertId);

      if (!res.success) {
        _error = res.message ?? 'Failed to delete alert';
        notifyListeners();
        return;
      }

      _alerts.removeWhere((a) => a.id == alertId);
      notifyListeners();
    } catch (_) {
      _error = 'Failed to delete alert';
      notifyListeners();
    }
  }

  void addAlert(Alert alert) {
    _alerts.insert(0, alert);
    if (!alert.isAcknowledged) {
      _unreadCount += 1;
    }
    notifyListeners();
  }
}
