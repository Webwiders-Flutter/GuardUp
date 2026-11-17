import 'dart:math';

import 'package:guardup_admin/shared/widgets/table/table_models.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';

/// Enterprise skeleton table loading view designed for [AdminTableBuilder].
///
/// Replaces generic spinners with a polished, structural shimmer interface:
/// - Preserves readable table headers and exact column widths
/// - Animated indeterminate linear accent bar under the header
/// - High-performance shimmer rows with natural text length variations,
///   status badge capsules, and action button skeletons
/// - Adaptive responsive design supporting desktop tables and mobile cards
class TableSkeletonView<T> extends StatelessWidget {
  final List<TableColumn<T>> columns;
  final bool showCheckbox;
  final double colWidth;
  final double actionColumnWidth;
  final int rowCount;
  final bool striped;
  final ScrollController? hCtrl;
  final ScrollController? vCtrl;

  const TableSkeletonView({
    super.key,
    required this.columns,
    this.showCheckbox = false,
    this.colWidth = 160.0,
    this.actionColumnWidth = 100.0,
    this.rowCount = 7,
    this.striped = true,
    this.hCtrl,
    this.vCtrl,
    this.rowHeight = AppSpacing.xxxl + AppSpacing.xl,
  });

  static const double _checkWidth = AppSpacing.xxl + AppSpacing.xl + 2;
  static const double _headerHeight = AppSpacing.xxxl + AppSpacing.md; // 44.0
  final double rowHeight;

  double _resolveColWidth(TableColumn<T> col) {
    if (col.width != null) return col.width!;
    return colWidth * col.flex;
  }

  bool _isActionColumn(TableColumn<T> col, int index) {
    final title = col.title.trim().toLowerCase();
    return title == 'action' ||
        title == 'actions' ||
        (index == columns.length - 1 &&
            (col.width != null && col.width! <= 140));
  }

