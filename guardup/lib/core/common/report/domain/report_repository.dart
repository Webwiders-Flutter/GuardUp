import 'package:dartz/dartz.dart';
import 'package:guardup/core/enums/report_type.dart';
import 'package:guardup/core/error/failures.dart';

abstract class ReportRepository {
  Future<Either<Failure, void>> report({
    required ReportType type,
    required String targetId,
    required String reason,
    String? details,
  });
}
