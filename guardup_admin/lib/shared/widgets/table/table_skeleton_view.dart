import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '/core/constants/app_layout.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import 'table_models.dart';
import 'table_parts.dart';

/// Structural loading state for [AdminTableBuilder].
///
/// Mirrors the real table: the actual column headers and widths, an
/// indeterminate progress line under the header, and per-column shimmer
/// placeholders chosen by [TableColumn.skeleton]. Narrow widths render
/// skeleton cards instead.
class TableSkeletonView<T> extends StatelessWidget {
  const TableSkeletonView({
    super.key,
    required this.columns,
    this.showCheckbox = false,
    this.colWidth = AppLayout.tableMinFlexColumnWidth,
    this.rowCount = 7,
    this.striped = true,
    this.rowHeight = AppLayout.tableRowHeight,
    this.hCtrl,
    this.vCtrl,
  });

  final List<TableColumn<T>> columns;
  final bool showCheckbox;

  /// Width of one flex unit.
  final double colWidth;
  final int rowCount;
  final bool striped;
  final double rowHeight;
  final ScrollController? hCtrl;
  final ScrollController? vCtrl;

  static const double _textBoneHeight = AppSpacing.md;
  static const double _badgeBoneHeight = AppSpacing.xl;
  static const double _badgeBoneWidth = AppSpacing.xxxl * 2;
  static const double _actionBoneSize =
      AppLayout.controlHeightSm - AppSpacing.xs;

  /// Text-bar widths as a fraction of the cell, varied per row/column so the
  /// placeholder reads like real content instead of a grid of equal bars.
  static const List<double> _textFactors = [
    0.68, 0.46, 0.82, 0.54, 0.72, 0.38, 0.88, 0.60, //
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppLayout.tableCardBreakpoint) {
          return _buildCards(context);
        }
        return _buildTable(context, constraints);
      },
    );
  }

  Widget _shimmer(BuildContext context, {required Widget child}) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.borderLight.withValues(alpha: 0.55),
      highlightColor: colors.isDark
          ? colors.onSurface.withValues(alpha: 0.12)
          : colors.surface,
      child: child,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Table skeleton
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTable(BuildContext context, BoxConstraints constraints) {
    final colors = context.colors;
    var contentWidth = showCheckbox ? AppLayout.tableCheckboxColumnWidth : 0.0;
    for (final column in columns) {
      contentWidth += column.resolveWidth(colWidth);
    }
    final tableWidth = max(constraints.maxWidth, contentWidth);

    return SingleChildScrollView(
      controller: hCtrl,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: SizedBox(
        width: tableWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: AppLayout.tableHeaderHeight,
              color: colors.surfaceMuted,
              child: Row(
                children: [
                  if (showCheckbox)
                    const SizedBox(
                      width: AppLayout.tableCheckboxColumnWidth,
                      child: Center(child: TableCheckbox(value: false)),
                    ),
                  for (final column in columns)
                    Container(
                      width: column.resolveWidth(colWidth),
                      alignment: column.alignment,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: TableHeaderLabel<T>(column: column),
                    ),
                ],
              ),
            ),
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: colors.borderLight,
              color: colors.primary,
            ),
            Expanded(
              child: ListView.builder(
                controller: vCtrl,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rowCount,
                itemBuilder: (context, index) => _buildRow(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, int rowIndex) {
    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        color: tableRowColor(context, rowIndex: rowIndex, striped: striped),
        border: Border(bottom: tableRowDivider(context)),
      ),
      child: _shimmer(
        context,
        child: Row(
          children: [
            if (showCheckbox)
              const SizedBox(
                width: AppLayout.tableCheckboxColumnWidth,
                child: Center(
                  child: _Bone(
                    width: AppLayout.iconSm,
                    height: AppLayout.iconSm,
                  ),
                ),
              ),
            for (final (columnIndex, column) in columns.indexed)
              Container(
                width: column.resolveWidth(colWidth),
                alignment: column.alignment,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _placeholder(column, rowIndex, columnIndex),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(TableColumn<T> column, int rowIndex, int columnIndex) {
    final kind = column.resolveSkeleton(
      isLast: columnIndex == columns.length - 1,
    );

    switch (kind) {
      case TableCellSkeleton.none:
        return const _Bone(width: AppSpacing.lg, height: _textBoneHeight);
      case TableCellSkeleton.badge:
        return _Bone(
          width: _badgeBoneWidth,
          height: _badgeBoneHeight,
          borderRadius: AppRadius.fullRadius,
        );
      case TableCellSkeleton.actions:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Bone(
              width: _actionBoneSize,
              height: _actionBoneSize,
              borderRadius: AppRadius.smRadius,
            ),
            AppSpacing.sm.w,
            _Bone(
              width: _actionBoneSize,
              height: _actionBoneSize,
              borderRadius: AppRadius.smRadius,
            ),
          ],
        );
      case TableCellSkeleton.text:
        final cellWidth = column.resolveWidth(colWidth) - AppSpacing.md * 2;
        final factor =
            _textFactors[(rowIndex * 3 + columnIndex * 5) %
                _textFactors.length];
        final width = (cellWidth * factor)
            .clamp(AppSpacing.xxxl, max(AppSpacing.xxxl, cellWidth))
            .toDouble();
        return _Bone(width: width, height: _textBoneHeight);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Card skeleton
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCards(BuildContext context) {
    final colors = context.colors;

    Widget line(double labelWidth, double valueWidth) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _Bone(width: labelWidth, height: AppSpacing.sm + 2),
        _Bone(width: valueWidth, height: _textBoneHeight),
      ],
    );

    return ListView.separated(
      controller: vCtrl,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: min(rowCount, 5),
      padding: AppSpacing.md.allPadding,
      separatorBuilder: (_, _) => AppSpacing.md.h,
      itemBuilder: (context, index) => Container(
        padding: AppSpacing.lg.allPadding,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: colors.borderLight),
        ),
        child: _shimmer(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _Bone(
                    width: AppSpacing.xxxl * 4,
                    height: AppSpacing.lg,
                  ),
                  _Bone(
                    width: _badgeBoneWidth,
                    height: _badgeBoneHeight,
                    borderRadius: AppRadius.fullRadius,
                  ),
                ],
              ),
              AppSpacing.md.h,
              Divider(height: 1, color: colors.borderExtraLight),
              AppSpacing.md.h,
              line(AppSpacing.xxxl * 2, AppSpacing.xxxl * 4),
              AppSpacing.sm.h,
              line(AppSpacing.xxxl * 2 + AppSpacing.lg, AppSpacing.xxxl * 3),
            ],
          ),
        ),
      ),
    );
  }
}

/// A placeholder block painted by [Shimmer].
class _Bone extends StatelessWidget {
  const _Bone({required this.width, required this.height, this.borderRadius});

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: borderRadius ?? AppRadius.xsRadius,
      ),
    );
  }
}
