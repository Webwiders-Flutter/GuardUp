import 'dart:async';

import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '../models/dashboard_stats_models.dart';
import 'dashboard_bar_chart_view.dart';
import 'dashboard_chart_switcher.dart';
import 'dashboard_date_filter_picker.dart';
import 'dashboard_donut_chart_view.dart';
import 'dashboard_kpi_card_view.dart';

/// Professional, enterprise-grade analytics card.
/// Features a uniform, fixed height across all views, a single clean header with
/// grouped chart switcher & unified date/refresh capsule, and smooth body transitions.
class DashboardStatsCard extends StatefulWidget {
  final DashboardChartData chartData;
  final String? heading;
  final ChartDisplayType initialChartType;
  final bool showSwitcher;
  final List<ChartDisplayType> allowedChartTypes;
  final bool showDateFilter;
  final DateFilterOption initialDateFilter;
  final DateTimeRange? initialCustomRange;
  final void Function(DateFilterOption option, DateTimeRange? customRange)?
  onDateFilterChanged;
  final FutureOr<void> Function()? onRefresh;
  final List<Widget>? filters;
  final List<Widget>? actions;
  final double? width;
  final double height;
  final bool isLoading;

  const DashboardStatsCard({
    super.key,
    required this.chartData,
    this.heading,
    this.initialChartType = ChartDisplayType.ring,
    this.showSwitcher = true,
    this.allowedChartTypes = const [
      ChartDisplayType.ring,
      ChartDisplayType.bar,
      ChartDisplayType.card,
    ],
    this.showDateFilter = true,
    this.initialDateFilter = DateFilterOption.last30Days,
    this.initialCustomRange,
    this.onDateFilterChanged,
    this.onRefresh,
    this.filters,
    this.actions,
    this.width,
    this.height = 340.0,
    this.isLoading = false,
  });

  @override
  State<DashboardStatsCard> createState() => _DashboardStatsCardState();
}

class _DashboardStatsCardState extends State<DashboardStatsCard> {
  late final ValueNotifier<ChartDisplayType> _chartTypeNotifier;
  late final ValueNotifier<DateFilterOption> _dateFilterNotifier;
  late final ValueNotifier<DateTimeRange?> _customRangeNotifier;
  final ValueNotifier<bool> _isRefreshingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _chartTypeNotifier = ValueNotifier<ChartDisplayType>(
      widget.initialChartType,
    );
    _dateFilterNotifier = ValueNotifier<DateFilterOption>(
      widget.initialDateFilter,
    );
    _customRangeNotifier = ValueNotifier<DateTimeRange?>(
      widget.initialCustomRange,
    );
  }

  @override
  void dispose() {
    _chartTypeNotifier.dispose();
    _dateFilterNotifier.dispose();
    _customRangeNotifier.dispose();
    _isRefreshingNotifier.dispose();
    super.dispose();
  }

  void _onDateFilterChanged(
    DateFilterOption option,
    DateTimeRange? customRange,
  ) {
    _dateFilterNotifier.value = option;
    _customRangeNotifier.value = customRange;
    widget.onDateFilterChanged?.call(option, customRange);
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefresh == null || _isRefreshingNotifier.value) return;
    _isRefreshingNotifier.value = true;
    try {
      await widget.onRefresh!();
    } finally {
      if (mounted) {
        _isRefreshingNotifier.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = context.colors.borderLight;
    final cardBg = context.colors.surface;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: context.colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Clean Header (Title on left, Controls on right) ───────────────
          _buildHeader(context),
          AppSpacing.sm.h,

          // ── Subtle Divider ────────────────────────────────────────────────
          Divider(
            height: 1,
            thickness: 1,
            color: borderColor.withValues(alpha: 0.5),
          ),
          AppSpacing.sm.h,

          // ── Chart Content Body (Fixed-height expanded) ────────────────────
          Expanded(
            child: widget.isLoading
                ? _buildLoadingState(context)
                : ValueListenableBuilder<bool>(
                    valueListenable: _isRefreshingNotifier,
                    builder: (context, isRefreshing, _) {
                      if (isRefreshing) {
                        return _buildLoadingState(context);
                      }
                      return ValueListenableBuilder<ChartDisplayType>(
                        valueListenable: _chartTypeNotifier,
                        builder: (context, currentType, _) {
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: KeyedSubtree(
                              key: ValueKey(currentType),
                              child: _buildCurrentChart(currentType),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final displayTitle = widget.heading ?? widget.chartData.title;

    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleSmall?.bold().colour(
            context.colors.onSurface,
          ),
        ),
        // if (displaySubtitle != null) ...[
        //   const SizedBox(height: 2),
        //   Text(
        //     displaySubtitle,
        //     maxLines: 1,
        //     overflow: TextOverflow.ellipsis,
        //     style: context.textTheme.bodySmall
        //         ?.regular()
        //         .colour(context.colors.onSurfaceSecondary)
        //         .size(11),
        //   ),
        // ],
      ],
    );

    final chartSwitcher = widget.showSwitcher
        ? ValueListenableBuilder<ChartDisplayType>(
            valueListenable: _chartTypeNotifier,
            builder: (context, currentType, _) {
              return DashboardChartSwitcher(
                currentType: currentType,
                allowedTypes: widget.allowedChartTypes,
                onTypeChanged: (type) => _chartTypeNotifier.value = type,
              );
            },
          )
        : const SizedBox.shrink();

    final filterAndActionControls = Wrap(
      spacing: AppSpacing.xs + 2,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        // Custom filters (e.g. status dropdown, role dropdown, etc.)
        if (widget.filters != null) ...widget.filters!,

        // Date Filter & Refresh Unified Capsule
        if (widget.showDateFilter)
          ValueListenableBuilder<DateFilterOption>(
            valueListenable: _dateFilterNotifier,
            builder: (context, selectedOption, _) {
              return ValueListenableBuilder<DateTimeRange?>(
                valueListenable: _customRangeNotifier,
                builder: (context, customRange, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _isRefreshingNotifier,
                    builder: (context, isRefreshing, _) {
                      return DashboardDateFilterPicker(
                        selectedOption: selectedOption,
                        customRange: customRange,
                        onFilterChanged: _onDateFilterChanged,
                        onRefresh: widget.onRefresh != null
                            ? _handleRefresh
                            : null,
                        isRefreshing: isRefreshing,
                      );
                    },
                  );
                },
              );
            },
          ),

        // Custom actions if provided
        if (widget.actions != null) ...widget.actions!,
      ],
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              titleSection,
              if (widget.showSwitcher) ...[AppSpacing.xs.h, chartSwitcher],
            ],
          ),
        ),
        AppSpacing.sm.w,
        Flexible(child: filterAndActionControls),
      ],
    );
  }

  Widget _buildCurrentChart(ChartDisplayType type) {
    switch (type) {
      case ChartDisplayType.ring:
        return DashboardDonutChartView(
          chartData: widget.chartData,
          isRing: true,
        );
      case ChartDisplayType.pie:
        return DashboardDonutChartView(
          chartData: widget.chartData,
          isRing: false,
        );
      case ChartDisplayType.bar:
        return DashboardBarChartView(chartData: widget.chartData);
      case ChartDisplayType.card:
        return DashboardKpiCardView(chartData: widget.chartData);
    }
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AppSpacing.lg,
            height: AppSpacing.lg,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colors.primary,
            ),
          ),
          AppSpacing.sm.h,
          Text(
            'Loading...',
            style: context.textTheme.bodySmall?.medium().colour(
              context.colors.onSurfaceSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
