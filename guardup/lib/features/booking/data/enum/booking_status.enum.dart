import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/extensions/context.extension.dart';

/// Operational lifecycle statuses for client protection and bodyguard bookings.
enum BookingStatus {
  @JsonValue('PENDING')
  pending('PENDING', 'Pending Confirmation', hasDot: false),

  @JsonValue('CONFIRMED')
  confirmed('CONFIRMED', 'Confirmed', hasDot: true),

  @JsonValue('ON_GOING')
  onGoing('ON_GOING', 'Running', hasDot: true),

  @JsonValue('COMPLETED')
  completed('COMPLETED', 'Completed', hasDot: true),

  @JsonValue('CANCELLED')
  cancelled('CANCELLED', 'Cancelled', hasDot: true);

  final String apiValue;
  final String label;
  final bool hasDot;

  const BookingStatus(this.apiValue, this.label, {required this.hasDot});

  bool get isPending => this == BookingStatus.pending;
  bool get isConfirmed => this == BookingStatus.confirmed;
  bool get isOngoing => this == BookingStatus.onGoing;
  bool get isCompleted => this == BookingStatus.completed;
  bool get isCancelled => this == BookingStatus.cancelled;

  Color badgeColor(BuildContext context) {
    switch (this) {
      case BookingStatus.pending:
      case BookingStatus.onGoing:
      case BookingStatus.confirmed:
        return context.colors.primary;
      case BookingStatus.completed:
        return context.colors.success;
      case BookingStatus.cancelled:
        return context.colors.error;
    }
  }

  Color badgeBackgroundColor(BuildContext context) {
    switch (this) {
      case BookingStatus.pending:
      case BookingStatus.onGoing:
      case BookingStatus.confirmed:
        return context.colors.primary.withValues(alpha: 0.15);
      case BookingStatus.completed:
        return context.colors.success.withValues(alpha: 0.15);
      case BookingStatus.cancelled:
        return context.colors.error.withValues(alpha: 0.15);
    }
  }

  Color badgeBorderColor(BuildContext context) {
    switch (this) {
      case BookingStatus.pending:
      case BookingStatus.onGoing:
      case BookingStatus.confirmed:
        return context.colors.primary.withValues(alpha: 0.4);
      case BookingStatus.completed:
        return context.colors.success.withValues(alpha: 0.4);
      case BookingStatus.cancelled:
        return context.colors.error.withValues(alpha: 0.4);
    }
  }

  IconData get icon {
    switch (this) {
      case BookingStatus.pending:
        return Icons.hourglass_top_rounded;
      case BookingStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case BookingStatus.onGoing:
        return Icons.shield_rounded;
      case BookingStatus.completed:
        return Icons.task_alt_rounded;
      case BookingStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}
