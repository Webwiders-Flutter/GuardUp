import 'package:equatable/equatable.dart';

/// Data model representing a Contact Us user submission.
class ContactUsSubmission extends Equatable {
  final String fullName;
  final String email;
  final String phoneCode;
  final String mobileNumber;
  final String message;
  final DateTime submittedAt;

  const ContactUsSubmission({
    required this.fullName,
    required this.email,
    this.phoneCode = '+1',
    required this.mobileNumber,
    required this.message,
    required this.submittedAt,
  });

  @override
  List<Object?> get props => [
    fullName,
    email,
    phoneCode,
    mobileNumber,
    message,
    submittedAt,
  ];
}

