import 'package:flutter/material.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';

enum VisaApplicationStatus {
  draft('draft', 0),
  pending('pending', 1),
  documentsVerified('documents_verified', 2),
  embassyReview('embassy_review', 3),
  interviewSchedules('interview_schedules', 4),
  approved('approved', 5),
  rejected('rejected', 0),
  serviceCompleted('service_completed', 6);

  final String value;
  final int step;

  const VisaApplicationStatus(this.value, this.step);

  static VisaApplicationStatus fromValue(String? value) {
    if (value == null) return VisaApplicationStatus.pending;
    return VisaApplicationStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => VisaApplicationStatus.pending,
    );
  }

  String getLabel(BuildContext context) {
    switch (this) {
      case VisaApplicationStatus.draft:
        return context.l10n.statusDraft;
      case VisaApplicationStatus.pending:
        return context.l10n.pending;
      case VisaApplicationStatus.documentsVerified:
        return context.l10n.documentVerified;
      case VisaApplicationStatus.embassyReview:
        return context.l10n.embassyReview;
      case VisaApplicationStatus.interviewSchedules:
        return context.l10n.interviewScheduled;
      case VisaApplicationStatus.approved:
        return context.l10n.approved;
      case VisaApplicationStatus.rejected:
        return context.l10n.rejected;
      case VisaApplicationStatus.serviceCompleted:
        return context.l10n.serviceCompleted;
    }
  }

  Color get color {
    switch (this) {
      case VisaApplicationStatus.draft:
        return Colors.amber;
      case VisaApplicationStatus.pending:
        return Colors.orange;
      case VisaApplicationStatus.documentsVerified:
        return Colors.blue;
      case VisaApplicationStatus.embassyReview:
        return Colors.purple;
      case VisaApplicationStatus.interviewSchedules:
        return Colors.teal;
      case VisaApplicationStatus.approved:
        return Colors.green;
      case VisaApplicationStatus.rejected:
        return Colors.red;
      case VisaApplicationStatus.serviceCompleted:
        return Colors.indigo;
    }
  }
}
