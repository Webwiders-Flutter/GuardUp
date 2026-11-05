import 'package:flutter/widgets.dart';

import '../extensions/localization.extension.dart';
import '/core/constants/app_regx.dart';

final class Validators {
  Validators._();

  // ---------------------------------------------------------------------------
  // Common
  // ---------------------------------------------------------------------------

  /// Required field.
  static String? required(
    BuildContext context,
    String? value, {
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.fieldRequired(fieldName ?? context.l10n.thisField);
    }

    return null;
  }

  /// Minimum length.
  static String? minLength(BuildContext context, String? value, int length) {
    if (value == null || value.length < length) {
      return context.l10n.minLengthError(length);
    }

    return null;
  }

  /// Maximum length.
  static String? maxLength(BuildContext context, String? value, int length) {
    if (value != null && value.length > length) {
      return context.l10n.maxLengthError(length);
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Name / Text
  // ---------------------------------------------------------------------------

  /// Person name.
  static String? name(
    BuildContext context,
    String? value, {
    bool isOptional = false,
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (isOptional) return null;

      return context.l10n.fieldRequired(fieldName ?? context.l10n.thisField);
    }

    if (!AppRegex.name.hasMatch(value.trim())) {
      return context.l10n.enterValidName;
    }

    return null;
  }

  /// Business / company name.
  static String? businessName(
    BuildContext context,
    String? value, {
    bool isOptional = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (isOptional) return null;

      return context.l10n.fieldRequired(context.l10n.businessName);
    }

    if (!AppRegex.businessName.hasMatch(value.trim())) {
      return context.l10n.enterValidBusinessName;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Email / Password
  // ---------------------------------------------------------------------------

  /// Email validation.
  static String? email(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.emailRequired;
    }

    if (!AppRegex.email.hasMatch(value.trim())) {
      return context.l10n.enterValidEmail;
    }

    return null;
  }

  /// Password validation.
  static String? password(
    BuildContext context,
    String? value, {
    int minLength = 6,
  }) {
    if (value == null || value.isEmpty) {
      return context.l10n.passwordRequired;
    }

    if (value.length < minLength) {
      return context.l10n.passwordMinLengthError(minLength);
    }

    return null;
  }

  /// Strong password validation.
  static String? strongPassword(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.l10n.passwordRequired;
    }

    if (!AppRegex.strongPassword.hasMatch(value)) {
      return context.l10n.strongPasswordError;
    }

    return null;
  }

  /// Confirm password.
  static String? confirmPassword(
    BuildContext context,
    String? value,
    String original,
  ) {
    if (value == null || value.isEmpty) {
      return context.l10n.pleaseConfirmPassword;
    }

    if (value != original) {
      return context.l10n.passwordsDoNotMatch;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Phone
  // ---------------------------------------------------------------------------

  /// Phone number.
  static String? phone(
    BuildContext context,
    String? value, {
    bool allowCountryCode = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.phoneRequired;
    }

    final trimmed = value.trim();

    final regex = allowCountryCode ? AppRegex.phone : AppRegex.indianPhone;

    if (!regex.hasMatch(trimmed)) {
      return context.l10n.enterValidPhone;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Indian Government / Business IDs
  // ---------------------------------------------------------------------------

  /// PAN card number.
  ///
  /// Example: ABCDE1234F
  static String? pan(
    BuildContext context,
    String? value, {
    bool isOptional = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (isOptional) return null;

      return context.l10n.panRequired;
    }

    final trimmed = value.trim().toUpperCase();

    if (!AppRegex.pan.hasMatch(trimmed)) {
      return context.l10n.enterValidPan;
    }

    return null;
  }

  /// GSTIN.
  ///
  /// Example: 22AAAAA0000A1Z5
  static String? gst(
    BuildContext context,
    String? value, {
    bool isOptional = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (isOptional) return null;

      return context.l10n.gstRequired;
    }

    final trimmed = value.trim().toUpperCase();

    if (!AppRegex.gstin.hasMatch(trimmed)) {
      return context.l10n.enterValidGst;
    }

    return null;
  }

  /// Aadhaar number.
  static String? aadhaar(
    BuildContext context,
    String? value, {
    bool isOptional = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (isOptional) return null;

      return context.l10n.aadhaarRequired;
    }

    final trimmed = value.trim();

    if (!AppRegex.aadhaar.hasMatch(trimmed)) {
      return context.l10n.enterValidAadhaar;
    }

    return null;
  }

  /// Indian IFSC code.
  ///
  /// Example: SBIN0001234
  static String? ifsc(
    BuildContext context,
    String? value, {
    bool isOptional = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (isOptional) return null;

      return context.l10n.ifscRequired;
    }

    final trimmed = value.trim().toUpperCase();

    if (!AppRegex.ifsc.hasMatch(trimmed)) {
      return context.l10n.enterValidIfsc;
    }

    return null;
  }

  /// Indian PIN code.
  static String? pincode(
    BuildContext context,
    String? value, {
    bool isOptional = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (isOptional) return null;

      return context.l10n.pincodeRequired;
    }

    if (!AppRegex.indianPincode.hasMatch(value.trim())) {
      return context.l10n.enterValidPincode;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Vehicle / Transport
  // ---------------------------------------------------------------------------

  /// Vehicle / Truck registration number validation (Indian format e.g. MH 12 AB 1234, DL 01 A 1234, 22 BH 1234 AA, MP 09 1234).
  static String? vehicleNumber(
    BuildContext context,
    String? value, {
    bool isOptional = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (isOptional) return null;

      return context.l10n.pleaseEnterOrSelectVehicleNumber;
    }

    final trimmed = value.trim().toUpperCase().replaceAll(
      RegExp(r'[\s\-]'),
      '',
    );

    if (!AppRegex.vehicleNumber.hasMatch(trimmed)) {
      return context.l10n.enterValidVehicleNumber;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Banking
  // ---------------------------------------------------------------------------

  /// Bank account number.
  static String? bankAccountNumber(
    BuildContext context,
    String? value, {
    bool isOptional = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (isOptional) return null;

      return context.l10n.bankAccountNumberRequired;
    }

    final trimmed = value.trim();

    if (!AppRegex.bankAccountNumber.hasMatch(trimmed)) {
      return context.l10n.enterValidBankAccountNumber;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Number
  // ---------------------------------------------------------------------------

  /// Number validation.
  static String? number(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.l10n.thisFieldRequired;
    }

    if (double.tryParse(value) == null) {
      return context.l10n.enterValidNumber;
    }

    return null;
  }

  /// Positive number.
  static String? positiveNumber(
    BuildContext context,
    String? value, {
    String? fieldName,
  }) {
    final error = number(context, value);

    if (error != null) return error;

    final parsed = double.parse(value!.trim());

    if (parsed <= 0) {
      return '${fieldName ?? context.l10n.thisField} must be greater than 0';
    }

    return null;
  }

  /// Integer validation with optional bounds.
  static String? integer(
    BuildContext context,
    String? value, {
    int? min,
    int? max,
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.fieldRequired(fieldName ?? context.l10n.thisField);
    }

    final parsed = int.tryParse(value.trim());

    if (parsed == null) {
      return context.l10n.enterValidNumber;
    }

    final name = fieldName ?? context.l10n.thisField;

    if (min != null && max != null && (parsed < min || parsed > max)) {
      if (min == max) return '$name must be $min';

      return '$name must be between $min and $max';
    }

    if (min != null && parsed < min) {
      return '$name must be at least $min';
    }

    if (max != null && parsed > max) {
      return '$name cannot be greater than $max';
    }

    return null;
  }

  /// Percentage between 0 and 100.
  static String? percentage(
    BuildContext context,
    String? value, {
    String? fieldName,
  }) {
    return numberRange(context, value, min: 0, max: 100, fieldName: fieldName);
  }

  /// Number within a range.
  static String? numberRange(
    BuildContext context,
    String? value, {
    double? min,
    double? max,
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.fieldRequired(fieldName ?? context.l10n.thisField);
    }

    final parsed = double.tryParse(value.trim());

    if (parsed == null) {
      return context.l10n.enterValidNumber;
    }

    final name = fieldName ?? context.l10n.thisField;

    if (min != null && max != null && (parsed < min || parsed > max)) {
      return '$name must be between $min and $max';
    }

    if (min != null && parsed < min) {
      return '$name must be at least $min';
    }

    if (max != null && parsed > max) {
      return '$name cannot be greater than $max';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // URL / Version
  // ---------------------------------------------------------------------------

  /// URL validation.
  static String? url(
    BuildContext context,
    String? value, {
    bool isOptional = false,
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (isOptional) return null;

      return context.l10n.fieldRequired(fieldName ?? context.l10n.thisField);
    }

    final trimmed = value.trim();

    if (!AppRegex.url.hasMatch(trimmed) &&
        !trimmed.startsWith('https://') &&
        !trimmed.startsWith('http://')) {
      return context.l10n.enterValidUrl;
    }

    return null;
  }

  /// Version validation.
  ///
  /// Example: 1.0.0
  static String? version(
    BuildContext context,
    String? value, {
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.fieldRequired(fieldName ?? context.l10n.thisField);
    }

    if (!AppRegex.version.hasMatch(value.trim())) {
      return context.l10n.enterValidVersion;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Combination
  // ---------------------------------------------------------------------------

  /// Runs validators in order and returns the first error.
  static String? combine(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final result = validator(value);

      if (result != null) {
        return result;
      }
    }

    return null;
  }
}
