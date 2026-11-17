import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '../models/dashboard_stats_models.dart';
import '../painters/dashboard_chart_painters.dart';

/// Interactive Donut / Pie chart visualization with bidirectional hover
/// synchronization between chart slices and the legend list.
class DashboardDonutChartView extends StatefulWidget {
  final DashboardChartData chartData;
  final bool isRing;
  final double chartSize;
  final double strokeWidth;

  const DashboardDonutChartView({
    super.key,
    required this.chartData,
    this.isRing = true,
    this.chartSize = 150,
    this.strokeWidth = 18,
  });

  @override
  State<DashboardDonutChartView> createState() =>
      _DashboardDonutChartViewState();
}

class _DashboardDonutChartViewState extends State<DashboardDonutChartView> {
  final ValueNotifier<int?> _hoveredIndexNotifier = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _hoveredIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chartData.isEmpty) {
      return _buildEmptyState(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        if (isCompact) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildChartCanvas(context),
                AppSpacing.md.h,
                _buildLegendList(context),
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildChartCanvas(context),
            AppSpacing.lg.w,
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildLegendList(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            size: AppSpacing.xxxl,
            color: context.colors.onSurfaceSecondary.withValues(alpha: 0.35),
          ),
          AppSpacing.sm.h,
          Text(
            'No data recorded for this period',
            style: context.textTheme.bodySmall?.medium().colour(
              context.colors.onSurfaceSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCanvas(BuildContext context) {
    final trackColor = context.colors.borderLight.withValues(alpha: 0.5);

    return Center(
      child: SizedBox(
        width: widget.chartSize,
        height: widget.chartSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, animValue, _) {
                return ValueListenableBuilder<int?>(
                  valueListenable: _hoveredIndexNotifier,
                  builder: (context, hoveredIndex, _) {
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onHover: (event) {
                        final size = Size(widget.chartSize, widget.chartSize);
                        final hit = widget.isRing
                            ? ChartArcHitTester.hitTestDonut(
                                localPosition: event.localPosition,
                                size: size,
                                items: widget.chartData.items,
                                total: widget.chartData.total,
                                strokeWidth: widget.strokeWidth,
                              )
                            : ChartArcHitTester.hitTestPie(
                                localPosition: event.localPosition,
                                size: size,
                                items: widget.chartData.items,
                                total: widget.chartData.total,
                              );
                        if (_hoveredIndexNotifier.value != hit) {
                          _hoveredIndexNotifier.value = hit;
                        }
                      },
                      onExit: (_) => _hoveredIndexNotifier.value = null,
                      child: CustomPaint(
                        size: Size(widget.chartSize, widget.chartSize),
                        painter: widget.isRing
                            ? DashboardDonutPainter(
                                items: widget.chartData.items,
                                total: widget.chartData.total,
                                animationProgress: animValue,
                                hoveredIndex: hoveredIndex,
                                strokeWidth: widget.strokeWidth,
                                colorResolver: (idx) =>
                                    widget.chartData.colorFor(idx, context),
                                trackColor: trackColor,
                              )
                            : DashboardPiePainter(
                                items: widget.chartData.items,
                                total: widget.chartData.total,
                                animationProgress: animValue,
                                hoveredIndex: hoveredIndex,
                                colorResolver: (idx) =>
                                    widget.chartData.colorFor(idx, context),
                                trackColor: trackColor,
                              ),
                      ),
                    );
                  },
                );
              },
            ),

            // Dynamic Center Label (Ring mode only)
            if (widget.isRing)
              ValueListenableBuilder<int?>(
                valueListenable: _hoveredIndexNotifier,
                builder: (context, hoveredIndex, _) {
                  if (hoveredIndex != null &&
                      hoveredIndex >= 0 &&
                      hoveredIndex < widget.chartData.items.length) {
                    final item = widget.chartData.items[hoveredIndex];
                    final itemColor = widget.chartData.colorFor(
                      hoveredIndex,
                      context,
                    );

                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelSmall
                                ?.medium()
                                .colour(context.colors.onSurfaceSecondary)
                                .size(9),
                          ),
                          Text(
                            widget.chartData.formatValue(
                              item.value,
                              compact: true,
                            ),
                            style: context.textTheme.titleSmall?.bold().colour(
                              itemColor,
                            ),
                          ),
                          Text(
                            widget.chartData.formattedPercentage(item),
                            style: context.textTheme.labelSmall
                                ?.bold()
                                .colour(context.colors.onSurfaceSecondary)
                                .size(9),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TOTAL',
                          style: context.textTheme.labelSmall
                              ?.semiBold()
                              .colour(context.colors.onSurfaceSecondary)
                              .size(9),
                        ),
                        Text(
                          widget.chartData.formatValue(
                            widget.chartData.total,
                            compact: true,
                          ),
                          style: context.textTheme.titleMedium?.bold().colour(
                            context.colors.onSurface,
                          ),
                        ),
                        if (widget.chartData.unitSuffix != null)
                          Text(
                            widget.chartData.unitSuffix!.trim(),
                            style: context.textTheme.labelSmall
                                ?.medium()
                                .colour(context.colors.onSurfaceSecondary)
                                .size(9),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendList(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: _hoveredIndexNotifier,
      builder: (context, hoveredIndex, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(widget.chartData.items.length, (index) {
            final item = widget.chartData.items[index];
            final itemColor = widget.chartData.colorFor(index, context);
            final isHovered = hoveredIndex == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => _hoveredIndexNotifier.value = index,
                onExit: (_) {
                  if (_hoveredIndexNotifier.value == index) {
                    _hoveredIndexNotifier.value = null;
                  }
                },
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: AppRadius.mdRadius,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isHovered
                          ? itemColor.withValues(alpha: 0.08)
                          : context.colors.backgroundLight.withValues(
                              alpha: 0.5,
                            ),
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: isHovered
                            ? itemColor
                            : context.colors.borderLight,
                        width: isHovered ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Color Pill
                        Container(
                          width: AppSpacing.sm + 2,
                          height: AppSpacing.sm + 2,
                          decoration: BoxDecoration(
                            color: itemColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: itemColor.withValues(alpha: 0.35),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.sm.w,

                        // Item Title
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.medium().colour(
                              isHovered ? itemColor : context.colors.onSurface,
                            ),
                          ),
                        ),
                        AppSpacing.xs.w,

                        // Formatted Count
                        Text(
                          widget.chartData.formatValue(item.value),
                          style: context.textTheme.bodySmall?.semiBold().colour(
                            context.colors.onSurface,
                          ),
                        ),
                        AppSpacing.xs.w,

                        // Percentage Badge
                        QuickContainer(
                          px: 6,
                          py: 1,
                          radius: AppRadius.full,
                          color: itemColor.withValues(alpha: 0.12),
                          child: Text(
                            widget.chartData.formattedPercentage(item),
                            style: context.textTheme.labelSmall
                                ?.bold()
                                .colour(itemColor)
                                .size(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
