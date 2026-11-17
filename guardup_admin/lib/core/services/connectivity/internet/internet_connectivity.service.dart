import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

abstract interface class ConnectivityService {
  Future<bool> isConnected();
  Stream<bool> get onConnectionChanged;
}

class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;
  final InternetConnection _internetConnection;

  ConnectivityServiceImpl({
    Connectivity? connectivity,
    InternetConnection? internetConnection,
  }) : _connectivity = connectivity ?? Connectivity(),
       _internetConnection = internetConnection ?? InternetConnection();

  @override
  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.every((r) => r == ConnectivityResult.none)) {
        return false;
      }
      return await _internetConnection.hasInternetAccess;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onConnectionChanged {
    final controller = StreamController<bool>.broadcast();
    StreamSubscription<InternetStatus>? statusSub;
    StreamSubscription<List<ConnectivityResult>>? connSub;

    controller.onListen = () {
      // 1. Listen to real Internet status changes (active reachability)
      statusSub = _internetConnection.onStatusChange.listen((status) {
        if (!controller.isClosed) {
          controller.add(status == InternetStatus.connected);
        }
      });

      // 2. Listen to network interface changes for instant hardware disconnects
      connSub = _connectivity.onConnectivityChanged.listen((results) async {
        if (results.every((r) => r == ConnectivityResult.none)) {
          if (!controller.isClosed) {
            controller.add(false);
          }
        } else {
          try {
            final hasAccess = await _internetConnection.hasInternetAccess;
            if (!controller.isClosed) {
              controller.add(hasAccess);
            }
          } catch (_) {
            if (!controller.isClosed) {
              controller.add(false);
            }
          }
        }
      });
    };

    controller.onCancel = () {
      statusSub?.cancel();
      connSub?.cancel();
    };

    return controller.stream.distinct();
  }
}
