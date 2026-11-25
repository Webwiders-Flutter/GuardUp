import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '../../data/enum/bodyguard_availability_status.enum.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/auth.dart';

/// Row of 3 metric summary cards: Experience, Qualifications, and Availability or Verification Status.
class GuardMetricsRowWidget extends StatelessWidget {
  final String experience;
  final String qualifications;
  final BodyguardAvailabilityStatus status;
  final UserStatus? verificationStatus;

  const GuardMetricsRowWidget({
    super.key,
    this.experience = '0 yrs',
    this.qualifications = 'Not specified',
    this.status = BodyguardAvailabilityStatus.notSet,
    this.verificationStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isUnapproved =
        verificationStatus != null && verificationStatus != UserStatus.active;
    final statusLabel = isUnapproved ? 'Account Status' : 'Status';
    final statusValue = isUnapproved ? verificationStatus!.label : status.label;
    final statusColor = isUnapproved
        ? verificationStatus!.color(context)
        : status.badgeColor(context);
    final hasDot = isUnapproved ? true : status.hasDot;

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

        // 3. Status (Availability or Account Verification Status if unapproved)
        Expanded(
          child: _buildMetricBox(
            context,
            label: statusLabel,
            valueWidget: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasDot) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  AppSpacing.xs.w,
                ],
                Flexible(
                  child: Text(
                    statusValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.colour(statusColor),
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
