import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/extensions/context.extension.dart';
import '/gen/app_localizations.dart';

enum VerificationStatus {
  @JsonValue('PENDING')
  pending('PENDING'),

  @JsonValue('VERIFIED')
  verified('VERIFIED'),

  @JsonValue('REJECTED')
  rejected('REJECTED');

  final String apiValue;

  const VerificationStatus(this.apiValue);

  String label([AppLocalizations? l10n]) {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }

  Color color(BuildContext context) {
    final colors = context.colors;
    switch (this) {
      case VerificationStatus.pending:
        return colors.warning;
      case VerificationStatus.verified:
        return colors.success;
      case VerificationStatus.rejected:
        return colors.error;
    }
  }

  IconData get icon {
    switch (this) {
      case VerificationStatus.pending:
        return Icons.pending_outlined;
      case VerificationStatus.verified:
        return Icons.check_circle_outline_rounded;
      case VerificationStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  static VerificationStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'VERIFIED':
        return VerificationStatus.verified;
      case 'REJECTED':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.pending;
    }
  }
}
