import 'package:equatable/equatable.dart';

import '../../data/model/contact_us.model.dart';

abstract class ContactUsEvent extends Equatable {
  const ContactUsEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched when submitting a Contact Us inquiry.
class SubmitContactUsRequested extends ContactUsEvent {
  final ContactUsSubmission submission;

  const SubmitContactUsRequested(this.submission);

  @override
  List<Object?> get props => [submission];
}
