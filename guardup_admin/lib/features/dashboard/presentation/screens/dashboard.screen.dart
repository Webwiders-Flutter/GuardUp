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
import '/features/users/data/enums/user_status.enum.dart';
import '/shared/widgets/dashboard/models/dashboard_stats_models.dart';
import '/shared/widgets/dashboard/widgets/dashboard_dropdown_filter.dart';
import '/shared/widgets/dashboard/widgets/dashboard_stats_card.dart';

/// Executive Command Dashboard screen for GuardUp Admin.
/// Displays clean, modern KPI analytics cards for Users, Operatives, and Verification queues
/// following the architecture and design patterns of the Supplr admin portal.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final ValueNotifier<DashboardFilterParam> _roleFilterNotifier =
      ValueNotifier<DashboardFilterParam>((
        option: DateFilterOption.last30Days,
        customRange: null,
        role: null,
        status: null,
      ));

  @override
  void dispose() {
    _roleFilterNotifier.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref
        .read(
          dashboardStatsControllerProvider(_roleFilterNotifier.value).notifier,
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

            // ── Users by Platform Role ──
            _buildRoleCard(context),
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
              'Dashboard Overview',
              style: context.textTheme.headlineSmall?.bold().colour(
                colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time operational metrics across platform users, bodyguard operatives, and account compliance.',
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

  // ─────────────────────────────────────────────────────────────────────────────
  // Users by Platform Role Card (Filtered by Account Status)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildRoleCard(BuildContext context) {
    return ValueListenableBuilder<DashboardFilterParam>(
      valueListenable: _roleFilterNotifier,
      builder: (context, roleParam, _) {
        final userAsync = ref.watch(
          dashboardStatsControllerProvider(roleParam),
        );
        final stats = userAsync.value ?? DashboardUserStats.sample();
        final chartData = stats.toRoleChartData(
          context,
          statusFilter: roleParam.status,
        );

        return DashboardStatsCard(
          chartData: chartData,
          heading: 'Users',
          height: 350,
          initialChartType: ChartDisplayType.ring,
          initialDateFilter: roleParam.option,
          initialCustomRange: roleParam.customRange,
          isLoading: userAsync.isLoading,
          filters: [
            // Status dropdown filter (filters the role breakdown by account status)
            DashboardDropdownFilter<UserStatus?>(
              prefixLabel: 'Status',
              selectedValue: roleParam.status,
              options: [
                const DashboardDropdownOption(
                  label: 'All Statuses',
                  value: null,
                ),
                ...[
                  UserStatus.active,
                  UserStatus.approvalPending,
                  UserStatus.blocked,
                ].map(
                  (s) => DashboardDropdownOption(
                    label: s.label(context.l10n),
                    value: s,
                  ),
                ),
              ],
              onSelected: (selectedStatus) {
                _roleFilterNotifier.value = (
                  option: roleParam.option,
                  customRange: roleParam.customRange,
                  role: null,
                  status: selectedStatus,
                );
              },
            ),
          ],
          onDateFilterChanged: (option, customRange) {
            _roleFilterNotifier.value = (
              option: option,
              customRange: customRange,
              role: null,
              status: roleParam.status,
            );
          },
          onRefresh: () => ref
              .read(dashboardStatsControllerProvider(roleParam).notifier)
              .refresh(),
        );
      },
    );
  }
}
