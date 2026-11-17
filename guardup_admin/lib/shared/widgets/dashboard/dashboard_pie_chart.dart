import 'package:flutter/material.dart';

import 'models/dashboard_stats_models.dart';
import 'widgets/dashboard_stats_card.dart';

/// Legacy drop-in replacement & alias for [DashboardStatsCard].
/// Provides full backward compatibility with previously used [DashboardPieChart]
/// while upgrading to modern, responsive, animated UI and rich interaction capabilities.
class DashboardPieChart extends StatelessWidget {
  final DashboardChartData chartData;
  final String? heading;
  final String? subtitle;
  final String? currency;
  final double? width;
  final double height;
  final ChartDisplayType chartType;
  final bool showSwitcher;
  final bool showDateFilter;
  final DateFilterOption initialDateFilter;
  final void Function(DateFilterOption option, DateTimeRange? customRange)?
  onDateFilterChanged;
  final VoidCallback? onRefresh;
  final List<Widget>? filters;
  final List<Widget>? actions;

  const DashboardPieChart({
    super.key,
    required this.chartData,
    this.heading,
    this.subtitle,
    this.currency,
    this.width,
    this.height = 340.0,
    this.chartType = ChartDisplayType.ring,
    this.showSwitcher = true,
    this.showDateFilter = true,
    this.initialDateFilter = DateFilterOption.last30Days,
    this.onDateFilterChanged,
    this.onRefresh,
    this.filters,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardStatsCard(
      chartData: chartData,
      heading: heading,
      width: width,
      height: height,
      initialChartType: chartType,
      showSwitcher: showSwitcher,
      showDateFilter: showDateFilter,
      initialDateFilter: initialDateFilter,
      onDateFilterChanged: onDateFilterChanged,
      onRefresh: onRefresh,
      filters: filters,
      actions: actions,
    );
  }
}
