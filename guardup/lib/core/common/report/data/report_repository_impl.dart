import 'package:dartz/dartz.dart';
import 'package:guardup/core/constants/supabase_tables.dart';
import 'package:guardup/core/enums/report_type.dart';
import 'package:guardup/core/error/error_keys.dart';
import 'package:guardup/core/error/failures.dart';
import 'package:guardup/core/utils/app_logs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final SupabaseClient supabaseClient;

  ReportRepositoryImpl(this.supabaseClient);

  @override
  Future<Either<Failure, void>> report({
    required ReportType type,
    required String targetId,
    required String reason,
    String? details,
  }) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        return const Left(ServerFailure(ErrorKeys.userNotAuthenticated));
      }

      String table;
      String idColumn;

      switch (type) {
        case ReportType.video:
        case ReportType.playbackIssue:
          table = SupabaseTables.videoReports;
          idColumn = 'video_id';
          break;
        case ReportType.comment:
          table = SupabaseTables.commentReports;
          idColumn = 'comment_id';
          break;
        case ReportType.user:
          table = SupabaseTables.userReports;
          idColumn = 'reported_user_id';
          break;
      }

      await supabaseClient.from(table).insert({
        idColumn: targetId,
        'reporter_id': userId,
        'reason': reason,
        'details': details,
      });

      return const Right(null);
    } catch (e, stackTrace) {
      if (e is PostgrestException && e.code == '23505') {
        return const Left(ServerFailure(ErrorKeys.alreadyReported));
      }
      AppLogs.error(
        'Failed to report ${type.name}',
        error: e,
        stackTrace: stackTrace,
      );
      return const Left(ServerFailure(ErrorKeys.failedToUpdate));
    }
  }
}
