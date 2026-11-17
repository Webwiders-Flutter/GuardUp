import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'internet_connectivity.provider.dart';
import '/core/services/connectivity/internet/internet_connectivity.service.dart';

class ConnectivityController extends Notifier<bool> {
  late final ConnectivityService _service;
  StreamSubscription<bool>? _subscription;

  @override
  bool build() {
    _service = ref.read(connectivityServiceProvider);

    _subscription = _service.onConnectionChanged.listen((connected) {
      state = connected;
    });

    ref.onDispose(() => _subscription?.cancel());

    _checkInitial();

    return true;
  }

  Future<void> _checkInitial() async {
    try {
      final isConnected = await _service.isConnected();
      state = isConnected;
    } catch (_) {
      state = true;
    }
  }

  /// Manually force a connection check (e.g. from user "Retry" button).
  Future<bool> checkConnection() async {
    try {
      final isConnected = await _service.isConnected();
      state = isConnected;
      return isConnected;
    } catch (_) {
      return state;
    }
  }
}
