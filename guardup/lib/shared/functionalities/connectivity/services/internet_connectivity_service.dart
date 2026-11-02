import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

abstract interface class ConnectivityService {
  Future<bool> isConnected();
  Stream<bool> get onConnectionChanged;
  void dispose();
}

class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;
  StreamController<bool>? _controller;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityServiceImpl({
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (_isNone(results)) {
        return false;
      }
      return await _checkInternetAccess();
    } catch (_) {
      return false;
    }
  }

  bool _isNone(List<ConnectivityResult> results) {
    return results.isEmpty || results.every((r) => r == ConnectivityResult.none);
  }

  Future<bool> _checkInternetAccess() async {
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onConnectionChanged {
    _controller ??= StreamController<bool>.broadcast(
      onListen: () {
        _subscription = _connectivity.onConnectivityChanged.listen((results) async {
          if (_isNone(results)) {
            _controller?.add(false);
          } else {
            final hasAccess = await _checkInternetAccess();
            _controller?.add(hasAccess);
          }
        });
      },
      onCancel: () {
        _subscription?.cancel();
        _subscription = null;
      },
    );
    return _controller!.stream.distinct();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _controller?.close();
    _controller = null;
  }
}

