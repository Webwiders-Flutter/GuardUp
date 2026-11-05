import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';

/// "About" tab content displaying operative biography and the interactive booking configuration card.
class GuardAboutBookingCard extends StatelessWidget {
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

  const GuardAboutBookingCard({
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
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedStartDate = dateFormat.format(startDate);
    final formattedEndDate = dateFormat.format(endDate);

    final startPeriod = startTime.period == DayPeriod.am ? 'AM' : 'PM';
    final formattedStartTime =
        '${startTime.hourOfPeriod.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} $startPeriod';

    final endPeriod = endTime.period == DayPeriod.am ? 'AM' : 'PM';
    final formattedEndTime =
        '${endTime.hourOfPeriod.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')} $endPeriod';

    return SingleChildScrollView(
      padding: context.horizontalEdgeInsets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Biography
          QuickContainer(
            w: double.infinity,
            p: AppSpacing.md,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: context.colors.onPrimary.withValues(alpha: 0.3),
            border: Border.all(
              color: context.colors.borderColor.withValues(alpha: 0.3),
              width: 1,
            ),
            child: Text(
              bio,
              style: context.textTheme.bodySmall
                  ?.copyWith(fontSize: 12, height: 1.5)
                  .colour(context.colors.onSurfaceVariant),
            ),
          ),
          AppSpacing.lg.h,

          // BOOKING DETAILS Card
          QuickContainer(
            w: double.infinity,
            p: AppSpacing.md,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: context.colors.onPrimary.withValues(alpha: 0.3),
            border: Border.all(
              color: context.colors.borderColor.withValues(alpha: 0.3),
              width: 1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: context.colors.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        AppSpacing.xs.w,
                        Text(
                          'BOOKING DETAILS',
                          style: context.textTheme.titleSmall
                              ?.bold()
                              .copyWith(letterSpacing: 0.8)
                              .colour(context.colors.onSurface),
                        ),
                      ],
                    ),

                    // Instant Confirmation Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: context.colors.gold.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'Instant Confirmation',
                        style: context.textTheme.labelSmall
                            ?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            )
                            .colour(context.colors.gold),
                      ),
                    ),
                  ],
                ),
                Divider(
                  color: context.colors.borderColor.withValues(alpha: .4),
                  height: 25,
                ),

                // Notice
                QuickContainer(
                  w: double.infinity,
                  p: 5,
                  px: 10,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  color: context.colors.error.withValues(alpha: 0.15),
                  border: Border.all(
                    color: context.colors.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  child: Text(
                    'Bodyguard bookings require a minimum duration of 2 hours.',
                    style: context.textTheme.bodySmall
                        ?.copyWith(fontSize: 10.5)
                        .colour(context.colors.error),
                  ),
                ),
                AppSpacing.md.h,

                // 2x2 Date & Time Selectors
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectorTile(
                        context,
                        label: 'START DATE',
                        value: formattedStartDate,
                        icon: Assets.svg.calender.path,
                        onTap: onPickStartDate,
                      ),
                    ),
                    AppSpacing.md.w,
                    Expanded(
                      child: _buildSelectorTile(
                        context,
                        label: 'START TIME',
                        value: formattedStartTime,
                        icon: Assets.svg.clock.path,
                        onTap: onPickStartTime,
                      ),
                    ),
                  ],
                ),
                AppSpacing.md.h,
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectorTile(
                        context,
                        label: 'END DATE',
                        value: formattedEndDate,
                        icon: Assets.svg.calender.path,
                        onTap: onPickEndDate,
                      ),
                    ),
                    AppSpacing.md.w,
                    Expanded(
                      child: _buildSelectorTile(
                        context,
                        label: 'END TIME',
                        value: formattedEndTime,
                        icon: Assets.svg.clock.path,
                        onTap: onPickEndTime,
                      ),
                    ),
                  ],
                ),

                AppSpacing.lg.h,

                // Price Breakdown
                QuickContainer(
                  w: double.infinity,
                  p: AppSpacing.md,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  color: context.colors.onPrimary.withValues(alpha: 0.3),
                  border: Border.all(
                    color: context.colors.borderColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Base Rate (\$${hourlyRate.toInt()} x $durationHours hrs)',
                            style: context.textTheme.bodySmall?.colour(
                              context.colors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '\$${totalBaseRate.toStringAsFixed(2)}',
                            style: context.textTheme.bodySmall?.colour(
                              context.colors.onSurface,
                            ),
                          ),
                        ],
                      ),

                      AppSpacing.sm.h,

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Executive Protection Fee',
                            style: context.textTheme.bodySmall?.colour(
                              context.colors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Included',
                            style: context.textTheme.bodySmall?.colour(
                              context.colors.success,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.md.h,

                      Divider(
                        color: context.colors.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                        height: 1,
                      ),
                      AppSpacing.md.h,

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: context.textTheme.titleSmall?.bold().colour(
                              context.colors.onSurface,
                            ),
                          ),
                          Text(
                            '\$${totalBaseRate.toStringAsFixed(2)}',
                            style: context.textTheme.titleMedium?.bold().colour(
                              context.colors.gold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorTile(
    BuildContext context, {
    required String label,
    required String value,
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          // color: context.colors.surfaceDim,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.textTheme.labelSmall
                  ?.copyWith(fontSize: 9.5)
                  .colour(context.colors.onSurfaceVariant),
            ),
            AppSpacing.xs.h,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelMedium?.bold().colour(
                      context.colors.onSurface,
                    ),
                  ),
                ),
                Icon(
                  label.contains('TIME')
                      ? Icons.access_time_rounded
                      : Icons.calendar_today_rounded,
                  size: 14,
                  color: context.colors.gold,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
