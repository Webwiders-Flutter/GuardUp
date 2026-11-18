import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/gen/app_localizations.dart';

/// Mirrors the `public.gender_type` enum.
enum GenderType {
  @JsonValue('MALE')
  male('MALE'),

  @JsonValue('FEMALE')
  female('FEMALE'),

  @JsonValue('OTHER')
  other('OTHER');

  final String apiValue;

  const GenderType(this.apiValue);

  String label([AppLocalizations? l10n]) {
    switch (this) {
      case GenderType.male:
        return 'Male';
      case GenderType.female:
        return 'Female';
      case GenderType.other:
        return 'Other';
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
