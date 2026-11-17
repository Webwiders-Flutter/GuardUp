import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '../models/dashboard_stats_models.dart';

/// Clean, unified date range selector and optional refresh control for dashboard widgets.
/// Supports preset periods, custom date range picker, and cohesive action capsule styling.
class DashboardDateFilterPicker extends StatelessWidget {
  final DateFilterOption selectedOption;
  final DateTimeRange? customRange;
  final void Function(DateFilterOption option, DateTimeRange? customRange)
  onFilterChanged;
  final VoidCallback? onRefresh;
  final bool isRefreshing;

  const DashboardDateFilterPicker({
    super.key,
    required this.selectedOption,
    this.customRange,
    required this.onFilterChanged,
    this.onRefresh,
    this.isRefreshing = false,
  });

  String get _displayLabel {
    if (selectedOption == DateFilterOption.custom && customRange != null) {
      final startFmt = DateFormat('d MMM').format(customRange!.start);
      final endFmt = DateFormat('d MMM yyyy').format(customRange!.end);
      return '$startFmt - $endFmt';
    }
    return selectedOption.label;
  }

  Future<void> _handleCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange:
          customRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: context.colors.primary,
              onPrimary: context.colors.onPrimary,
              surface: context.colors.surface,
              onSurface: context.colors.onSurface,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      onFilterChanged(DateFilterOption.custom, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = context.colors.borderLight;
    final primaryColor = context.colors.primary;

    return QuickContainer(
      radius: AppRadius.md,
      color: context.colors.backgroundLight,
      border: Border.all(color: borderColor),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Date Dropdown Button ──────────────────────────────────────────
          PopupMenuButton<DateFilterOption>(
            tooltip: 'Select Time Period',
            offset: const Offset(0, 36),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.mdRadius,
              side: BorderSide(color: borderColor),
            ),
            elevation: 4,
            color: context.colors.surface,
            onSelected: (option) {
              if (option == DateFilterOption.custom) {
                _handleCustomDateRange(context);
              } else {
                onFilterChanged(option, null);
              }
            },
            itemBuilder: (context) {
              return DateFilterOption.values.map((option) {
                final isSelected = selectedOption == option;
                return PopupMenuItem<DateFilterOption>(
                  value: option,
                  height: AppSpacing.xxl + 4,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs + 2,
                    vertical: 2,
                  ),
                  child: QuickContainer(
                    px: AppSpacing.md,
                    py: AppSpacing.sm,
                    radius: AppRadius.sm,
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.1)
                        : context.colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.3)
                          : context.colors.transparent,
                    ),
                    child: Text(
                      option.label,
                      style: context.textTheme.bodyMedium
                          ?.colour(
                            isSelected
                                ? primaryColor
                                : context.colors.onSurface,
                          )
                          .weight(
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                    ),
                  ),
                );
              }).toList();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 4,
                vertical: AppSpacing.xs + 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Text(
                      _displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelMedium?.semiBold().colour(
                        context.colors.onSurface,
                      ),
                    ),
                  ),
                  AppSpacing.xs.w,
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: AppSpacing.lg,
                    color: context.colors.onSurfaceSecondary,
                  ),
                ],
              ),
            ),
          ),

          // ── Divider & Refresh Button Capsule ─────────────────────────────
          if (onRefresh != null) ...[
            Container(width: 1, height: 20, color: borderColor),
            Material(
              color: context.colors.transparent,
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(AppRadius.md),
              ),
              child: InkWell(
                onTap: isRefreshing ? null : onRefresh,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(AppRadius.md),
                ),
                hoverColor: primaryColor.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 1,
                    vertical: AppSpacing.xs + 2,
                  ),
                  child: isRefreshing
                      ? SizedBox(
                          width: AppSpacing.md + 1,
                          height: AppSpacing.md + 1,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryColor,
                          ),
                        )
                      : Tooltip(
                          message: 'Refresh this metric',
                          child: Icon(
                            Icons.refresh_rounded,
                            size: AppSpacing.lg,
                            color: context.colors.onSurfaceSecondary,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
