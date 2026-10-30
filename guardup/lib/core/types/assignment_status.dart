import 'package:flutter/material.dart';

enum AssignmentStatus {
  pending,
  accepted,
  active,
  completed,
  cancelled,
}

extension AssignmentStatusExtension on AssignmentStatus {
  String get title {
    switch (this) {
      case AssignmentStatus.pending:
        return "Pending";
      case AssignmentStatus.accepted:
        return "Accepted";
      case AssignmentStatus.active:
        return "Active";
      case AssignmentStatus.completed:
        return "Completed";
      case AssignmentStatus.cancelled:
        return "Cancelled";
    }
  }

  Color get textColor {
    switch (this) {
      case AssignmentStatus.pending:
        return Colors.orange;
      case AssignmentStatus.accepted:
        return Colors.blue;
      case AssignmentStatus.active:
        return Colors.green;
      case AssignmentStatus.completed:
        return const Color(0xFF2E7D32);
      case AssignmentStatus.cancelled:
        return Colors.red;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AssignmentStatus.pending:
        return Colors.orange.withValues(alpha: 0.1);
      case AssignmentStatus.accepted:
        return Colors.blue.withValues(alpha: 0.1);
      case AssignmentStatus.active:
        return Colors.green.withValues(alpha: 0.1);
      case AssignmentStatus.completed:
        return const Color(0xFF2E7D32).withValues(alpha: 0.1);
      case AssignmentStatus.cancelled:
        return Colors.red.withValues(alpha: 0.1);
    }
  }
}
