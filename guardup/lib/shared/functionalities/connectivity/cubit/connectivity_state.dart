import 'package:equatable/equatable.dart';

enum ConnectivityStatus { initial, connected, disconnected }

class ConnectivityState extends Equatable {
  final ConnectivityStatus status;
  final bool isChecking;

  const ConnectivityState({
    this.status = ConnectivityStatus.initial,
    this.isChecking = false,
  });

  bool get isConnected => status == ConnectivityStatus.connected;
  bool get isDisconnected => status == ConnectivityStatus.disconnected;
  bool get isInitial => status == ConnectivityStatus.initial;

  ConnectivityState copyWith({ConnectivityStatus? status, bool? isChecking}) {
    return ConnectivityState(
      status: status ?? this.status,
      isChecking: isChecking ?? this.isChecking,
    );
  }

  @override
  List<Object?> get props => [status, isChecking];
}
