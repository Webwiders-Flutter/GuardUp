import 'package:equatable/equatable.dart';

import '/core/state/api_state.dart';

/// State representation for Contact Us submission.
class ContactUsState extends Equatable {
  final ApiState<String> submissionState;

  const ContactUsState({this.submissionState = const ApiState.initial()});

  ContactUsState copyWith({ApiState<String>? submissionState}) {
    return ContactUsState(
      submissionState: submissionState ?? this.submissionState,
    );
  }

  @override
  List<Object?> get props => [submissionState];
}