  bool _isBadgeColumn(TableColumn<T> col) {
    final title = col.title.trim().toLowerCase();
    return title.contains('status') ||
        title.contains('applies') ||
        title.contains('type') ||
        title.contains('role');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return _buildMobileSkeleton(context);
        }
        return _buildDesktopSkeleton(context, constraints);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESKTOP SKELETON (Column-aligned Shimmer Table)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktopSkeleton(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final colors = context.colors;

    // Calculate total required table width
    double totalColsWidth = showCheckbox ? _checkWidth : 0.0;
    for (final col in columns) {
      totalColsWidth += _resolveColWidth(col);
    }

    final double tableWidth = max(constraints.maxWidth, totalColsWidth);

    return Scrollbar(
      controller: vCtrl,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: AppSpacing.sm,
      radius: const Radius.circular(AppRadius.sm),
      child: Scrollbar(
        controller: hCtrl,
        thumbVisibility: true,
        trackVisibility: true,
        notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
        thickness: AppSpacing.sm,
        radius: const Radius.circular(AppRadius.sm),
        child: SingleChildScrollView(
          controller: hCtrl,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Structural Header
                _buildHeader(context, colors),

                // 2. Linear Live Sync Indicator Line
                LinearProgressIndicator(
                  minHeight: 2.0,
                  backgroundColor: colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.secondary),
                ),

                // 3. Shimmering Skeleton Data Rows
                Expanded(
                  child: ListView.builder(
                    controller: vCtrl,
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    itemCount: rowCount,
                    itemBuilder: (context, index) {
                      return _buildDesktopRow(context, colors, index);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic colors) {
    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        color: context.colors.backgroundLight.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: context.colors.borderLight.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showCheckbox)
            Container(
              width: _checkWidth,
              alignment: Alignment.center,
              child: Container(
                width: 16.0,
                height: 16.0,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.xsRadius,
                  border: Border.all(
                    color: context.colors.borderLight.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          for (int i = 0; i < columns.length; i++) ...[
            _buildHeaderCell(context, columns[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, TableColumn<T> col) {
    final colors = context.colors;
    final width = _resolveColWidth(col);

    return Container(
      width: width,
      height: _headerHeight,
      alignment: col.alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              col.title,
              style: context.textTheme.labelMedium?.bold().colour(
                colors.onSurfaceSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (col.sortable) ...[
            AppSpacing.xs.w,
            Icon(
              Icons.unfold_more_rounded,
              size: AppSpacing.md + 2,
              color: colors.onSurfaceSecondary.withValues(alpha: 0.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopRow(BuildContext context, dynamic colors, int rowIndex) {
    final isStripe = striped && rowIndex.isOdd;
    final rowBackground = isStripe
        ? context.colors.backgroundLight.withValues(alpha: 0.35)
        : context.colors.surface;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? colors.borderDark.withValues(alpha: 0.5)
        : context.colors.borderLight.withValues(alpha: 0.45);
    final highlightColor = isDark
        ? colors.borderLight.withValues(alpha: 0.3)
        : context.colors.surface.withValues(alpha: 0.85);

    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        color: rowBackground,
        border: Border(
          bottom: BorderSide(
            color: context.colors.borderLight.withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Row(
          children: [
            if (showCheckbox)
              Container(
                width: _checkWidth,
                alignment: Alignment.center,
                child: Container(
                  width: 16.0,
                  height: 16.0,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: AppRadius.xsRadius,
                  ),
                ),
              ),
            for (int colIdx = 0; colIdx < columns.length; colIdx++) ...[
              _buildCellSkeleton(context, columns[colIdx], rowIndex, colIdx),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCellSkeleton(
    BuildContext context,
    TableColumn<T> col,
    int rowIndex,
    int colIndex,
  ) {
    final width = _resolveColWidth(col);
    final isAction = _isActionColumn(col, colIndex);
    final isBadge = _isBadgeColumn(col);

    Widget placeholder;

    if (isAction) {
      placeholder = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28.0,
            height: 28.0,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: AppRadius.smRadius,
            ),
          ),
          AppSpacing.sm.w,
          Container(
            width: 28.0,
            height: 28.0,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: AppRadius.smRadius,
            ),
          ),
        ],
      );
    } else if (isBadge) {
      placeholder = Container(
        height: 22.0,
        width: 68.0,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.round),
        ),
      );
    } else {
      // Natural variation factors so text bars feel organic across rows
      const factors = [0.68, 0.46, 0.82, 0.54, 0.72, 0.38, 0.88, 0.60];
      final factor = factors[(rowIndex * 3 + colIndex * 5) % factors.length];
      final maxAvailable = max(40.0, width - (AppSpacing.md * 2));
      final barWidth = (maxAvailable * factor).clamp(32.0, maxAvailable);

      placeholder = Container(
        height: 13.0,
        width: barWidth,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: AppRadius.xsRadius,
        ),
      );
    }

    return Container(
      width: width,
      height: rowHeight,
      alignment: col.alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: placeholder,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE SKELETON (Card-based Shimmer List)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMobileSkeleton(BuildContext context) {
    final colors = context.colors;

    return ListView.separated(
      controller: vCtrl,
      itemCount: min(rowCount, 5),
      separatorBuilder: (_, _) => AppSpacing.md.h,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemBuilder: (ctx, index) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(
              color: colors.borderLight.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Shimmer.fromColors(
            baseColor: Theme.of(context).brightness == Brightness.dark
                ? colors.borderDark.withValues(alpha: 0.5)
                : colors.borderLight.withValues(alpha: 0.5),
            highlightColor: Theme.of(context).brightness == Brightness.dark
                ? colors.borderLight.withValues(alpha: 0.3)
                : colors.surface.withValues(alpha: 0.9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header line: Title + Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 16.0,
                      width: 140.0,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: AppRadius.xsRadius,
                      ),
                    ),
                    Container(
                      height: 22.0,
                      width: 64.0,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.round),
                      ),
                    ),
                  ],
                ),
                AppSpacing.md.h,
                Divider(
                  height: 1,
                  color: colors.borderLight.withValues(alpha: 0.4),
                ),
                AppSpacing.md.h,

                // Content fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 11.0,
                      width: 55.0,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: AppRadius.xsRadius,
                      ),
                    ),
                    Container(
                      height: 13.0,
                      width: 120.0,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: AppRadius.xsRadius,
                      ),
                    ),
                  ],
                ),
                AppSpacing.sm.h,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 11.0,
                      width: 70.0,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: AppRadius.xsRadius,
                      ),
                    ),
                    Container(
                      height: 13.0,
                      width: 90.0,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: AppRadius.xsRadius,
                      ),
                    ),
                  ],
                ),
                AppSpacing.md.h,

                // Actions row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 28.0,
                      height: 28.0,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: AppRadius.smRadius,
                      ),
                    ),
                    AppSpacing.sm.w,
                    Container(
                      width: 28.0,
                      height: 28.0,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: AppRadius.smRadius,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
