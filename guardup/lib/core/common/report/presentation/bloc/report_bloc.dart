import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardup/core/enums/report_type.dart';

import '../../domain/report_usecase.dart';

part 'report_event.dart';
part 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportUseCase reportUseCase;

  ReportBloc({required this.reportUseCase}) : super(ReportInitial()) {
    on<SubmitReportEvent>(_onReportRequested);
  }

  Future<void> _onReportRequested(
    SubmitReportEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    final result = await reportUseCase(
      type: event.type,
      targetId: event.targetId,
      reason: event.reason,
      details: event.details,
    );

    result.fold(
      (failure) => emit(ReportError(failure.message)),
      (_) => emit(ReportSuccess()),
    );
  }
}
