import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/extensions/context.extension.dart';
import '/gen/app_localizations.dart';

/// Semantic content types for legal and support documentation.
enum ContentType {
  @JsonValue('TERMS')
  terms('TERMS'),

  @JsonValue('ABOUT_US')
  aboutUs('ABOUT_US'),

  @JsonValue('PRIVACY_POLICY')
  privacyPolicy('PRIVACY_POLICY'),

  @JsonValue('DELETE_ACCOUNT')
  deleteAccount('DELETE_ACCOUNT'),

  @JsonValue('SUPPORT')
  support('SUPPORT');

  final String apiValue;

  const ContentType(this.apiValue);

  String label(AppLocalizations l10n) {
    switch (this) {
      case ContentType.terms:
        return 'Terms & Conditions';
      case ContentType.aboutUs:
        return 'About Us';
      case ContentType.privacyPolicy:
        return 'Privacy Policy';
      case ContentType.deleteAccount:
        return 'Delete Account';
      case ContentType.support:
        return 'Help & Support';
    }
  }

  static ContentType fromApiValue(String? value) {
    if (value == null) return ContentType.terms;
    return ContentType.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => ContentType.terms,
    );
  }

  static ContentType? tryFromApiValue(String? value) {
    if (value == null) return null;
    try {
      return ContentType.values.firstWhere(
        (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  Color color(BuildContext context) {
    final colors = context.colors;
    switch (this) {
      case ContentType.terms:
        return colors.primary;
      case ContentType.aboutUs:
        return colors.info;
      case ContentType.privacyPolicy:
        return colors.primary;
      case ContentType.deleteAccount:
        return colors.error;
      case ContentType.support:
        return colors.warning;
    }
  }

  Color backgroundColor(BuildContext context) {
    final colors = context.colors;
    switch (this) {
      case ContentType.terms:
        return colors.primaryContainer;
      case ContentType.aboutUs:
        return colors.infoContainer;
      case ContentType.privacyPolicy:
        return colors.primaryContainer;
      case ContentType.deleteAccount:
        return colors.errorContainer;
      case ContentType.support:
        return colors.warningContainer;
    }
  }

  IconData get icon {
    switch (this) {
      case ContentType.terms:
        return Icons.gavel_rounded;
      case ContentType.privacyPolicy:
        return Icons.shield_outlined;
      case ContentType.aboutUs:
        return Icons.info_outline_rounded;
      case ContentType.deleteAccount:
        return Icons.delete_outline_rounded;
      case ContentType.support:
        return Icons.support_agent_rounded;
    }
  }
}

