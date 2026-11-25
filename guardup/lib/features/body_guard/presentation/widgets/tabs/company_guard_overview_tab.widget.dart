import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/body_guard/data/model/body_guard.model.dart';

/// Company View "Overview" Tab: Displays comprehensive operative operational statistics,
/// onboarding tenure, tactical clearance, bio, and assigned services.
class CompanyGuardOverviewTabWidget extends StatelessWidget {
  final BodyGuardModel bodyguard;

  const CompanyGuardOverviewTabWidget({super.key, required this.bodyguard});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: context.horizontalEdgeInsets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Joined Date Card
          QuickContainer(
            px: 14,
            py: 14,
            radius: 15,
            color: context.colors.onPrimary.withValues(alpha: 0.6),
            borderColor: context.colors.borderColor.withValues(alpha: 0.7),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: context.colors.primary,
                  size: 16,
                ),
                12.w,
                Text(
                  'Joined Member on ${bodyguard.createdAt != null ? DateFormat("d MMM, yyyy").format(bodyguard.createdAt!) : "Recently"}',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.lg.h,

          // Biography Card
          QuickContainer(
            w: double.infinity,
            p: AppSpacing.md,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: context.colors.onPrimary,
            border: Border.all(
              color: context.colors.borderColor.withValues(alpha: 0.5),
              width: 1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPERATIVE BIOGRAPHY',
                  style: context.textTheme.labelMedium
                      ?.bold()
                      .copyWith(letterSpacing: 0.8)
                      .colour(context.colors.onSurfaceVariant),
                ),
                AppSpacing.sm.h,
                Text(
                  bodyguard.bio.isNotEmpty ? bodyguard.bio : 'Specialized operative deployed for high-threat dignitary protection, tactical escort, and private perimeter security.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: context.colors.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.lg.h,

          // Rate & Performance Metrics
          QuickContainer(
            w: double.infinity,
            p: AppSpacing.md,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: context.colors.onPrimary,
            border: Border.all(
              color: context.colors.borderColor.withValues(alpha: 0.5),
              width: 1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPERATIONAL METRICS',
                  style: context.textTheme.labelMedium
                      ?.bold()
                      .copyWith(letterSpacing: 0.8)
                      .colour(context.colors.onSurfaceVariant),
                ),
                AppSpacing.md.h,
                _buildMetricRow(
                  context,
                  title: 'Hourly Billing Rate',
                  value: '\$${bodyguard.hourlyRate.toStringAsFixed(2)} / hr',
                  valueColor: context.colors.primary,
                ),
                // AppSpacing.sm.h,
                // _buildMetricRow(
                //   context,
                //   title: 'Completed Deployments',
                //   value: '${bodyguard.totalCompletedMissions > 0 ? bodyguard.totalCompletedMissions : 38} Missions',
                //   valueColor: context.colors.onSurface,
                // ),
                AppSpacing.sm.h,
                _buildMetricRow(
                  context,
                  title: 'Client Rating',
                  value:
                      '${bodyguard.rating.toStringAsFixed(1)} ★ (${bodyguard.reviewCount > 0 ? bodyguard.reviewCount : 0} Reviews)',
                  valueColor: context.colors.onSurface,
                ),
                AppSpacing.sm.h,
                _buildMetricRow(
                  context,
                  title: 'Services Offered',
                  value: bodyguard.serviceTypes.isNotEmpty
                      ? bodyguard.serviceTypes.map((x) => x.label).join(', ')
                      : 'Standard Protection',
                  valueColor: context.colors.onSurface,
                ),
              ],
            ),
          ),

          AppSpacing.xxl.h,
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: context.textTheme.bodyMedium?.colour(
            context.colors.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: context.textTheme.bodyMedium?.bold().colour(valueColor),
            textAlign: .right,
          ),
        ),
      ],
    );
  }
}
