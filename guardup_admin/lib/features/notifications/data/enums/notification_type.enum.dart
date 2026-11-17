import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/extensions/context.extension.dart';

enum NotificationType {
  @JsonValue('ACCOUNT_APPROVED')
  accountApproved('ACCOUNT_APPROVED'),

  @JsonValue('ACCOUNT_REJECTED')
  accountRejected('ACCOUNT_REJECTED'),

  @JsonValue('DOCUMENT_APPROVED')
  documentApproved('DOCUMENT_APPROVED'),

  @JsonValue('DOCUMENT_REJECTED')
  documentRejected('DOCUMENT_REJECTED'),

  @JsonValue('ORDER_CREATED')
  orderCreated('ORDER_CREATED'),

  @JsonValue('ORDER_UPDATED')
  orderUpdated('ORDER_UPDATED'),

  @JsonValue('ORDER_CANCELLED')
  orderCancelled('ORDER_CANCELLED'),

  @JsonValue('TRIP_CREATED')
  tripCreated('TRIP_CREATED'),

  @JsonValue('TRIP_UPDATED')
  tripUpdated('TRIP_UPDATED'),

  @JsonValue('PAYMENT_RECEIVED')
  paymentReceived('PAYMENT_RECEIVED'),

  @JsonValue('PAYMENT_FAILED')
  paymentFailed('PAYMENT_FAILED'),

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
      case NotificationType.documentApproved:
        return 'Document Approved';
      case NotificationType.documentRejected:
        return 'Document Rejected';
      case NotificationType.orderCreated:
        return 'Order Created';
      case NotificationType.orderUpdated:
        return 'Order Updated';
      case NotificationType.orderCancelled:
        return 'Order Cancelled';
      case NotificationType.tripCreated:
        return 'Trip Created';
      case NotificationType.tripUpdated:
        return 'Trip Updated';
      case NotificationType.paymentReceived:
        return 'Payment Received';
      case NotificationType.paymentFailed:
        return 'Payment Failed';
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
      case NotificationType.documentApproved:
        return colors.success;
      case NotificationType.accountRejected:
      case NotificationType.documentRejected:
      case NotificationType.paymentFailed:
      case NotificationType.orderCancelled:
        return colors.error;
      case NotificationType.orderCreated:
      case NotificationType.orderUpdated:
        return colors.info;
      case NotificationType.tripCreated:
      case NotificationType.tripUpdated:
      case NotificationType.paymentReceived:
        return colors.secondary;
      case NotificationType.newUserRegistration:
      case NotificationType.system:
        return colors.primary;
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.accountApproved:
      case NotificationType.documentApproved:
        return Icons.verified_user_rounded;
      case NotificationType.accountRejected:
      case NotificationType.documentRejected:
        return Icons.gpp_bad_rounded;
      case NotificationType.orderCreated:
      case NotificationType.orderUpdated:
        return Icons.shopping_bag_rounded;
      case NotificationType.orderCancelled:
        return Icons.cancel_outlined;
      case NotificationType.tripCreated:
      case NotificationType.tripUpdated:
        return Icons.local_shipping_rounded;
      case NotificationType.paymentReceived:
        return Icons.account_balance_wallet_rounded;
      case NotificationType.paymentFailed:
        return Icons.error_outline_rounded;
      case NotificationType.newUserRegistration:
        return Icons.person_add_alt_1_rounded;
      case NotificationType.system:
        return Icons.notifications_rounded;
    }
  }
}
