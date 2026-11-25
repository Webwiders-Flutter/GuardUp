import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/extensions/localization.extension.dart';
import '/features/users/data/enums/week_day.enum.dart';
import '/features/users/data/models/user_availability.model.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/sections/app_detail_section.dart';

/// Weekly working hours from `user_availabilities`, Monday → Sunday.
class UserAvailabilitySection extends StatelessWidget {
  const UserAvailabilitySection({super.key, required this.availabilities});

  /// Rows of an account or of a company-managed bodyguard.
  final List<UserAvailabilityModel>? availabilities;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rows = availabilities ?? const <UserAvailabilityModel>[];
    final hasSchedule = rows.isNotEmpty;
    final availableDays = rows.where((r) => r.isAvailable).length;

    return AppDetailSection(
      title: 'Weekly Availability',
      subtitle: hasSchedule
          ? 'Available $availableDays of 7 days'
          : 'No schedule set yet',
      icon: Icons.event_available_outlined,
      child: !hasSchedule
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No weekly availability has been set yet.',
                style: context.textTheme.bodyMedium?.colour(
                  colors.onSurfaceSecondary,
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: colors.backgroundLight,
                borderRadius: AppRadius.smRadius,
                border: Border.all(color: colors.borderLight),
              ),
              child: Column(
                children: [
                  for (final day in WeekDay.values) ...[
                    if (day != WeekDay.values.first)
                      Divider(
                        color: colors.borderLight.withValues(alpha: 0.5),
                        height: 1,
                      ),
                    _DayRow(
                      day: day,
                      row: rows.where((r) => r.dayOfWeek == day).firstOrNull,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, this.row});

  final WeekDay day;

  /// Null when the user has not set this day.
  final UserAvailabilityModel? row;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isAvailable = row?.isAvailable == true;

    final (
      String statusLabel,
      Color statusColor,
      IconData statusIcon,
    ) = row == null
        ? ('Not set', colors.onSurfaceSecondary, Icons.remove_circle_outline)
        : isAvailable
        ? ('Available', colors.success, Icons.check_circle_outline_rounded)
        : ('Off', colors.error, Icons.do_not_disturb_on_outlined);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              day.label(context.l10n),
              style: context.textTheme.bodyMedium?.semiBold().colour(
                isAvailable ? colors.onSurface : colors.onSurfaceSecondary,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: AppSpacing.md,
                  color: isAvailable
                      ? colors.primary
                      : colors.onSurfaceSecondary.withValues(alpha: 0.5),
                ),
                AppSpacing.xs.w,
                Flexible(
                  child: Text(
                    isAvailable ? '${row!.fromTime} – ${row!.toTime}' : '—',
                    style: context.textTheme.bodyMedium?.colour(
                      isAvailable
                          ? colors.onSurface
                          : colors.onSurfaceSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          AppChip(
            title: statusLabel,
            icon: statusIcon,
            color: statusColor,
            size: AppChipSize.small,
          ),
        ],
      ),
    );
  }
}
