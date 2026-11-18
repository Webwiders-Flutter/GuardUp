import 'package:flutter/widgets.dart';

import '../extensions/localization.extension.dart';

import '/core/constants/app_regx.dart';

final class Validators {
  Validators._();

  /// Required field
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

  /// Email validation
  static String? email(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.emailRequired;
    }

    if (!AppRegex.email.hasMatch(value.trim())) {
      return context.l10n.enterValidEmail;
    }

    return null;
  }

  /// Password validation
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

  /// Strong password (optional advanced)
  static String? strongPassword(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.l10n.passwordRequired;
    }

    if (!AppRegex.strongPassword.hasMatch(value)) {
      return context.l10n.strongPasswordError;
    }

    return null;
  }

  /// Phone number (supports standard 10-digit and international with country code)
  static String? phone(
    BuildContext context,
    String? value, {
    bool allowCountryCode = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.phoneRequired;
    }

    final trimmed = value.trim();
    final regex = allowCountryCode ? AppRegex.phone : RegExp(r'^[0-9]{10}$');

    if (!regex.hasMatch(trimmed)) {
      return context.l10n.enterValidPhone;
    }

    return null;
  }

  /// URL validation
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
      return 'Please enter a valid URL';
    }

    return null;
  }

  /// Version validation (e.g. 1.0.0)
  static String? version(
    BuildContext context,
    String? value, {
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.fieldRequired(fieldName ?? context.l10n.thisField);
    }

    final trimmed = value.trim();
    final versionRegex = RegExp(r'^\d+(\.\d+)*$');
    if (!versionRegex.hasMatch(trimmed)) {
      return '${fieldName ?? "Version"} must follow version format (e.g. 1.0.0)';
    }

    return null;
  }

  /// Min length
  static String? minLength(BuildContext context, String? value, int length) {
    if (value == null || value.length < length) {
      return context.l10n.minLengthError(length);
    }
    return null;
  }

  /// Max length
  static String? maxLength(BuildContext context, String? value, int length) {
    if (value != null && value.length > length) {
      return context.l10n.maxLengthError(length);
    }
    return null;
  }

  /// Number validation (integers or decimals) with optional bounds.
  ///
  /// - [isRequired] `false` treats an empty value as valid.
  /// - [minExclusive] rejects values equal to [min] (e.g. "must be more than 0").
  /// - [integerOnly] rejects decimals such as `2.5`.
  static String? number(
    BuildContext context,
    String? value, {
    num? min,
    num? max,
    bool minExclusive = false,
    bool integerOnly = false,
    bool isRequired = true,
    String? fieldName,
  }) {
    final name = fieldName ?? context.l10n.thisField;
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return isRequired ? context.l10n.fieldRequired(name) : null;
    }

    final num? parsed = integerOnly ? int.tryParse(text) : num.tryParse(text);
    if (parsed == null) {
      return context.l10n.enterValidNumber;
    }

    if (min != null && max != null && !minExclusive) {
      if (parsed < min || parsed > max) {
        if (min == max) return '$name must be ${_formatBound(min)}';
        return '$name must be between ${_formatBound(min)} and ${_formatBound(max)}';
      }
      return null;
    }

    if (min != null) {
      if (minExclusive && parsed <= min) {
        return '$name must be more than ${_formatBound(min)}';
      }
      if (!minExclusive && parsed < min) {
        return '$name must be at least ${_formatBound(min)}';
      }
    }

    if (max != null && parsed > max) {
      return '$name cannot be greater than ${_formatBound(max)}';
    }

    return null;
  }

  static String _formatBound(num value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();

  /// Confirm password
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

  /// Multiple validators
  static String? combine(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) return result;
    }
    return null;
  }
}
