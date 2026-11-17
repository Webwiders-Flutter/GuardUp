import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '../models/dashboard_stats_models.dart';

/// Modern animated vertical bar / column chart visualization with wide rounded gradient pillars,
/// horizontal scrollability when items are abundant, hover feedback, and top-aligned value badges.
class DashboardBarChartView extends StatefulWidget {
  final DashboardChartData chartData;

  const DashboardBarChartView({super.key, required this.chartData});

  @override
  State<DashboardBarChartView> createState() => _DashboardBarChartViewState();
}

class _DashboardBarChartViewState extends State<DashboardBarChartView> {
  final ValueNotifier<int?> _hoveredBarNotifier = ValueNotifier<int?>(null);
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _hoveredBarNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemsCount = widget.chartData.items.length;
        // Generous minimum width per column to keep bars wide and readable
        const minColumnWidth = 88.0;
        final totalNeededWidth = itemsCount * minColumnWidth;
        final needsScroll = totalNeededWidth > constraints.maxWidth;

        return ValueListenableBuilder<int?>(
          valueListenable: _hoveredBarNotifier,
          builder: (context, hoveredIndex, _) {
            final barsRow = Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(itemsCount, (index) {
                final item = widget.chartData.items[index];
                final itemColor = widget.chartData.colorFor(index, context);
                final itemPercent = widget.chartData.percentageFor(item);
                final percentage = (itemPercent / 100.0).clamp(0.0, 1.0);
                final isHovered = hoveredIndex == index;

                final columnWidget = MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => _hoveredBarNotifier.value = index,
                  onExit: (_) {
                    if (_hoveredBarNotifier.value == index) {
                      _hoveredBarNotifier.value = null;
                    }
                  },
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: AppRadius.mdRadius,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? itemColor.withValues(alpha: 0.05)
                            : context.colors.transparent,
                        borderRadius: AppRadius.mdRadius,
                      ),
                      child: Column(
                        children: [
                          // 1. Top Value Badge / Percentage Pill
                          SizedBox(
                            height: 26,
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isHovered
                                      ? itemColor
                                      : itemColor.withValues(alpha: 0.12),
                                  borderRadius: AppRadius.fullRadius,
                                  border: Border.all(
                                    color: isHovered
                                        ? itemColor
                                        : itemColor.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  widget.chartData.formatValue(
                                    item.value,
                                    compact: true,
                                  ),
                                  style: context.textTheme.labelSmall
                                      ?.bold()
                                      .size(11)
                                      .colour(
                                        isHovered
                                            ? context.colors.onPrimary
                                            : itemColor,
                                      ),
                                ),
                              ),
                            ),
                          ),
                          AppSpacing.xs.h,

                          // 2. Vertical Bar Track & Wide Animated Filled Pillar
                          Expanded(
                            child: Center(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0.0,
                                  end: percentage,
                                ),
                                duration: const Duration(milliseconds: 650),
                                curve: Curves.easeOutCubic,
                                builder: (context, animPercent, _) {
                                  return LayoutBuilder(
                                    builder: (context, barAreaConstraints) {
                                      // Wide, substantial bar width
                                      final barWidth =
                                          (barAreaConstraints.maxWidth * 0.54)
                                              .clamp(34.0, 56.0);

                                      return Container(
                                        width: barWidth,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          color: context.colors.borderLight
                                              .withValues(alpha: 0.35),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(
                                                  AppRadius.sm + 2,
                                                ),
                                              ),
                                        ),
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: FractionallySizedBox(
                                            heightFactor: animPercent.clamp(
                                              0.0,
                                              1.0,
                                            ),
                                            widthFactor: 1.0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(
                                                        AppRadius.sm + 2,
                                                      ),
                                                    ),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    itemColor,
                                                    itemColor.withValues(
                                                      alpha: 0.72,
                                                    ),
                                                  ],
                                                ),
                                                boxShadow: isHovered
                                                    ? [
                                                        BoxShadow(
                                                          color: itemColor
                                                              .withValues(
                                                                alpha: 0.45,
                                                              ),
                                                          blurRadius: 10,
                                                          offset: const Offset(
                                                            0,
                                                            -3,
                                                          ),
                                                        ),
                                                      ]
                                                    : [
                                                        BoxShadow(
                                                          color: itemColor
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                            0,
                                                            -1,
                                                          ),
                                                        ),
                                                      ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          AppSpacing.xs.h,

                          // 3. Bottom Label & Icon Section
                          SizedBox(
                            height: 46,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (item.icon != null) ...[
                                  Icon(
                                    item.icon,
                                    size: AppSpacing.md + 2,
                                    color: isHovered
                                        ? itemColor
                                        : context.colors.onSurfaceSecondary,
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.labelSmall
                                      ?.semiBold()
                                      .size(11)
                                      .colour(
                                        isHovered
                                            ? itemColor
                                            : context.colors.onSurface,
                                      ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  widget.chartData.formattedPercentage(item),
                                  style: context.textTheme.labelSmall
                                      ?.size(10)
                                      .colour(
                                        context.colors.onSurfaceSecondary
                                            .withValues(alpha: 0.8),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                if (needsScroll) {
                  return SizedBox(width: minColumnWidth, child: columnWidget);
                }

                return Expanded(child: columnWidget);
              }),
            );

            if (needsScroll) {
              return Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: totalNeededWidth,
                    height: constraints.maxHeight,
                    child: barsRow,
                  ),
                ),
              );
            }

            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: barsRow,
            );
          },
        );
      },
    );
  }
}
