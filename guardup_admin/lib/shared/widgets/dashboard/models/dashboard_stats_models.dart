import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/core/extensions/context.extension.dart';

/// Supported chart & visual display representations for dashboard statistics.
enum ChartDisplayType {
  /// Circular donut / ring chart with center metrics & dynamic hover inspector.
  ring,

  /// Solid circular pie chart with subtle slice separations.
  pie,

  /// Horizontal or vertical proportional bar chart with percentage badges.
  bar,

  /// High-density responsive KPI stat cards with trend badges & icons.
  card,
}

/// Standard date range filter options for dashboard data.
enum DateFilterOption {
  allTime('All Time', 'All'),
  today('Today', '1D'),
  last7Days('Last 7 Days', '7D'),
  last30Days('Last 30 Days', '30D'),
  thisMonth('This Month', '1M'),
  thisYear('This Year', '1Y'),
  custom('Custom Range', 'Custom');

  final String label;
  final String shortLabel;

  const DateFilterOption(this.label, this.shortLabel);

  /// Computes the start and end dates for this filter option relative to [now].
  ({DateTime? start, DateTime? end}) getRange([DateTime? now]) {
    final reference = now ?? DateTime.now();
    final todayStart = DateTime(reference.year, reference.month, reference.day);
    final todayEnd = DateTime(
      reference.year,
      reference.month,
      reference.day,
      23,
      59,
      59,
      999,
    );

    switch (this) {
      case DateFilterOption.allTime:
      case DateFilterOption.custom:
        return (start: null, end: null);
      case DateFilterOption.today:
        return (start: todayStart, end: todayEnd);
      case DateFilterOption.last7Days:
        final start = todayStart.subtract(const Duration(days: 6));
        return (start: start, end: todayEnd);
      case DateFilterOption.last30Days:
        final start = todayStart.subtract(const Duration(days: 29));
        return (start: start, end: todayEnd);
      case DateFilterOption.thisMonth:
        final start = DateTime(reference.year, reference.month, 1);
        final end = DateTime(
          reference.year,
          reference.month + 1,
          0,
          23,
          59,
          59,
          999,
        );
        return (start: start, end: end);
      case DateFilterOption.thisYear:
        final start = DateTime(reference.year, 1, 1);
        final end = DateTime(reference.year, 12, 31, 23, 59, 59, 999);
        return (start: start, end: end);
    }
  }
}

/// Represents an individual metric slice, category, or status entry.
class StatMetricItem {
  /// Unique identifier for this metric (e.g., 'active', 'blocked', 'driver').
  final String id;

  /// Human-readable label (e.g., 'Active Users', 'Buyer / Seller').
  final String title;

  /// Numeric count or value.
  final double value;

  /// Optional specific color. If null, a color is assigned from the theme palette.
  final Color? color;

  /// Optional icon representing this metric.
  final IconData? icon;

  /// Optional secondary subtitle or caption (e.g., 'Requires verification').
  final String? subtitle;

  /// Optional percentage override. If omitted, calculated dynamically from total.
  final double? percentage;

  /// Optional trend percentage relative to previous period (e.g., 12.5 for +12.5%).
  final double? trendPercentage;

  /// Whether the trend is considered positive/desirable. Defaults to true if >= 0.
  final bool? isTrendPositive;

  /// Optional callback invoked when this slice or card is tapped.
  final VoidCallback? onTap;

  const StatMetricItem({
    required this.id,
    required this.title,
    required this.value,
    this.color,
    this.icon,
    this.subtitle,
    this.percentage,
    this.trendPercentage,
    this.isTrendPositive,
    this.onTap,
  });

