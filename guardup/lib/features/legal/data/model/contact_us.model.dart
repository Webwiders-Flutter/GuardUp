import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_us.model.freezed.dart';
part 'contact_us.model.g.dart';

/// Data model representing a Contact Us user submission.
@freezed
abstract class ContactUsSubmission with _$ContactUsSubmission {
  const factory ContactUsSubmission({
    required String fullName,
    required String email,
    @Default('+1') String phoneCode,
    required String mobileNumber,
    required String message,
    required DateTime submittedAt,
  }) = _ContactUsSubmission;

  factory ContactUsSubmission.fromJson(Map<String, dynamic> json) =>
      _$ContactUsSubmissionFromJson(json);
}
