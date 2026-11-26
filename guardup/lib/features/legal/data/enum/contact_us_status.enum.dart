import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/extensions/context.extension.dart';
import '/gen/app_localizations.dart';

/// Mirrors the `public.contact_us_status` enum.
enum ContactUsStatus {
  @JsonValue('PENDING')
  pending('PENDING'),

  @JsonValue('IN_PROGRESS')
  inProgress('IN_PROGRESS'),

  @JsonValue('RESOLVED')
  resolved('RESOLVED'),

  @JsonValue('CLOSED')
  closed('CLOSED');

  final String apiValue;

  const ContactUsStatus(this.apiValue);

  bool get isPending => this == ContactUsStatus.pending;
  bool get isInProgress => this == ContactUsStatus.inProgress;
  bool get isResolved => this == ContactUsStatus.resolved;
  bool get isClosed => this == ContactUsStatus.closed;

  String label([AppLocalizations? l10n]) {
    switch (this) {
      case ContactUsStatus.pending:
        return 'Pending';
      case ContactUsStatus.inProgress:
        return 'In Progress';
      case ContactUsStatus.resolved:
        return 'Resolved';
      case ContactUsStatus.closed:
        return 'Closed';
    }
  }

  Color color(BuildContext context) {
    final colors = context.colors;
    switch (this) {
      case ContactUsStatus.pending:
        return colors.warning;
      case ContactUsStatus.inProgress:
        return colors.info;
      case ContactUsStatus.resolved:
        return colors.success;
      case ContactUsStatus.closed:
        return colors.onSurfaceVariant;
    }
  }

  IconData get icon {
    switch (this) {
      case ContactUsStatus.pending:
        return Icons.pending_actions_rounded;
      case ContactUsStatus.inProgress:
        return Icons.autorenew_rounded;
      case ContactUsStatus.resolved:
        return Icons.check_circle_rounded;
      case ContactUsStatus.closed:
        return Icons.lock_outline_rounded;
    }
  }
}
