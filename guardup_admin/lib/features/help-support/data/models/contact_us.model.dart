import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../users/data/enums/user_role.enum.dart';

part 'contact_us.model.freezed.dart';
part 'contact_us.model.g.dart';

@freezed
sealed class ContactUs with _$ContactUs {
  const factory ContactUs({
    required String id,
    required String fullName,
    String? email,
    @Default('+91') String phoneCode,
    required String mobileNumber,
    UserRoleType? role,
    required String message,
    @Default(false) bool isResolved,
    String? createdAt,
    String? updatedAt,
  }) = _ContactUs;

  factory ContactUs.fromJson(Map<String, dynamic> json) =>
      _$ContactUsFromJson(json);
}
