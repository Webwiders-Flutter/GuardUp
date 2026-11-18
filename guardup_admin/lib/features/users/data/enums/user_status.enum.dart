import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/extensions/context.extension.dart';
import '/gen/app_localizations.dart';

enum UserStatus {
  @JsonValue("INCOMPLETE")
  incomplete("INCOMPLETE"),

  @JsonValue('ACTIVE')
  active('ACTIVE'),

  @JsonValue("PENDING_APPROVAL")
  approvalPending("PENDING_APPROVAL"),

  @JsonValue('REJECTED')
  rejected('REJECTED'),

  @JsonValue('BLOCKED')
  blocked('BLOCKED'),

  @JsonValue('DELETED')
  deleted('DELETED');

  final String apiValue;

  const UserStatus(this.apiValue);

  bool get isIncomplete => this == UserStatus.incomplete;
  bool get isApproved => this == UserStatus.active;
  bool get isPendingApproval => this == UserStatus.approvalPending;
  bool get isRejected => this == UserStatus.rejected;
  bool get isBlocked => this == UserStatus.blocked;
  bool get isDeleted => this == UserStatus.deleted;

  /// Pending or rejected applications can be reviewed (documents approved /
  /// rejected, profile approved / rejected).
  bool get isUnderReview => isPendingApproval || isRejected;

  String label([AppLocalizations? l10n]) {
    switch (this) {
      case UserStatus.incomplete:
        return 'Incomplete';
      case UserStatus.active:
        return 'Approved';
      case UserStatus.approvalPending:
        return 'Pending Approval';
      case UserStatus.rejected:
        return 'Rejected';
      case UserStatus.blocked:
        return 'Blocked';
      case UserStatus.deleted:
        return 'Deleted';
    }
  }

  Color color(BuildContext context) {
    final colors = context.colors;
    switch (this) {
      case UserStatus.incomplete:
        return colors.warning;
      case UserStatus.active:
        return colors.success;
      case UserStatus.approvalPending:
        return colors.warning;
      case UserStatus.rejected:
        return colors.error;
      case UserStatus.blocked:
        return colors.error;
      case UserStatus.deleted:
        return colors.error;
    }
  }

  IconData get icon {
    switch (this) {
      case UserStatus.incomplete:
        return Icons.pending_actions_outlined;
      case UserStatus.active:
        return Icons.verified_user_outlined;
      case UserStatus.approvalPending:
        return Icons.hourglass_top_outlined;
      case UserStatus.rejected:
        return Icons.cancel_outlined;
      case UserStatus.blocked:
        return Icons.block_outlined;
      case UserStatus.deleted:
        return Icons.delete_outlined;
    }
  }

  String get subtitle {
    switch (this) {
      case UserStatus.active:
        return 'Fully approved and active GuardUp accounts';
      case UserStatus.approvalPending:
        return 'Documents submitted, pending compliance review';
      case UserStatus.rejected:
        return 'Profile or documents rejected by an admin';
      case UserStatus.incomplete:
        return 'Profile onboarding in progress';
      case UserStatus.blocked:
        return 'Suspended or restricted accounts';
      case UserStatus.deleted:
        return 'Deactivated or deleted user accounts';
    }
  }

  static UserStatus? fromApi(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toUpperCase();
    if (normalized == 'APPROVED' || normalized == 'ACTIVE') {
      return UserStatus.active;
    }
    if (normalized == 'PENDING_APPROVAL' ||
        normalized == 'APPROVAL_PENDING' ||
        normalized == 'PENDING') {
      return UserStatus.approvalPending;
    }
    return UserStatus.values
        .where((e) => e.apiValue.toUpperCase() == normalized)
        .firstOrNull;
  }
}
