import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';

/// Customer View "About" Tab: Displays operative biography and interactive booking duration selector.
class CustomerGuardAboutTabWidget extends StatelessWidget {
  final String bio;
  final double hourlyRate;
  final DateTime startDate;
  final TimeOfDay startTime;
  final DateTime endDate;
  final TimeOfDay endTime;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEndDate;
  final VoidCallback onPickEndTime;

  const CustomerGuardAboutTabWidget({
    super.key,
    required this.bio,
    this.hourlyRate = 60.0,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    required this.onPickStartDate,
    required this.onPickStartTime,
    required this.onPickEndDate,
    required this.onPickEndTime,
  });

  int get durationHours {
    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
    );
    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      endTime.hour,
      endTime.minute,
    );
    final diff = end.difference(start).inHours;
    return diff > 0 ? diff : 4;
  }

  double get totalBaseRate => hourlyRate * durationHours;

  @override
  Widget build(BuildContext context) {
    final startDayStr = DateFormat('EEE, d MMM yyyy').format(startDate);
    final endDayStr = DateFormat('EEE, d MMM yyyy').format(endDate);
    final startTimeStr = startTime.format(context);
    final endTimeStr = endTime.format(context);

    return SingleChildScrollView(
      padding: context.horizontalEdgeInsets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. About Operative Biography Card
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
                  'About Guard',
                  style: context.textTheme.labelMedium
                      ?.bold()
                      .copyWith(letterSpacing: 0.6)
                      .colour(context.colors.onSurfaceVariant),
                ),
                AppSpacing.sm.h,
                Text(
                  bio.isNotEmpty ? bio : 'Professional bodyguard with certified tactical protection, executive transport, and close perimeter security experience.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: context.colors.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.lg.h,

          // 2. Booking Configuration Card
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BOOKING DURATION',
                      style: context.textTheme.labelMedium
                          ?.bold()
                          .copyWith(letterSpacing: 0.8)
                          .colour(context.colors.onSurfaceVariant),
                    ),
                    Text(
                      '\$${hourlyRate.toStringAsFixed(0)} / hr',
                      style: context.textTheme.labelMedium?.bold().colour(
                        context.colors.primary,
                      ),
                    ),
                  ],
                ),
                AppSpacing.md.h,

                // Start Date & Time Pickers
                _buildPickerRow(
                  context: context,
                  label: 'START',
                  dateText: startDayStr,
                  timeText: startTimeStr,
                  onDateTap: onPickStartDate,
                  onTimeTap: onPickStartTime,
                ),
                AppSpacing.sm.h,

                // End Date & Time Pickers
                _buildPickerRow(
                  context: context,
                  label: 'END',
                  dateText: endDayStr,
                  timeText: endTimeStr,
                  onDateTap: onPickEndDate,
                  onTimeTap: onPickEndTime,
                ),

                AppSpacing.md.h,
                Divider(
                  color: context.colors.outlineVariant.withValues(alpha: 0.3),
                  height: 1,
                ),
                AppSpacing.md.h,

                // Duration & Total Rate Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Calculated Duration:',
                      style: context.textTheme.bodyMedium?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '$durationHours Hours',
                      style: context.textTheme.bodyMedium?.bold().colour(
                        context.colors.onSurface,
                      ),
                    ),
                  ],
                ),
                AppSpacing.xs.h,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Base Amount:',
                      style: context.textTheme.bodyMedium?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '\$${totalBaseRate.toStringAsFixed(2)}',
                      style: context.textTheme.titleMedium?.bold().colour(
                        context.colors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.xxl.h,
        ],
      ),
    );
  }

  Widget _buildPickerRow({
    required BuildContext context,
    required String label,
    required String dateText,
    required String timeText,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall
              ?.bold()
              .copyWith(letterSpacing: 0.5)
              .colour(context.colors.onSurfaceVariant),
        ),
        AppSpacing.xxs.h,
        Row(
          children: [
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: onDateTap,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: QuickContainer(
                  p: AppSpacing.sm,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  color: context.colors.surfaceContainer,
                  border: Border.all(
                    color: context.colors.outlineVariant.withValues(alpha: 0.5),
                    width: 0.7,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: context.colors.primary,
                      ),
                      AppSpacing.xs.w,
                      Expanded(
                        child: Text(
                          dateText,
                          style: context.textTheme.bodySmall?.bold().colour(
                            context.colors.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AppSpacing.xs.w,
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: onTimeTap,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: QuickContainer(
                  p: AppSpacing.sm,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  color: context.colors.surfaceContainer,
                  border: Border.all(
                    color: context.colors.outlineVariant.withValues(alpha: 0.5),
                    width: 0.7,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: context.colors.primary,
                      ),
                      AppSpacing.xs.w,
                      Expanded(
                        child: Text(
                          timeText,
                          style: context.textTheme.bodySmall?.bold().colour(
                            context.colors.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
