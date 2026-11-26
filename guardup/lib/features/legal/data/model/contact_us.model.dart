import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/utils/json_converters/enum.jsonconverter.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '../enum/contact_us_status.enum.dart';

part 'contact_us.model.freezed.dart';
part 'contact_us.model.g.dart';

UserRole? _userRoleFromJson(dynamic value) {
  if (value == null) return null;
  return UserRole.values.fromValue(value);
}

String? _userRoleToJson(UserRole? role) => role?.apiValue;

ContactUsStatus _statusFromJson(dynamic value) {
  if (value == null) return ContactUsStatus.pending;
  return ContactUsStatus.values.parse(
    value,
    defaultValue: ContactUsStatus.pending,
  );
}

String _statusToJson(ContactUsStatus status) => status.apiValue;

/// One row of `public.contact_us`: user support inquiries.
@freezed
sealed class ContactUsModel with _$ContactUsModel {
  const factory ContactUsModel({
    required String id,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'role', fromJson: _userRoleFromJson, toJson: _userRoleToJson)
    UserRole? role,
    @JsonKey(name: 'full_name') required String fullName,
    required String email,
    required String message,
    @JsonKey(name: 'status', fromJson: _statusFromJson, toJson: _statusToJson)
    @Default(ContactUsStatus.pending)
    ContactUsStatus status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ContactUsModel;

  factory ContactUsModel.fromJson(Map<String, dynamic> json) =>
      _$ContactUsModelFromJson(json);
}

/// Data model representing a Contact Us user submission (legacy compatibility).
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
