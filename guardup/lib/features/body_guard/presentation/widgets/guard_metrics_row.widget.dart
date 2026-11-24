import 'package:flutter/material.dart';
import 'package:guardup/features/auth/data/enum/user_status.enum.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';

/// Row of 3 metric summary cards: Experience, Qualifications, and Availability Status.
class GuardMetricsRowWidget extends StatelessWidget {
  final String experience;
  final String qualifications;
  final UserStatus status;

  const GuardMetricsRowWidget({
    super.key,
    this.experience = '5+ yrs',
    this.qualifications = 'Certified Spec',
    this.status= UserStatus.active,
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
                    color: status.color(context),
                    shape: BoxShape.circle,
                  ),
                ),
                AppSpacing.xs.w,
                Flexible(
                  child: Text(
                    status.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.colour(
                      status.color(context),
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
      p: 10,
      radius: 12,
      color: context.colors.onPrimary.withValues(alpha: 0.6),
      borderColor: context.colors.onSurface.withValues(alpha: 0.15),
      child: Column(
        children: [
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.onSurface.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
          AppSpacing.xxs.h,
          valueWidget,
        ],
      ),
    );
  }
}
