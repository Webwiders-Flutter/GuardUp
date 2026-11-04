import 'package:freezed_annotation/freezed_annotation.dart';

import '/gen/assets.gen.dart';

/// Semantic notification type categorizing notifications and determining icons and category filters.
enum NotificationType {
  @JsonValue('BOOKING_REQUEST')
  bookingRequest('BOOKING_REQUEST'),

  @JsonValue('BOOKING_REMINDER')
  bookingReminder('BOOKING_REMINDER'),

  @JsonValue('CUSTOMER_MESSAGE')
  customerMessage('CUSTOMER_MESSAGE'),

  @JsonValue('PAYOUT_PROCESSED')
  payoutProcessed('PAYOUT_PROCESSED'),

  @JsonValue('DOCUMENT_VERIFIED')
  documentVerified('DOCUMENT_VERIFIED'),

  @JsonValue('PROFILE_UPDATE')
  profileUpdate('PROFILE_UPDATE'),

  // Legacy mappings for backwards compatibility
  @JsonValue('TRIP_CREATED')
  tripCreated('TRIP_CREATED'),

  @JsonValue('DOCUMENT_APPROVED')
  documentApproved('DOCUMENT_APPROVED'),

  @JsonValue('PAYMENT_RECEIVED')
  paymentReceived('PAYMENT_RECEIVED'),

  @JsonValue('ORDER_UPDATED')
  orderUpdated('ORDER_UPDATED');

  final String apiValue;

  const NotificationType(this.apiValue);

  static NotificationType fromApiValue(String? value) {
    if (value == null) return NotificationType.bookingRequest;
    return NotificationType.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => NotificationType.bookingRequest,
    );
  }

  /// The SVG icon corresponding to this notification type.
  SvgGenImage get svgIcon {
    switch (this) {
      case NotificationType.bookingRequest:
      case NotificationType.bookingReminder:
      case NotificationType.tripCreated:
        return Assets.svg.calender;
      case NotificationType.customerMessage:
        return Assets.svg.chat;
      case NotificationType.payoutProcessed:
      case NotificationType.paymentReceived:
        return Assets.svg.payout;
      case NotificationType.documentVerified:
      case NotificationType.documentApproved:
        return Assets.svg.verified;
      case NotificationType.profileUpdate:
      case NotificationType.orderUpdated:
        return Assets.svg.profileUpdate;
    }
  }

  /// Filter category mapping: All, Booking, Payment, Account.
  NotificationCategory get category {
    switch (this) {
      case NotificationType.bookingRequest:
      case NotificationType.bookingReminder:
      case NotificationType.tripCreated:
        return NotificationCategory.booking;
      case NotificationType.payoutProcessed:
      case NotificationType.paymentReceived:
        return NotificationCategory.payment;
      case NotificationType.customerMessage:
      case NotificationType.documentVerified:
      case NotificationType.documentApproved:
      case NotificationType.profileUpdate:
      case NotificationType.orderUpdated:
        return NotificationCategory.account;
    }
  }
}

/// Category tabs for filtering notifications.
enum NotificationCategory {
  all,
  booking,
  payment,
  account;

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

