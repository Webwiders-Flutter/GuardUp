part of 'report_bloc.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class SubmitReportEvent extends ReportEvent {
  final ReportType type;
  final String targetId;
  final String reason;
  final String? details;

  const SubmitReportEvent({
    required this.type,
    required this.targetId,
    required this.reason,
    this.details,
  });

  @override
  List<Object?> get props => [type, targetId, reason, details];
}
