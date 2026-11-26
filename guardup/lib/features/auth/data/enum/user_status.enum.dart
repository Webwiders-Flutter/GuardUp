import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/extensions/context.extension.dart';

/// Represents the verification and access status of a user across all 3 roles:
/// - Customer
/// - Bodyguard (Guard)
/// - Security Company (Company)
enum UserStatus {
  /// User signed up and verified email, but has not completed required
  /// profile details or document uploads (Guards & Companies).
  @JsonValue('INCOMPLETE')
  incomplete('INCOMPLETE'),

  /// Guard/Company submitted profile, documents, and fee, and is currently
  /// waiting for admin review and verification.
  @JsonValue('PENDING_APPROVAL')
  pendingApproval('PENDING_APPROVAL'),

  /// Active access across all roles (Customers upon OTP verification, Guards & Companies once approved).
  @JsonValue('ACTIVE')
  active('ACTIVE'),

  /// Application was rejected by admin.
  @JsonValue('REJECTED')
  rejected('REJECTED'),

  /// Account has been temporarily or permanently suspended by admin.
  @JsonValue('BLOCKED')
  blocked('BLOCKED'),

  /// Soft-deleted or deactivated account.
  @JsonValue('DELETED')
  deleted('DELETED');

  final String apiValue;

  const UserStatus(this.apiValue);

  bool get isIncomplete => this == UserStatus.incomplete;
  bool get isPendingApproval => this == UserStatus.pendingApproval;
  bool get isActive => this == UserStatus.active;
  bool get isRejected => this == UserStatus.rejected;
  bool get isBlocked => this == UserStatus.blocked;
  bool get isDeleted => this == UserStatus.deleted;

  String get label {
    switch (this) {
      case UserStatus.incomplete:
        return 'Incomplete Profile';
      case UserStatus.pendingApproval:
        return 'Pending Approval';
      case UserStatus.active:
        return 'Active';
      case UserStatus.rejected:
        return 'Rejected';
      case UserStatus.blocked:
        return 'Blocked';
      case UserStatus.deleted:
        return 'Deleted';
    }
  }

  /// Accent colour for status chips / banners.
  Color color(BuildContext context) {
    final colors = context.colors;
    switch (this) {
      case UserStatus.active:
        return colors.success;
      case UserStatus.pendingApproval:
        return colors.warning;
      case UserStatus.incomplete:
        return colors.info;
      case UserStatus.rejected:
      case UserStatus.blocked:
      case UserStatus.deleted:
        return colors.error;
    }
  }
}

