import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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

  /// URL-friendly path identifier for public routing.
  String get slug {
    switch (this) {
      case ContentType.terms:
        return 'terms';
      case ContentType.aboutUs:
        return 'about-us';
      case ContentType.privacyPolicy:
        return 'privacy-policy';
      case ContentType.deleteAccount:
        return 'delete-account';
      case ContentType.support:
        return 'support';
    }
  }

  /// Resolves [ContentType] from a URL slug or API value with safe fallback.
  static ContentType fromSlug(String slug) {
    final normalized = slug.toLowerCase().trim();
    return ContentType.values.firstWhere(
      (e) => e.slug == normalized || e.apiValue.toLowerCase() == normalized,
      orElse: () => ContentType.terms,
    );
  }

  /// Safely resolves [ContentType] from a nullable URL slug.
  static ContentType? tryFromSlug(String? slug) {
    if (slug == null || slug.isEmpty) return null;
    final normalized = slug.toLowerCase().trim();
    try {
      return ContentType.values.firstWhere(
        (e) => e.slug == normalized || e.apiValue.toLowerCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  /// Static function returning the display label for a given [ContentType].
  String get label {
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
        return 'Support';
    }
  }

  String get description {
    switch (this) {
      case ContentType.terms:
        return 'Platform service terms and legal clauses';
      case ContentType.aboutUs:
        return 'Company information and platform background';
      case ContentType.privacyPolicy:
        return 'Data protection and user privacy guidelines';
      case ContentType.deleteAccount:
        return 'User account deletion terms, procedure, and data retention policy';
      case ContentType.support:
        return 'Platform customer support details, contact lines, and help assistance';
    }
  }

  /// Associated icon for UI navigation and display.
  IconData get icon {
    switch (this) {
      case ContentType.terms:
        return Icons.gavel_rounded;
      case ContentType.privacyPolicy:
        return Icons.shield_outlined;
      case ContentType.aboutUs:
        return Icons.info_outline_rounded;
      case ContentType.deleteAccount:
        return Icons.person_remove_outlined;
      case ContentType.support:
        return Icons.contact_support_outlined;
    }
  }
}
