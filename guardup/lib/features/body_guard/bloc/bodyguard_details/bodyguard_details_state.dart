import 'package:equatable/equatable.dart';

import '/core/state/api_state.dart';
import '../../data/model/body_guard.model.dart';

class BodyguardDetailsState extends Equatable {
  const BodyguardDetailsState({
    this.status = const ApiState.initial(),
    this.guard,
  });

  final ApiState<BodyGuardModel> status;

  /// Latest loaded or preview bodyguard model so the UI can render immediately
  /// while full joined details load in the background.
  final BodyGuardModel? guard;

  bool get isLoading => status.isLoading && guard == null;
  bool get isRefreshing => status.isLoading && guard != null;
  bool get isFailure => status.isFailure && guard == null;

  BodyguardDetailsState copyWith({
    ApiState<BodyGuardModel>? status,
    BodyGuardModel? guard,
  }) {
    return BodyguardDetailsState(
      status: status ?? this.status,
      guard: guard ?? this.guard,
    );
  }

  @override
  List<Object?> get props => [status, guard];
}
