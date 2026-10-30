import 'package:dartz/dartz.dart';
import 'package:guardup/core/enums/report_type.dart';
import 'package:guardup/core/error/failures.dart';

import 'report_repository.dart';

class ReportUseCase {
  final ReportRepository repository;

  ReportUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required ReportType type,
    required String targetId,
    required String reason,
    String? details,
  }) async {
    return await repository.report(
      type: type,
      targetId: targetId,
      reason: reason,
      details: details,
    );
  }
}
