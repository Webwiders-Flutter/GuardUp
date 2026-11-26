import 'package:equatable/equatable.dart';

/// Events dispatched to [RegistrationFeeBloc].
sealed class RegistrationFeeEvent extends Equatable {
  const RegistrationFeeEvent();

  @override
  List<Object?> get props => [];
}

/// Processes the registration fee payment and submits the account for review.
final class RegistrationFeeSubmitted extends RegistrationFeeEvent {
  const RegistrationFeeSubmitted({this.discountNote});

  final String? discountNote;

  @override
  List<Object?> get props => [discountNote];
}
