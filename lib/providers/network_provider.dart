import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<dynamic>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  NetworkProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    final dynamic initialStatus = await _connectivity.checkConnectivity();
    _handleStatusUpdate(initialStatus);

    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleStatusUpdate,
    );
  }

  void _handleStatusUpdate(dynamic status) {
    final List<ConnectivityResult> results;
    if (status is List<ConnectivityResult>) {
      results = status;
    } else if (status is ConnectivityResult) {
      results = <ConnectivityResult>[status];
    } else {
      results = const <ConnectivityResult>[ConnectivityResult.none];
    }

    final online = results.any((result) => result != ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