  /// Factory helper for creating from count (int).
  factory StatMetricItem.fromCount({
    required String id,
    required String title,
    required int count,
    Color? color,
    IconData? icon,
    String? subtitle,
    double? trendPercentage,
    bool? isTrendPositive,
    VoidCallback? onTap,
  }) {
    return StatMetricItem(
      id: id,
      title: title,
      value: count.toDouble(),
      color: color,
      icon: icon,
      subtitle: subtitle,
      trendPercentage: trendPercentage,
      isTrendPositive: isTrendPositive,
      onTap: onTap,
    );
  }

  StatMetricItem copyWith({
    String? id,
    String? title,
    double? value,
    Color? color,
    IconData? icon,
    String? subtitle,
    double? percentage,
    double? trendPercentage,
    bool? isTrendPositive,
    VoidCallback? onTap,
  }) {
    return StatMetricItem(
      id: id ?? this.id,
      title: title ?? this.title,
      value: value ?? this.value,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      subtitle: subtitle ?? this.subtitle,
      percentage: percentage ?? this.percentage,
      trendPercentage: trendPercentage ?? this.trendPercentage,
      isTrendPositive: isTrendPositive ?? this.isTrendPositive,
      onTap: onTap ?? this.onTap,
    );
  }
}

/// Aggregated data container supplied to dashboard analytics widgets.
class DashboardChartData {
  /// Card header heading.
  final String title;

  /// Optional secondary subtitle description.
  final String? subtitle;

  /// List of metric items to visualize.
  final List<StatMetricItem> items;

  /// Optional currency prefix (e.g., '₹ ', '$ ').
  final String? currency;

  /// Optional unit suffix (e.g., ' users', ' trips', ' %').
  final String? unitSuffix;

  /// Optional total override. If null, computed as sum of [items].
  final double? customTotal;

  const DashboardChartData({
    required this.title,
    this.subtitle,
    required this.items,
    this.currency,
    this.unitSuffix,
    this.customTotal,
  });

  /// Computed total of all items.
  double get total {
    if (customTotal != null) return customTotal!;
    if (items.isEmpty) return 0.0;
    return items.fold<double>(0.0, (sum, item) => sum + item.value);
  }

  /// Whether the dataset has no items configured.
  bool get isEmpty => items.isEmpty;

  /// Whether the dataset has items configured.
  bool get isNotEmpty => items.isNotEmpty;

  /// Formats a numeric value with commas and optional currency/unit.
  String formatValue(double value, {bool compact = false}) {
    final prefix = currency ?? '';
    final suffix = unitSuffix ?? '';

    if (compact && value >= 1000) {
      final compactFormat = NumberFormat.compact();
      return '$prefix${compactFormat.format(value)}$suffix';
    }

    final hasDecimals = value % 1 != 0;
    final formatter = NumberFormat(hasDecimals ? '#,##0.00' : '#,##0');
    return '$prefix${formatter.format(value)}$suffix';
  }

  /// Formatted total string.
  String get formattedTotal => formatValue(total);

  /// Calculates percentage for a given [item].
  double percentageFor(StatMetricItem item) {
    if (item.percentage != null) return item.percentage!;
    if (total == 0) return 0.0;
    return (item.value / total) * 100.0;
  }

  /// Formatted percentage string (e.g. '34.5%').
  String formattedPercentage(StatMetricItem item) {
    return '${percentageFor(item).toStringAsFixed(1)}%';
  }

  /// Returns a curated color for the item at [index], adhering to the design system.
  Color colorFor(int index, BuildContext context) {
    if (index >= 0 && index < items.length && items[index].color != null) {
      return items[index].color!;
    }

    final colors = context.colors;
    final palette = [
      colors.primary,
      colors.secondary,
      colors.success,
      colors.warning,
      colors.info,
      colors.error,
    ];

    return palette[index % palette.length];
  }
}

/// Generic dropdown filter option for dashboard card filters (e.g., status, role, category).
class DashboardDropdownOption<T> {
  final String label;
  final T value;
  final IconData? icon;

  const DashboardDropdownOption({
    required this.label,
    required this.value,
    this.icon,
  });
}
