import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/internet_connectivity_service.dart';
import 'connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final ConnectivityService _service;
  StreamSubscription<bool>? _subscription;

  ConnectivityCubit({ConnectivityService? service})
      : _service = service ?? ConnectivityServiceImpl(),
        super(const ConnectivityState()) {
    _init();
  }

  void _init() {
    _subscription = _service.onConnectionChanged.listen((connected) {
      emit(
        state.copyWith(
          status: connected
              ? ConnectivityStatus.connected
              : ConnectivityStatus.disconnected,
        ),
      );
    });

    _checkInitial();
  }

  Future<void> _checkInitial() async {
    try {
      final isConnected = await _service.isConnected();
      emit(
        state.copyWith(
          status: isConnected
              ? ConnectivityStatus.connected
              : ConnectivityStatus.disconnected,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: ConnectivityStatus.connected));
    }
  }

  /// Manually force a connection check (e.g. from user "Retry" button).
  Future<bool> checkConnection() async {
    emit(state.copyWith(isChecking: true));
    try {
      final isConnected = await _service.isConnected();
      emit(
        state.copyWith(
          status: isConnected
              ? ConnectivityStatus.connected
              : ConnectivityStatus.disconnected,
          isChecking: false,
        ),
      );
      return isConnected;
    } catch (_) {
      emit(state.copyWith(isChecking: false));
      return state.isConnected;
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _service.dispose();
    return super.close();
  }
}

