import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/utils/callback/async_callback.handler.dart';
import '/features/dashboard/data/models/dashboard_user_stats.model.dart';
import '/features/dashboard/data/repositories/dashboard_stats.repository.dart';
import '/features/dashboard/di/dashboard.providers.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/shared/widgets/dashboard/models/dashboard_stats_models.dart';

typedef DashboardFilterParam = ({
  DateFilterOption option,
  DateTimeRange? customRange,
  UserRoleType? role,
  UserStatus? status,
});

class DashboardStatsController extends AsyncNotifier<DashboardUserStats> {
  DashboardStatsController(this.filterParam);

  final DashboardFilterParam filterParam;

  DashboardStatsRepository get _repository =>
      ref.read(dashboardStatsRepositoryProvider);

  @override
  FutureOr<DashboardUserStats> build() async {
    return _fetchStats();
  }

  Future<DashboardUserStats> _fetchStats() async {
    return asyncHandler(() async {
      // Negate admin role: platform dashboard stats only tracks marketplace clients
      final role = filterParam.role?.isAdmin == true ? null : filterParam.role;

      return _repository.getUserStats(
        option: filterParam.option,
        customRange: filterParam.customRange,
        role: role,
        status: filterParam.status,
      );
    });
  }

  /// Forces a data refresh for the current filter.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchStats);
  }
}
