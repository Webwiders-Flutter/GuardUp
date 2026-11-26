import 'package:equatable/equatable.dart';

import '/core/state/api_state.dart';
import '../../data/model/transaction.model.dart';

/// Immutable state for [RegistrationFeeBloc].
final class RegistrationFeeState extends Equatable {
  const RegistrationFeeState({
    this.paymentStatus = const ApiState.initial(),
  });

  final ApiState<TransactionModel> paymentStatus;

  RegistrationFeeState copyWith({
    ApiState<TransactionModel>? paymentStatus,
  }) {
    return RegistrationFeeState(
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  @override
  List<Object?> get props => [paymentStatus];
}
