import 'package:flutter/foundation.dart';

import '../models/device.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class DeviceProvider extends ChangeNotifier {
  final StorageService _storage;

  DeviceProvider(this._storage);

  final List<Device> _devices = <Device>[];
  Device? _selectedDevice;
  bool _isLoading = false;
  String? _error;

  List<Device> get devices => List.unmodifiable(_devices);
  Device? get selectedDevice => _selectedDevice;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await ApiService.getInstance();
      final res = await api.getDevices();

      if (!res.success) {
        _devices.clear();
        _error = res.message ?? 'Failed to load devices';
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

      _devices
        ..clear()
        ..addAll(list.map((item) {
          if (item is Map<String, dynamic>) {
            return Device.fromJson(item);
          }
          if (item is Map) {
            return Device.fromJson(Map<String, dynamic>.from(item));
          }
          return null;
        }).whereType<Device>());

      final savedId = _storage.getSelectedDevice();
      if (savedId != null) {
        Device? found;
        for (final d in _devices) {
          if (d.id == savedId || d.deviceId == savedId) {
            found = d;
            break;
          }
        }
        _selectedDevice = found ?? (_devices.isNotEmpty ? _devices.first : null);
      } else {
        _selectedDevice = _devices.isNotEmpty ? _devices.first : null;
      }
    } catch (_) {
      _devices.clear();
      _error = 'Failed to load devices';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Device?> registerDevice(Map<String, dynamic> deviceData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await ApiService.getInstance();
      final res = await api.registerDevice(deviceData);

      if (!res.success || res.data == null) {
        _error = res.message ?? 'Failed to register device';
        return null;
      }

      dynamic data = res.data;
      if (data is Map<String, dynamic> && data['device'] is Map<String, dynamic>) {
        data = data['device'];
      }

      Map<String, dynamic>? json;
      if (data is Map<String, dynamic>) {
        json = data;
      } else if (data is Map) {
        json = Map<String, dynamic>.from(data);
      }

      if (json == null) {
        _error = 'Invalid device data';
        return null;
      }

      final device = Device.fromJson(json);
      _devices.add(device);
      selectDevice(device);
      return device;
    } catch (_) {
      _error = 'Failed to register device';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDevice(String deviceId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await ApiService.getInstance();
      final res = await api.updateDevice(deviceId, data);

      if (!res.success || res.data == null) {
        _error = res.message ?? 'Failed to update device';
        return;
      }

      Map<String, dynamic>? json;
      if (res.data is Map<String, dynamic>) {
        json = res.data as Map<String, dynamic>;
      } else if (res.data is Map) {
        json = Map<String, dynamic>.from(res.data as Map);
      }

      if (json == null) {
        _error = 'Invalid device data';
        return;
      }

      final updated = Device.fromJson(json);
      for (var i = 0; i < _devices.length; i++) {
        if (_devices[i].id == updated.id ||
            _devices[i].deviceId == updated.deviceId) {
          _devices[i] = updated;
          break;
        }
      }

      if (_selectedDevice != null &&
          (_selectedDevice!.id == updated.id ||
              _selectedDevice!.deviceId == updated.deviceId)) {
        _selectedDevice = updated;
        await _storage.saveSelectedDevice(updated.id);
      }
    } catch (_) {
      _error = 'Failed to update device';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await ApiService.getInstance();
      final res = await api.deleteDevice(deviceId);

      if (!res.success) {
        _error = res.message ?? 'Failed to delete device';
        return;
      }

      _devices.removeWhere(
        (d) => d.id == deviceId || d.deviceId == deviceId,
      );

      if (_selectedDevice != null &&
          (_selectedDevice!.id == deviceId ||
              _selectedDevice!.deviceId == deviceId)) {
        if (_devices.isNotEmpty) {
          _selectedDevice = _devices.first;
          await _storage.saveSelectedDevice(_selectedDevice!.id);
        } else {
          _selectedDevice = null;
          await _storage.saveSelectedDevice('');
        }
      }
    } catch (_) {
      _error = 'Failed to delete device';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDevice(Device device) {
    _selectedDevice = device;
    _storage.saveSelectedDevice(device.id);
    notifyListeners();
  }

  Device? getDeviceById(String deviceId) {
    for (final d in _devices) {
      if (d.id == deviceId || d.deviceId == deviceId) {
        return d;
      }
    }
    return null;
  }
}
