import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '../models/dashboard_stats_models.dart';

/// Responsive card grid representing stats as high-contrast enterprise KPI cards.
class DashboardKpiCardView extends StatefulWidget {
  final DashboardChartData chartData;

  const DashboardKpiCardView({super.key, required this.chartData});

  @override
  State<DashboardKpiCardView> createState() => _DashboardKpiCardViewState();
}

class _DashboardKpiCardViewState extends State<DashboardKpiCardView> {
  final ValueNotifier<int?> _hoveredCardNotifier = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _hoveredCardNotifier.dispose();
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
              Icons.grid_view_rounded,
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
        final crossAxisCount = constraints.maxWidth >= 500
            ? 3
            : constraints.maxWidth >= 320
            ? 2
            : 1;

        return ValueListenableBuilder<int?>(
          valueListenable: _hoveredCardNotifier,
          builder: (context, hoveredIndex, _) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.chartData.items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: crossAxisCount == 1 ? 3.0 : 1.7,
                ),
                itemBuilder: (context, index) {
                  final item = widget.chartData.items[index];
                  final itemColor = widget.chartData.colorFor(index, context);
                  final isHovered = hoveredIndex == index;

                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => _hoveredCardNotifier.value = index,
                    onExit: (_) {
                      if (_hoveredCardNotifier.value == index) {
                        _hoveredCardNotifier.value = null;
                      }
                    },
                    child: InkWell(
                      onTap: item.onTap,
                      borderRadius: AppRadius.mdRadius,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: AppRadius.mdRadius,
                          border: Border.all(
                            color: isHovered
                                ? itemColor
                                : context.colors.borderLight,
                            width: isHovered ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isHovered
                                  ? itemColor.withValues(alpha: 0.1)
                                  : context.colors.black.withValues(
                                      alpha: 0.02,
                                    ),
                              blurRadius: isHovered ? 8 : 4,
                              offset: Offset(0, isHovered ? 2 : 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top row: Icon + % pill
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                QuickContainer(
                                  px: 6,
                                  py: 6,
                                  radius: AppRadius.sm,
                                  color: itemColor.withValues(alpha: 0.12),
                                  child: Icon(
                                    item.icon ?? Icons.analytics_outlined,
                                    size: AppSpacing.md + 2,
                                    color: itemColor,
                                  ),
                                ),
                                QuickContainer(
                                  px: 6,
                                  py: 1,
                                  radius: AppRadius.full,
                                  color: itemColor.withValues(alpha: 0.1),
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

                            // Bottom: Value & Title
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.chartData.formatValue(item.value),
                                  style: context.textTheme.titleMedium?.bold(),
                                ),
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.bodySmall
                                      ?.medium()
                                      .colour(context.colors.onSurfaceSecondary)
                                      .size(11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
