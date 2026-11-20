import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '../../buttons/app_icon_button.dart';
import '../models/dashboard_stats_models.dart';
import 'dashboard_filter_button.dart';

/// Time-period filter pill (presets + custom range) with an optional refresh
/// button, for dashboard card headers.
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DashboardFilterButton<DateFilterOption>(
          label: _displayLabel,
          icon: Icons.calendar_today_outlined,
          menuTitle: 'Time period',
          tooltip: 'Select time period',
          isActive: selectedOption != DateFilterOption.allTime,
          entries: [
            for (final option in DateFilterOption.values)
              (
                value: option,
                label: option == DateFilterOption.custom
                    ? '${option.label}…'
                    : option.label,
                icon: option == DateFilterOption.custom
                    ? Icons.date_range_outlined
                    : null,
                isSelected: option == selectedOption,
                dividerBefore: option == DateFilterOption.custom,
              ),
          ],
          onSelected: (option) {
            if (option == DateFilterOption.custom) {
              _handleCustomDateRange(context);
            } else {
              onFilterChanged(option, null);
            }
          },
        ),
        if (onRefresh != null) ...[
          (AppSpacing.xs + 2).w,
          AppIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh this metric',
            size: AppIconButtonSize.small,
            foregroundColor: context.colors.onSurfaceSecondary,
            isLoading: isRefreshing,
            onPressed: onRefresh,
          ),
        ],
      ],
    );
  }
}
