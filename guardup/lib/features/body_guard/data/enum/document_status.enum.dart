import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Verification status for uploaded bodyguard documents and credentials.
enum DocumentStatus {
  @JsonValue('PENDING')
  pending('PENDING', 'Pending'),

  @JsonValue('REJECTED')
  rejected('REJECTED', 'Rejected'),

  @JsonValue('APPROVED')
  approved('APPROVED', 'Approved');

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

