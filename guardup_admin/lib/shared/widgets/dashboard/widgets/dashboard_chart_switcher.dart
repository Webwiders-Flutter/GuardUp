import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '../models/dashboard_stats_models.dart';

/// Segmented toolbar switcher allowing users to toggle between Ring, Pie, Bar,
/// and Card views with smooth micro-interactions.
class DashboardChartSwitcher extends StatelessWidget {
  final ChartDisplayType currentType;
  final ValueChanged<ChartDisplayType> onTypeChanged;
  final List<ChartDisplayType> allowedTypes;

  const DashboardChartSwitcher({
    super.key,
    required this.currentType,
    required this.onTypeChanged,
    this.allowedTypes = ChartDisplayType.values,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = context.colors.borderLight;
    final containerBg = context.colors.backgroundLight;

    return QuickContainer(
      py: AppSpacing.xs,
      px: AppSpacing.xs,
      radius: AppRadius.md,
      color: containerBg,
      border: Border.all(color: borderColor),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: allowedTypes.map((type) {
          final isSelected = currentType == type;
          final (icon, tooltip) = _metaFor(type);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Tooltip(
              message: tooltip,
              waitDuration: const Duration(milliseconds: 400),
              child: Material(
                color: isSelected
                    ? context.colors.primary
                    : context.colors.transparent,
                borderRadius: AppRadius.smRadius,
                child: InkWell(
                  onTap: () => onTypeChanged(type),
                  borderRadius: AppRadius.smRadius,
                  hoverColor: context.colors.primary.withValues(alpha: 0.08),
                  child: QuickContainer(
                    px: AppSpacing.sm + 2,
                    py: AppSpacing.sm - 2,
                    radius: AppRadius.sm,
                    child: Icon(
                      icon,
                      size: AppSpacing.lg + 2,
                      color: isSelected
                          ? context.colors.onPrimary
                          : context.colors.onSurfaceSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  (IconData, String) _metaFor(ChartDisplayType type) {
    switch (type) {
      case ChartDisplayType.ring:
        return (Icons.donut_large_rounded, 'Donut / Ring Chart');
      case ChartDisplayType.pie:
        return (Icons.pie_chart_rounded, 'Pie Chart');
      case ChartDisplayType.bar:
        return (Icons.bar_chart_rounded, 'Bar Chart');
      case ChartDisplayType.card:
        return (Icons.grid_view_rounded, 'Metric Cards Grid');
    }
  }
}
