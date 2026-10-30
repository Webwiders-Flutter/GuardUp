import 'package:flutter/material.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';

class AppValidators {
  /// EMAIL VALIDATION
  static String? email(String? value, {BuildContext? context}) {
    if (value == null || value.trim().isEmpty) {
      return context?.l10n.validationEmailRequired ?? 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.\\+]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(value.trim())) {
      return context?.l10n.validationEmailInvalid ?? 'Enter valid email';
    }

    return null;
  }

  /// PASSWORD VALIDATION
  static String? password(String? value, {BuildContext? context}) {
    if (value == null || value.isEmpty) {
      return context?.l10n.validationPasswordRequired ?? 'Password is required';
    }

    if (value.contains(' ')) {
      return context?.l10n.validationNoSpaces ?? 'Spaces are not allowed';
    }

    if (value.length < 6) {
      return context?.l10n.validationPasswordMinLength ??
          'Password must be at least 6 characters';
    }

    return null;
  }

  /// CONFIRM PASSWORD VALIDATION
  static String? confirmPassword(
    String? value,
    String password, {
    BuildContext? context,
  }) {
    if (value == null || value.isEmpty) {
      return context?.l10n.validationConfirmPasswordRequired ??
          'Confirm password is required';
    }

    if (value != password) {
      return context?.l10n.validationPasswordsNotMatch ??
          'Passwords do not match';
    }

    return null;
  }

  /// NAME VALIDATION
  static String? name(String? value, {BuildContext? context}) {
    if (value == null || value.trim().isEmpty) {
      return context?.l10n.validationNameRequired ?? 'Name is required';
    }

    if (value.trim().length < 2) {
      return context?.l10n.validationNameInvalid ?? 'Enter valid name';
    }

    return null;
  }

  /// PHONE VALIDATION
  static String? phone(String? value, {BuildContext? context}) {
    if (value == null || value.trim().isEmpty) {
      return context?.l10n.validationPhoneRequired ??
          'Phone number is required';
    }

    // Remove spaces
    value = value.trim();

    // Only digits allowed
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return context?.l10n.validationPhoneDigitsOnly ??
          'Only digits are allowed';
    }

    // Must be 10 digits
    if (value.length != 10) {
      return context?.l10n.validationPhoneLength ??
          'Phone number must be 10 digits';
    }

    return null;
  }

  /// DOB VALIDATION
  static String? dateOfBirth(String? value, {BuildContext? context}) {
    if (value == null || value.trim().isEmpty) {
      return context?.l10n.validationDobRequired ?? 'Date of birth is required';
    }
    return null;
  }

  /// PASSPORT VALIDATION
  static String? passport(String? value, {BuildContext? context}) {
    if (value == null || value.trim().isEmpty) {
      return context?.l10n.validationPassportRequired ??
          'Passport number is required';
    }

    // Alphanumeric validation
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value.trim())) {
      return context?.l10n.validationPassportInvalid ??
          'Enter valid passport number';
    }

    if (value.trim().length < 5) {
      return context?.l10n.validationPassportTooShort ??
          'Passport number is too short';
    }

    if (value.trim().length > 20) {
      return context?.l10n.validationPassportTooLong ??
          'Passport number is too long';
    }

    return null;
  }
}
