import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/extensions/context.extension.dart';

/// Verification status for uploaded bodyguard documents and credentials.
enum DocumentStatus {
  @JsonValue('PENDING')
  pending('PENDING', 'Pending'),

  @JsonValue('REJECTED')
  rejected('REJECTED', 'Rejected'),

  @JsonValue('APPROVED')
  approved('APPROVED', 'Verified');

  final String apiValue;
  final String label;

  const DocumentStatus(this.apiValue, this.label);

  static DocumentStatus fromApiValue(String? value) {
    if (value == null) return DocumentStatus.pending;
    return DocumentStatus.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => DocumentStatus.pending,
    );
  }

  static DocumentStatus? tryFromApiValue(String? value) {
    if (value == null) return null;
    try {
      return DocumentStatus.values.firstWhere(
        (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  bool get isApproved => this == DocumentStatus.approved;
  bool get isPending => this == DocumentStatus.pending;
  bool get isRejected => this == DocumentStatus.rejected;

  Color badgeColor(BuildContext context) {
    switch (this) {
      case DocumentStatus.approved:
        return context.colors.success;
      case DocumentStatus.pending:
        return context.colors.primary;
      case DocumentStatus.rejected:
        return context.colors.error;
    }
  }

  Color badgeBackgroundColor(BuildContext context) {
    switch (this) {
      case DocumentStatus.approved:
        return context.colors.success.withValues(alpha: 0.12);
      case DocumentStatus.pending:
        return context.colors.primary.withValues(alpha: 0.12);
      case DocumentStatus.rejected:
        return context.colors.error.withValues(alpha: 0.12);
    }
  }

  Color badgeBorderColor(BuildContext context) {
    switch (this) {
      case DocumentStatus.approved:
        return context.colors.success.withValues(alpha: 0.35);
      case DocumentStatus.pending:
        return context.colors.primary.withValues(alpha: 0.35);
      case DocumentStatus.rejected:
        return context.colors.error.withValues(alpha: 0.35);
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentStatus.approved:
        return Icons.check_circle_rounded;
      case DocumentStatus.pending:
        return Icons.hourglass_top_rounded;
      case DocumentStatus.rejected:
        return Icons.cancel_rounded;
    }
  }
}
