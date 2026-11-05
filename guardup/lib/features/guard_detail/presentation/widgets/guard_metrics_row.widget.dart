import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';

/// Row of 3 metric summary cards: Experience, Qualifications, and Availability Status.
class GuardMetricsRowWidget extends StatelessWidget {
  final String experience;
  final String qualifications;
  final String status;
  final bool isAvailable;

  const GuardMetricsRowWidget({
    super.key,
    this.experience = '5+ yrs',
    this.qualifications = 'Certified Spec',
    this.status = 'Available',
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Experience
        Expanded(
          child: _buildMetricBox(
            context,
            label: 'Experience',
            valueWidget: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_outline_rounded,
                  size: 14,
                  color: context.colors.primary,
                ),
                05.w,
                Text(
                  experience,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
        AppSpacing.sm.w,

        // 2. Qualifications
        Expanded(
          child: _buildMetricBox(
            context,
            label: 'Qualifications',
            valueWidget: Text(
              qualifications,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall,
            ),
          ),
        ),
        AppSpacing.sm.w,

        // 3. Status
        Expanded(
          child: _buildMetricBox(
            context,
            label: 'Status',
            valueWidget: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? context.colors.success
                        : context.colors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                AppSpacing.xs.w,
                Flexible(
                  child: Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.colour(
                      isAvailable
                          ? context.colors.success
                          : context.colors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox(
    BuildContext context, {
    required String label,
    required Widget valueWidget,
  }) {
    return QuickContainer(
      py: 13,
      px: AppSpacing.xs,
      borderRadius: BorderRadius.circular(AppRadius.md),
      // color: context.colors.onPrimary,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.7),
        width: 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.textTheme.labelSmall
                ?.copyWith(fontSize: 10)
                .colour(context.colors.onSurfaceVariant.withValues(alpha: 0.6)),
          ),
          AppSpacing.xs.h,
          valueWidget,
        ],
      ),
    );
  }
}
