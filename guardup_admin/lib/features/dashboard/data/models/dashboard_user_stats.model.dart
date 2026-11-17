import 'package:flutter/material.dart';

import '/core/extensions/localization.extension.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/shared/widgets/dashboard/models/dashboard_stats_models.dart';

/// Aggregated user statistics entity for the GuardUp admin dashboard.
class DashboardUserStats {
  final int totalUsers;
  final int activeUsers;
  final int pendingUsers;
  final int approvalPendingUsers;
  final int blockedUsers;
  final int deletedUsers;

  final int customerCount;
  final int guardCount;
  final int companyCount;
  final int adminCount;

  final double activeTrend;
  final double pendingTrend;
  final double blockedTrend;

  const DashboardUserStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.pendingUsers,
    required this.approvalPendingUsers,
    required this.blockedUsers,
    required this.deletedUsers,
    required this.customerCount,
    required this.guardCount,
    required this.companyCount,
    required this.adminCount,
    this.activeTrend = 8.4,
    this.pendingTrend = -2.1,
    this.blockedTrend = 0.0,
  });

  /// Zero-initialized instance.
  const DashboardUserStats.zero()
    : totalUsers = 0,
      activeUsers = 0,
      pendingUsers = 0,
      approvalPendingUsers = 0,
      blockedUsers = 0,
      deletedUsers = 0,
      customerCount = 0,
      guardCount = 0,
      companyCount = 0,
      adminCount = 0,
      activeTrend = 0.0,
      pendingTrend = 0.0,
      blockedTrend = 0.0;

  /// Default fallback: returns zero stats.
  factory DashboardUserStats.sample() => const DashboardUserStats.zero();

  /// Returns zero stats on filter/fallback.
  factory DashboardUserStats.sampleFor({
    UserRoleType? role,
    UserStatus? status,
  }) => const DashboardUserStats.zero();

  /// Returns the recorded count for a given [UserStatus].
  int countForStatus(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return activeUsers;
      case UserStatus.approvalPending:
        return approvalPendingUsers;
      case UserStatus.incomplete:
        return pendingUsers;
      case UserStatus.blocked:
        return blockedUsers;
      case UserStatus.rejected:
        return 0;
      case UserStatus.deleted:
        return deletedUsers;
    }
  }

  /// Returns the recorded count for a given [UserRoleType].
  int countForRole(UserRoleType role) {
    switch (role) {
      case UserRoleType.customer:
        return customerCount;
      case UserRoleType.guard:
        return guardCount;
      case UserRoleType.company:
        return companyCount;
      case UserRoleType.admin:
        return adminCount;
    }
  }

  /// Builds [DashboardChartData] for user status distribution.
  DashboardChartData toStatusChartData(
    BuildContext context, {
    UserRoleType? roleFilter,
  }) {
    final l10n = context.l10n;

    final items = [
      UserStatus.active,
      UserStatus.approvalPending,
      UserStatus.blocked,
    ].map((status) {
      return StatMetricItem(
        id: status.apiValue,
        title: status.label(l10n),
        value: countForStatus(status).toDouble(),
        color: status.color(context),
        icon: status.icon,
        subtitle: status.subtitle,
      );
    }).toList();

    final subtitle = roleFilter != null
        ? 'Status breakdown for ${roleFilter.label(l10n)} users'
        : 'Distribution across approved, pending review and restricted states';

    return DashboardChartData(
      title: 'Users by Account Status',
      subtitle: subtitle,
      items: items,
      unitSuffix: ' users',
    );
  }

  /// Builds [DashboardChartData] for user role distribution.
  DashboardChartData toRoleChartData(
    BuildContext context, {
    UserStatus? statusFilter,
    UserRoleType? roleFilter,
  }) {
    final l10n = context.l10n;

    final allItems = [
      UserRoleType.customer,
      UserRoleType.guard,
      UserRoleType.company,
    ].map((role) {
      return StatMetricItem(
        id: role.apiValue,
        title: role.label(l10n),
        value: countForRole(role).toDouble(),
        color: role.color(context),
        icon: role.icon,
        subtitle: role.description(l10n),
      );
    }).toList();

    final filteredItems = roleFilter != null
        ? allItems.where((x) => x.id == roleFilter.apiValue).toList()
        : allItems;

    final subtitle = statusFilter != null
        ? 'Filtered by ${statusFilter.label(l10n)} status'
        : 'Breakdown of Customers, Bodyguards and Security Companies';

    return DashboardChartData(
      title: 'Users by Platform Role',
      subtitle: subtitle,
      items: filteredItems,
      unitSuffix: ' users',
    );
  }
}
