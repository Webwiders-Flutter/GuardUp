import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/logger/app_logger.dart';
import '/features/dashboard/data/models/dashboard_user_stats.model.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/shared/widgets/dashboard/models/dashboard_stats_models.dart';

abstract interface class IDashboardStatsRepository {
  Future<DashboardUserStats> getUserStats({
    required DateFilterOption option,
    DateTimeRange? customRange,
    UserRoleType? role,
    UserStatus? status,
  });
}

/// Repository responsible for querying aggregated dashboard metrics and distribution statistics.
final class DashboardStatsRepository implements IDashboardStatsRepository {
  final SupabaseClient _client;

  const DashboardStatsRepository(this._client);

  @override
  Future<DashboardUserStats> getUserStats({
    required DateFilterOption option,
    DateTimeRange? customRange,
    UserRoleType? role,
    UserStatus? status,
  }) async {
    try {
      var query = _client
          .from(DatabaseTables.users)
          .select(
            '${JsonKeys.role}, ${JsonKeys.registrationStatus}, ${JsonKeys.createdAt}',
          );

      // Negate admin role from platform user stats
      query = query.neq(JsonKeys.role, UserRoleType.admin.apiValue);

      // Negate deleted users and incomplete profiles
      query = query
          .neq(JsonKeys.registrationStatus, UserStatus.deleted.apiValue)
          .neq(JsonKeys.registrationStatus, UserStatus.incomplete.apiValue);

      if (role != null && role != UserRoleType.admin) {
        query = query.eq(JsonKeys.role, role.apiValue);
      }
      if (status != null) {
        query = query.eq(JsonKeys.registrationStatus, status.apiValue);
      }

      // Date filtering
      DateTime? start;
      DateTime? end;

      if (option == DateFilterOption.custom && customRange != null) {
        start = customRange.start;
        end = customRange.end;
      } else {
        final range = option.getRange();
        start = range.start;
        end = range.end;
      }

      if (start != null) {
        query = query.gte(JsonKeys.createdAt, start.toIso8601String());
      }
      if (end != null) {
        query = query.lte(JsonKeys.createdAt, end.toIso8601String());
      }

      final response = await query;
      final rows = response as List<dynamic>;

      if (rows.isEmpty) {
        return const DashboardUserStats.zero();
      }

      var active = 0;
      var pending = 0;
      var approvalPending = 0;
      var blocked = 0;
      var deleted = 0;

      var customers = 0;
      var guards = 0;
      var companies = 0;

      for (final row in rows) {
        final map = row as Map<String, dynamic>;
        final rawRole = map[JsonKeys.role]?.toString();
        final rawStatus = map[JsonKeys.registrationStatus]?.toString();

        if (rawRole != null &&
            rawRole.toUpperCase() ==
                UserRoleType.admin.apiValue.toUpperCase()) {
          continue;
        }

        final parsedStatus = UserStatus.fromApi(rawStatus);
        switch (parsedStatus) {
          case UserStatus.active:
            active++;
            break;
          case UserStatus.approvalPending:
            approvalPending++;
            break;
          case UserStatus.incomplete:
            pending++;
            break;
          case UserStatus.blocked:
            blocked++;
            break;
          case UserStatus.deleted:
            deleted++;
            break;
          case null:
            break;
        }

        final parsedRole = UserRoleType.fromApi(rawRole);
        switch (parsedRole) {
          case UserRoleType.customer:
            customers++;
            break;
          case UserRoleType.guard:
            guards++;
            break;
          case UserRoleType.company:
            companies++;
            break;
          case UserRoleType.admin:
          case null:
            break;
        }
      }

      final totalPlatformUsers = customers + guards + companies;

      return DashboardUserStats(
        totalUsers: totalPlatformUsers,
        activeUsers: active,
        pendingUsers: pending,
        approvalPendingUsers: approvalPending,
        blockedUsers: blocked,
        deletedUsers: deleted,
        customerCount: customers,
        guardCount: guards,
        companyCount: companies,
        adminCount: 0,
        activeTrend: 0.0,
        pendingTrend: 0.0,
        blockedTrend: 0.0,
      );
    } catch (e, st) {
      AppLogger.e(
        'Failed to fetch user stats from Supabase',
        error: e,
        stackTrace: st,
      );
      return const DashboardUserStats.zero();
    }
  }
}
