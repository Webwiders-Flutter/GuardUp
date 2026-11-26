import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/extensions/context.extension.dart';

/// Operational availability status for a bodyguard evaluated dynamically from
/// their working hours in `user_availabilities`.
enum BodyguardAvailabilityStatus {
  @JsonValue('AVAILABLE')
  available('AVAILABLE', 'Available', hasDot: true),

  @JsonValue('NOT_AVAILABLE')
  notAvailable('NOT_AVAILABLE', 'Not Available', hasDot: false),

  @JsonValue('NOT_SET')
  notSet('NOT_SET', 'Not Set', hasDot: false);

  final String apiValue;
  final String label;
  final bool hasDot;

  const BodyguardAvailabilityStatus(
    this.apiValue,
    this.label, {
    required this.hasDot,
  });

  Color badgeColor(BuildContext context) {
    switch (this) {
      case BodyguardAvailabilityStatus.available:
        return context.colors.success;
      case BodyguardAvailabilityStatus.notAvailable:
        return context.colors.error;
      case BodyguardAvailabilityStatus.notSet:
        return context.colors.outline;
    }
  }

  Color badgeBackgroundColor(BuildContext context) {
    switch (this) {
      case BodyguardAvailabilityStatus.available:
        return context.colors.success.withValues(alpha: 0.12);
      case BodyguardAvailabilityStatus.notAvailable:
        return context.colors.error.withValues(alpha: 0.12);
      case BodyguardAvailabilityStatus.notSet:
        return context.colors.outline.withValues(alpha: 0.15);
    }
  }

  Color badgeBorderColor(BuildContext context) {
    switch (this) {
      case BodyguardAvailabilityStatus.available:
        return context.colors.success.withValues(alpha: 0.4);
      case BodyguardAvailabilityStatus.notAvailable:
        return context.colors.error.withValues(alpha: 0.4);
      case BodyguardAvailabilityStatus.notSet:
        return context.colors.outline.withValues(alpha: 0.4);
    }
  }
}
