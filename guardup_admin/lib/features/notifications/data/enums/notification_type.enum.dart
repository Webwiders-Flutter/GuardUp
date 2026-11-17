import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/extensions/context.extension.dart';

/// Mirrors `public.notification_type` in the database.
enum NotificationType {
  @JsonValue('ACCOUNT_APPROVED')
  accountApproved('ACCOUNT_APPROVED'),

  @JsonValue('ACCOUNT_REJECTED')
  accountRejected('ACCOUNT_REJECTED'),

  @JsonValue('ACCOUNT_BLOCKED')
  accountBlocked('ACCOUNT_BLOCKED'),

  @JsonValue('ACCOUNT_UNBLOCKED')
  accountUnblocked('ACCOUNT_UNBLOCKED'),

  @JsonValue('ACCOUNT_DELETED')
  accountDeleted('ACCOUNT_DELETED'),

  @JsonValue('NEW_USER_REGISTRATION')
  newUserRegistration('NEW_USER_REGISTRATION'),

  @JsonValue('SYSTEM')
  system('SYSTEM');

  final String apiValue;
  const NotificationType(this.apiValue);

  String get label {
    switch (this) {
      case NotificationType.accountApproved:
        return 'Account Approved';
      case NotificationType.accountRejected:
        return 'Account Rejected';
      case NotificationType.accountBlocked:
        return 'Account Blocked';
      case NotificationType.accountUnblocked:
        return 'Account Unblocked';
      case NotificationType.accountDeleted:
        return 'Account Deleted';
      case NotificationType.newUserRegistration:
        return 'New User Registration';
      case NotificationType.system:
        return 'System';
    }
  }

  Color color(BuildContext context) {
    final colors = context.colors;
    switch (this) {
      case NotificationType.accountApproved:
      case NotificationType.accountUnblocked:
        return colors.success;
      case NotificationType.accountRejected:
      case NotificationType.accountBlocked:
      case NotificationType.accountDeleted:
        return colors.error;
      case NotificationType.newUserRegistration:
        return colors.info;
      case NotificationType.system:
        return colors.primary;
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.accountApproved:
        return Icons.verified_user_rounded;
      case NotificationType.accountRejected:
        return Icons.gpp_bad_rounded;
      case NotificationType.accountBlocked:
        return Icons.block_rounded;
      case NotificationType.accountUnblocked:
        return Icons.lock_open_rounded;
      case NotificationType.accountDeleted:
        return Icons.person_remove_rounded;
      case NotificationType.newUserRegistration:
        return Icons.person_add_alt_1_rounded;
      case NotificationType.system:
        return Icons.notifications_rounded;
    }
  }
}
