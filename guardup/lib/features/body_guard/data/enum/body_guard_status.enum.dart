import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/extensions/context.extension.dart';

/// Operational availability and deployment status for a bodyguard operative.
enum BodyGuardStatus {
  @JsonValue('AVAILABLE_TODAY')
  availableToday('AVAILABLE_TODAY', 'Available Today', hasDot: true),

  @JsonValue('AVAILABLE_NOW')
  availableNow('AVAILABLE_NOW', 'Available Now', hasDot: true),

  @JsonValue('AVAILABLE_TOMORROW')
  availableTomorrow('AVAILABLE_TOMORROW', 'Available Tomorrow', hasDot: true),

  @JsonValue('ON_DUTY')
  onDuty('ON_DUTY', 'On Duty', hasDot: true),

  @JsonValue('UNAVAILABLE')
  unavailable('UNAVAILABLE', 'Unavailable', hasDot: false);

  final String apiValue;
  final String label;
  final bool hasDot;

  const BodyGuardStatus(this.apiValue, this.label, {required this.hasDot});

  Color badgeColor(BuildContext context) {
    switch (this) {
      case BodyGuardStatus.availableToday:
      case BodyGuardStatus.availableNow:
        return context.colors.success;
      case BodyGuardStatus.availableTomorrow:
        return context.colors.primary;
      case BodyGuardStatus.onDuty:
        return context.colors.primaryContainer;
      case BodyGuardStatus.unavailable:
        return context.colors.outline;
    }
  }

  Color badgeBackgroundColor(BuildContext context) {
    switch (this) {
      case BodyGuardStatus.availableToday:
      case BodyGuardStatus.availableNow:
        return context.colors.success.withValues(alpha: 0.15);
      case BodyGuardStatus.availableTomorrow:
        return context.colors.primary.withValues(alpha: 0.15);
      case BodyGuardStatus.onDuty:
        return context.colors.primaryContainer.withValues(alpha: 0.15);
      case BodyGuardStatus.unavailable:
        return context.colors.outline.withValues(alpha: 0.15);
    }
  }

  Color badgeBorderColor(BuildContext context) {
    switch (this) {
      case BodyGuardStatus.availableToday:
      case BodyGuardStatus.availableNow:
        return context.colors.success.withValues(alpha: 0.4);
      case BodyGuardStatus.availableTomorrow:
        return context.colors.primary.withValues(alpha: 0.4);
      case BodyGuardStatus.onDuty:
        return context.colors.primaryContainer.withValues(alpha: 0.4);
      case BodyGuardStatus.unavailable:
        return context.colors.outline.withValues(alpha: 0.4);
    }
  }
}

