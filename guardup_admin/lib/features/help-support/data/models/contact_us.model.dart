import 'package:freezed_annotation/freezed_annotation.dart';

import '/features/help-support/data/enums/contact_us_status.enum.dart';
import '/features/users/data/enums/user_role.enum.dart';

part 'contact_us.model.freezed.dart';
part 'contact_us.model.g.dart';

/// One row of `contact_us`: a support request sent from the app.
@freezed
sealed class ContactUs with _$ContactUs {
  const factory ContactUs({
    required String id,

    /// Sender's account; null for guests or when the user was deleted.
    String? userId,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    UserRoleType? role,
    required String fullName,
    required String email,
    required String message,
    @Default(ContactUsStatus.pending)
    @JsonKey(unknownEnumValue: ContactUsStatus.pending)
    ContactUsStatus status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ContactUs;

  factory ContactUs.fromJson(Map<String, dynamic> json) =>
      _$ContactUsFromJson(json);
}
