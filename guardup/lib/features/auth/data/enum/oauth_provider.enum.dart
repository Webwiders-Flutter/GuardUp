import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

enum OAuthProvider {
  @JsonValue('GOOGLE')
  google('GOOGLE'),

  @JsonValue('APPLE')
  apple('APPLE'),

  @JsonValue('FACEBOOK')
  facebook('FACEBOOK'),

  @JsonValue('GITHUB')
  github('GITHUB'),

  @JsonValue('TWITTER')
  twitter('TWITTER');

  final String apiValue;

  const OAuthProvider(this.apiValue);

  static OAuthProvider fromApiValue(String? value) {
    if (value == null) return OAuthProvider.google;
    return OAuthProvider.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => OAuthProvider.google,
    );
  }

  static OAuthProvider? tryFromApiValue(String? value) {
    if (value == null) return null;
    try {
      return OAuthProvider.values.firstWhere(
        (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  String get label {
    switch (this) {
      case OAuthProvider.google:
        return 'Google';
      case OAuthProvider.apple:
        return 'Apple';
      case OAuthProvider.facebook:
        return 'Facebook';
      case OAuthProvider.github:
        return 'GitHub';
      case OAuthProvider.twitter:
        return 'Twitter';
    }
  }

  IconData get icon {
    switch (this) {
      case OAuthProvider.google:
        return Icons.g_mobiledata_rounded;
      case OAuthProvider.apple:
        return Icons.apple;
      case OAuthProvider.facebook:
        return Icons.facebook;
      case OAuthProvider.github:
        return Icons.code;
      case OAuthProvider.twitter:
        return Icons.alternate_email;
    }
  }
}
