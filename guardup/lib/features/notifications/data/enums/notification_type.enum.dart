import 'package:freezed_annotation/freezed_annotation.dart';

import '/gen/assets.gen.dart';

/// Semantic notification type mirroring Postgres `public.notification_type` enum.
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

  /// The SVG icon corresponding to this notification type.
  SvgGenImage get svgIcon {
    switch (this) {
      case NotificationType.accountApproved:
      case NotificationType.accountUnblocked:
        return Assets.svg.verified;
      case NotificationType.accountRejected:
      case NotificationType.accountBlocked:
      case NotificationType.accountDeleted:
        return Assets.svg.profileUpdate;
      case NotificationType.newUserRegistration:
        return Assets.svg.user;
      case NotificationType.system:
        return Assets.svg.notificationBell;
    }
  }

  /// Filter category mapping: All, Booking, Payment, Account.
  NotificationCategory get category {
    switch (this) {
      case NotificationType.accountApproved:
      case NotificationType.accountRejected:
      case NotificationType.accountBlocked:
      case NotificationType.accountUnblocked:
      case NotificationType.accountDeleted:
      case NotificationType.newUserRegistration:
      case NotificationType.system:
        return NotificationCategory.account;
    }
  }
}

/// Category tabs for filtering notifications.
enum NotificationCategory {
  @JsonValue('ALL')
  all('ALL'),

  @JsonValue('BOOKING')
  booking('BOOKING'),

  @JsonValue('PAYMENT')
  payment('PAYMENT'),

  @JsonValue('ACCOUNT')
  account('ACCOUNT');

  final String apiValue;

  const NotificationCategory(this.apiValue);

  String get label {
    switch (this) {
      case NotificationCategory.all:
        return 'All';
      case NotificationCategory.booking:
        return 'Booking';
      case NotificationCategory.payment:
        return 'Payment';
      case NotificationCategory.account:
        return 'Account';
    }
  }
}
