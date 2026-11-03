import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/gen/app_localizations.dart';

/// Represents the gender choices available across user profile and registration.
enum GenderType {
  @JsonValue('MALE')
  male('MALE'),

  @JsonValue('FEMALE')
  female('FEMALE'),

  @JsonValue('OTHER')
  other('OTHER');

  final String apiValue;

  const GenderType(this.apiValue);

  static GenderType fromApiValue(String? value) {
    if (value == null) return GenderType.male;
    return GenderType.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => GenderType.male,
    );
  }

  static GenderType? tryFromApiValue(String? value) {
    if (value == null) return null;
    try {
      return GenderType.values.firstWhere(
        (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case GenderType.male:
        return l10n.male;
      case GenderType.female:
        return l10n.female;
      case GenderType.other:
        return l10n.other;
    }
  }

  IconData get icon {
    switch (this) {
      case GenderType.male:
        return Icons.male_rounded;
      case GenderType.female:
        return Icons.female_rounded;
      case GenderType.other:
        return Icons.transgender_rounded;
    }
  }
}

