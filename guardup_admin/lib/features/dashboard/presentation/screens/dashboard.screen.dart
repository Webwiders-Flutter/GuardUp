import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/dashboard/data/models/dashboard_user_stats.model.dart';
import '/features/dashboard/di/dashboard.providers.dart';
import '/features/dashboard/presentation/controllers/dashboard_stats.controller.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/shared/widgets/dashboard/models/dashboard_stats_models.dart';
import '/shared/widgets/dashboard/widgets/dashboard_dropdown_filter.dart';
import '/shared/widgets/dashboard/widgets/dashboard_stats_card.dart';

/// Executive Command Dashboard screen for GuardUp Admin.
/// Displays clean, modern KPI analytics cards for Users, Operatives, and Verification queues.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final ValueNotifier<DashboardFilterParam> _userFilterNotifier =
      ValueNotifier<DashboardFilterParam>((
        option: DateFilterOption.last30Days,
        customRange: null,
        role: null,
        status: null,
      ));

  @override
  void dispose() {
    _userFilterNotifier.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref
        .read(
          dashboardStatsControllerProvider(_userFilterNotifier.value).notifier,
        )
        .refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Header ──
            _buildTopHeader(context),
            AppSpacing.xl.h,

            // ── Quick Summary Cards Row ──
            _buildQuickKpiRow(context),
            AppSpacing.xl.h,

            // ── Responsive Analytics Cards ──
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 960;
                final roleCard = _buildRoleCard(context);
                final statusCard = _buildStatusCard(context);

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: roleCard),
                      AppSpacing.lg.w,
                      Expanded(child: statusCard),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    roleCard,
                    AppSpacing.xl.h,
                    statusCard,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GuardUp Executive Dashboard',
              style: context.textTheme.headlineSmall?.bold().colour(
                colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time overview of users, bodyguard operatives, companies and approval queues.',
              style: context.textTheme.bodyMedium?.colour(
                colors.onSurfaceSecondary,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: _refreshAll,
          borderRadius: AppRadius.smRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.smRadius,
              border: Border.all(color: colors.borderLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: AppSpacing.md + 2,
                  color: colors.primary,
                ),
                AppSpacing.xs.w,
                Text(
                  'Refresh All',
                  style: context.textTheme.bodySmall?.semiBold().colour(
                    colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickKpiRow(BuildContext context) {
    return ValueListenableBuilder<DashboardFilterParam>(
      valueListenable: _userFilterNotifier,
      builder: (context, userParam, _) {
        final userAsync = ref.watch(
          dashboardStatsControllerProvider(userParam),
        );
        final stats = userAsync.value ?? const DashboardUserStats.zero();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 960;
            final cards = [
              _buildKpiCard(
                context,
                title: 'Total Users',
                value: stats.totalUsers.toString(),
                icon: Icons.groups_outlined,
                color: context.colors.primary,
              ),
              _buildKpiCard(
                context,
                title: 'Customers',
                value: stats.customerCount.toString(),
                icon: Icons.person_outline,
                color: context.colors.success,
              ),
              _buildKpiCard(
                context,
                title: 'Bodyguards',
                value: stats.guardCount.toString(),
                icon: Icons.security_outlined,
                color: context.colors.secondary,
              ),
              _buildKpiCard(
                context,
                title: 'Companies',
                value: stats.companyCount.toString(),
                icon: Icons.business_outlined,
                color: context.colors.warning,
              ),
              _buildKpiCard(
                context,
                title: 'Pending Review',
                value: stats.approvalPendingUsers.toString(),
                icon: Icons.hourglass_top_outlined,
                color: stats.approvalPendingUsers > 0
                    ? context.colors.error
                    : context.colors.onSurfaceSecondary,
              ),
            ];

            if (isDesktop) {
              return Row(
                children: cards
                    .map((c) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: c,
                          ),
                        ))
                    .toList(),
              );
            }

            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: cards
                  .map((c) => SizedBox(
                        width: (constraints.maxWidth - AppSpacing.md) / 2,
                        child: c,
                      ))
                  .toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: context.textTheme.bodySmall?.semiBold().colour(
                  colors.onSurfaceSecondary,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          AppSpacing.sm.h,
          Text(
            value,
            style: context.textTheme.headlineMedium?.bold().colour(
              colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context) {
    return ValueListenableBuilder<DashboardFilterParam>(
      valueListenable: _userFilterNotifier,
      builder: (context, userParam, _) {
        final userAsync = ref.watch(
          dashboardStatsControllerProvider(userParam),
        );
        final stats = userAsync.value ?? DashboardUserStats.sample();
        final chartData = stats.toRoleChartData(
          context,
          statusFilter: userParam.status,
          roleFilter: userParam.role,
        );

        return DashboardStatsCard(
          chartData: chartData,
          heading: 'Users by Platform Role',
          height: 350,
          initialChartType: ChartDisplayType.ring,
          initialDateFilter: userParam.option,
          initialCustomRange: userParam.customRange,
          isLoading: userAsync.isLoading,
          filters: [
            DashboardDropdownFilter<UserRoleType?>(
              prefixLabel: 'Role',
              selectedValue: userParam.role,
              options: [
                const DashboardDropdownOption(label: 'All Roles', value: null),
                ...UserRoleType.platformRoles.map(
                  (r) => DashboardDropdownOption(
                    label: r.label(context.l10n),
                    value: r,
                  ),
                ),
              ],
              onSelected: (selectedRole) {
                _userFilterNotifier.value = (
                  option: userParam.option,
                  customRange: userParam.customRange,
                  role: selectedRole,
                  status: userParam.status,
                );
              },
            ),
          ],
          onDateFilterChanged: (option, customRange) {
            _userFilterNotifier.value = (
              option: option,
              customRange: customRange,
              role: userParam.role,
              status: userParam.status,
            );
          },
          onRefresh: () => ref
              .read(dashboardStatsControllerProvider(userParam).notifier)
              .refresh(),
        );
      },
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return ValueListenableBuilder<DashboardFilterParam>(
      valueListenable: _userFilterNotifier,
      builder: (context, userParam, _) {
        final userAsync = ref.watch(
          dashboardStatsControllerProvider(userParam),
        );
        final stats = userAsync.value ?? DashboardUserStats.sample();
        final chartData = stats.toStatusChartData(
          context,
          roleFilter: userParam.role,
        );

        return DashboardStatsCard(
          chartData: chartData,
          heading: 'Users by Account Status',
          height: 350,
          initialChartType: ChartDisplayType.bar,
          initialDateFilter: userParam.option,
          initialCustomRange: userParam.customRange,
          isLoading: userAsync.isLoading,
          filters: [
            DashboardDropdownFilter<UserStatus?>(
              prefixLabel: 'Status',
              selectedValue: userParam.status,
              options: [
                const DashboardDropdownOption(
                  label: 'All Statuses',
                  value: null,
                ),
                ...UserStatus.values.map(
                  (s) => DashboardDropdownOption(
                    label: s.label(context.l10n),
                    value: s,
                  ),
                ),
              ],
              onSelected: (selectedStatus) {
                _userFilterNotifier.value = (
                  option: userParam.option,
                  customRange: userParam.customRange,
                  role: userParam.role,
                  status: selectedStatus,
                );
              },
            ),
          ],
          onDateFilterChanged: (option, customRange) {
            _userFilterNotifier.value = (
              option: option,
              customRange: customRange,
              role: userParam.role,
              status: userParam.status,
            );
          },
          onRefresh: () => ref
              .read(dashboardStatsControllerProvider(userParam).notifier)
              .refresh(),
        );
      },
    );
  }
}
