import '/core/constants/api/json_keys.dart';
import '../enum/gender_type.enum.dart';

/// Payload for updating account-level fields on `public.users`.
///
/// Strings are trimmed; empty optional strings are written as `null` or omitted.
class UserAccountRequest {
  const UserAccountRequest({
    this.name,
    this.email,
    this.phoneCode,
    this.phoneNumber,
    this.profileImageUrl,
    this.gender,
    this.isPushNotificationEnabled,
  });

  final String? name;
  final String? email;
  final String? phoneCode;
  final String? phoneNumber;
  final String? profileImageUrl;
  final GenderType? gender;
  final bool? isPushNotificationEnabled;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (name != null) JsonKeys.name: _nullIfEmpty(name),
      if (email != null) JsonKeys.email: _nullIfEmpty(email),
      if (phoneCode != null) JsonKeys.phoneCode: _nullIfEmpty(phoneCode),
      if (phoneNumber != null) JsonKeys.phoneNumber: _nullIfEmpty(phoneNumber),
      if (profileImageUrl != null)
        JsonKeys.profileImageUrl: _nullIfEmpty(profileImageUrl),
      if (gender != null) JsonKeys.gender: gender!.apiValue,
      JsonKeys.isPushNotificationEnabled: ?isPushNotificationEnabled,
    };
  }
}

String? _nullIfEmpty(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
