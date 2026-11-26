import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/extensions/context.extension.dart';

/// Semantic operational status of a financial transaction.
enum TransactionStatus {
  @JsonValue('COMPLETED')
  completed('COMPLETED', 'Completed'),

  @JsonValue('PENDING')
  pending('PENDING', 'Pending'),

  @JsonValue('FAILED')
  failed('FAILED', 'Failed'),

  @JsonValue('CANCELLED')
  cancelled('CANCELLED', 'Cancelled'),

  @JsonValue('REFUNDED')
  refunded('REFUNDED', 'Refunded');

  final String apiValue;
  final String label;

  const TransactionStatus(this.apiValue, this.label);

  bool get isCompleted => this == TransactionStatus.completed;
  bool get isPending => this == TransactionStatus.pending;
  bool get isFailed => this == TransactionStatus.failed;
  bool get isCancelled => this == TransactionStatus.cancelled;
  bool get isRefunded => this == TransactionStatus.refunded;

  Color color(BuildContext context) {
    switch (this) {
      case TransactionStatus.completed:
        return context.colors.success;
      case TransactionStatus.pending:
        return context.colors.primary;
      case TransactionStatus.failed:
        return context.colors.error;
      case TransactionStatus.cancelled:
        return context.colors.outline;
      case TransactionStatus.refunded:
        return context.colors.info;
    }
  }

  Color backgroundColor(BuildContext context) {
    switch (this) {
      case TransactionStatus.completed:
        return context.colors.success.withValues(alpha: 0.15);
      case TransactionStatus.pending:
        return context.colors.primary.withValues(alpha: 0.15);
      case TransactionStatus.failed:
        return context.colors.error.withValues(alpha: 0.15);
      case TransactionStatus.cancelled:
        return context.colors.outline.withValues(alpha: 0.15);
      case TransactionStatus.refunded:
        return context.colors.info.withValues(alpha: 0.15);
    }
  }

  Color borderColor(BuildContext context) {
    switch (this) {
      case TransactionStatus.completed:
        return context.colors.success.withValues(alpha: 0.4);
      case TransactionStatus.pending:
        return context.colors.primary.withValues(alpha: 0.4);
      case TransactionStatus.failed:
        return context.colors.error.withValues(alpha: 0.4);
      case TransactionStatus.cancelled:
        return context.colors.outline.withValues(alpha: 0.4);
      case TransactionStatus.refunded:
        return context.colors.info.withValues(alpha: 0.4);
    }
  }
}

