import 'package:equatable/equatable.dart';

abstract class BodyguardDetailsEvent extends Equatable {
  const BodyguardDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched on screen start to load full bodyguard details.
final class BodyguardDetailsStarted extends BodyguardDetailsEvent {
  const BodyguardDetailsStarted();
}

/// Dispatched to refresh bodyguard details (e.g. after edit or retry).
final class BodyguardDetailsRefreshed extends BodyguardDetailsEvent {
  const BodyguardDetailsRefreshed();
}
