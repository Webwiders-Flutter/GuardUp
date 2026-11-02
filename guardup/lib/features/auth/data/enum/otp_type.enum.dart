import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

enum OtpType {
  @JsonValue('SMS')
  sms('SMS'),

  @JsonValue('EMAIL')
  email('EMAIL'),

  @JsonValue('MAGIC_LINK')
  magicLink('MAGIC_LINK'),

  @JsonValue('RECOVERY')
  recovery('RECOVERY'),

  @JsonValue('PHONE_CHANGE')
  phoneChange('PHONE_CHANGE'),

  @JsonValue('EMAIL_CHANGE')
  emailChange('EMAIL_CHANGE');

  final String apiValue;

  const OtpType(this.apiValue);

  static OtpType fromApiValue(String? value) {
    if (value == null) return OtpType.sms;
    return OtpType.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => OtpType.sms,
    );
  }

  static OtpType? tryFromApiValue(String? value) {
    if (value == null) return null;
    try {
      return OtpType.values.firstWhere(
        (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  String get label {
    switch (this) {
      case OtpType.sms:
        return 'SMS';
      case OtpType.email:
        return 'Email';
      case OtpType.magicLink:
        return 'Magic Link';
      case OtpType.recovery:
        return 'Password Recovery';
      case OtpType.phoneChange:
        return 'Phone Number Change';
      case OtpType.emailChange:
        return 'Email Change';
    }
  }

  IconData get icon {
    switch (this) {
      case OtpType.sms:
        return Icons.sms_outlined;
      case OtpType.email:
        return Icons.email_outlined;
      case OtpType.magicLink:
        return Icons.link_outlined;
      case OtpType.recovery:
        return Icons.lock_reset_outlined;
      case OtpType.phoneChange:
        return Icons.phone_android_outlined;
      case OtpType.emailChange:
        return Icons.mark_email_read_outlined;
    }
  }
}
