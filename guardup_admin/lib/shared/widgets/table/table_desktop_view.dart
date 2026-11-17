import 'package:guardup_admin/shared/widgets/table/table_models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';

/// Enterprise desktop table view with 2D virtualized spreadsheet scrolling,
/// interactive sorting, row hover effects, row click callbacks, selection highlights,
/// and optional drag-and-drop reordering.
class TableDesktopView<T> extends StatefulWidget {
  final List<TableColumn<T>> columns;
  final List<T> tableData;
  final List<Widget> Function(T) rows;
  final ScrollController hCtrl;
  final ScrollController vCtrl;
  final double actionColumnWidth;
  final double colWidth;
  final bool showCheckbox;
  final Set<Object> selectedItems;
  final Object Function(T item)? itemKey;
  final void Function(bool? value, List<T> items)? onSelectAll;
  final void Function(T item, bool? value)? onSelectRow;
  final void Function(T item)? onRowTap;
  final TableSortState? sortState;
  final void Function(String columnKey, bool ascending)? onSort;
  final Future<void> Function(int oldIndex, int newIndex)? onReorder;
  final bool isSaving;
  final bool striped;
  final bool enableHover;
  final double rowHeight;

  const TableDesktopView({
    super.key,
    required this.columns,
    required this.tableData,
    required this.rows,
    required this.hCtrl,
    required this.vCtrl,
    required this.actionColumnWidth,
    required this.colWidth,
    required this.showCheckbox,
    required this.selectedItems,
    this.itemKey,
    this.onSelectAll,
    this.onSelectRow,
    this.onRowTap,
    this.sortState,
    this.onSort,
    this.onReorder,
    this.isSaving = false,
    this.striped = true,
    this.enableHover = true,
    this.rowHeight = AppSpacing.xxxl + AppSpacing.xl,
  });

  @override
  State<TableDesktopView<T>> createState() => _TableDesktopViewState<T>();
}

class _TableDesktopViewState<T> extends State<TableDesktopView<T>> {
  final ValueNotifier<int?> _hoveredRowNotifier = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _hoveredRowNotifier.dispose();
    super.dispose();
  }

  bool get _isReorderable => widget.onReorder != null;

  static const double _handleWidth = AppSpacing.xxl + AppSpacing.xl;
  static const double _numberWidth = AppSpacing.xxxl + AppSpacing.xxl;
  static const double _checkWidth = AppSpacing.xxl + AppSpacing.xl + 2;
  static const double _spacing = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    if (_isReorderable) {
      return _buildReorderableTable(context);
    }
    return _build2DTableView(context);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2D TABLE VIEW (Standard Virtualized Mode)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _build2DTableView(BuildContext context) {
    final int totalColumns =
        widget.columns.length + (widget.showCheckbox ? 1 : 0);
    final borderColor = context.colors.borderLight.withValues(alpha: 0.5);
    final bool hasBottomSpacer = widget.tableData.isNotEmpty;
    final int totalRows =
        widget.tableData.length + 1 + (hasBottomSpacer ? 1 : 0);

    return Scrollbar(
      controller: widget.vCtrl,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: AppSpacing.sm,
      radius: const Radius.circular(AppRadius.sm),
      notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
      child: Scrollbar(
        controller: widget.hCtrl,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: AppSpacing.sm,
        radius: const Radius.circular(AppRadius.sm),
        notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
        child: TableView.builder(
          columnCount: totalColumns,
          rowCount: totalRows,
          pinnedRowCount: 1,
          pinnedColumnCount: widget.showCheckbox ? 2 : 1,
          horizontalDetails: ScrollableDetails.horizontal(
            controller: widget.hCtrl,
          ),
          verticalDetails: ScrollableDetails.vertical(controller: widget.vCtrl),
          columnBuilder: (i) => _buildColumnSpan(i),
          rowBuilder: (i) {
            if (i == 0) {
              return TableSpan(
                extent: FixedTableSpanExtent(AppSpacing.xxxl + AppSpacing.md),
                backgroundDecoration: TableSpanDecoration(
                  border: TableSpanBorder(
                    trailing: BorderSide(color: borderColor),
                  ),
                ),
              );
            }
            if (hasBottomSpacer && i == totalRows - 1) {
              return const TableSpan(
                extent: FixedTableSpanExtent(AppSpacing.lg),
              );
            }
            return TableSpan(
              extent: FixedTableSpanExtent(widget.rowHeight),
              backgroundDecoration: TableSpanDecoration(
                border: TableSpanBorder(
                  trailing: BorderSide(color: borderColor),
                ),
              ),
            );
          },
          cellBuilder: (ctx, vicinity) => _buildCell(ctx, vicinity),
        ),
      ),
    );
  }

  TableSpan _buildColumnSpan(int i) {
    if (widget.showCheckbox && i == 0) {
      return const TableSpan(extent: FixedTableSpanExtent(_checkWidth));
    }
    final int adjIdx = widget.showCheckbox ? i - 1 : i;

    // If the column definition has an explicit width, always respect it.
    if (adjIdx >= 0 && adjIdx < widget.columns.length) {
      final col = widget.columns[adjIdx];
      if (col.width != null) {
        return TableSpan(extent: FixedTableSpanExtent(col.width!));
      }
      // Flex columns scale with their flex factor relative to 1 flex unit.
      return TableSpan(
        extent: FixedTableSpanExtent(widget.colWidth * col.flex),
      );
    }

    return TableSpan(extent: FixedTableSpanExtent(widget.colWidth));
  }

  TableViewCell _buildCell(BuildContext context, TableVicinity vicinity) {
    final bool isHeader = vicinity.yIndex == 0;
    final bool isSpacerRow =
        widget.tableData.isNotEmpty &&
        vicinity.yIndex > widget.tableData.length;

    if (isSpacerRow) {
      return const TableViewCell(child: SizedBox.shrink());
    }

    // Checkbox column
    if (widget.showCheckbox && vicinity.xIndex == 0) {
      if (isHeader) {
        return _headerCellWidget(
          context: context,
          child: CupertinoCheckbox(
            value:
                widget.tableData.isNotEmpty &&
                widget.tableData.every(
                  (item) => widget.selectedItems.contains(
                    widget.itemKey?.call(item) ?? item,
                  ),
                ),
            activeColor: context.colors.secondary,
            onChanged: (val) => widget.onSelectAll?.call(val, widget.tableData),
          ),
        );
      }

      final rowIndex = vicinity.yIndex - 1;
      final item = widget.tableData[rowIndex];
      final isSelected = widget.selectedItems.contains(
        widget.itemKey?.call(item) ?? item,
      );

      return TableViewCell(
        child: MouseRegion(
          onEnter: (_) {
            if (widget.enableHover) _hoveredRowNotifier.value = rowIndex;
          },
          onExit: (_) {
            if (widget.enableHover) _hoveredRowNotifier.value = null;
          },
          child: ValueListenableBuilder<int?>(
            valueListenable: _hoveredRowNotifier,
            builder: (context, hoveredRowIndex, _) {
              final isHovered =
                  widget.enableHover && hoveredRowIndex == rowIndex;
              final Color rowColor = _resolveRowColor(
                context,
                rowIndex,
                isSelected,
                isHovered,
              );
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rowColor,
                  border: Border(
                    bottom: BorderSide(
                      color: context.colors.borderLight.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: CupertinoCheckbox(
                  value: isSelected,
                  activeColor: context.colors.secondary,
                  onChanged: (val) => widget.onSelectRow?.call(item, val),
                ),
              );
            },
          ),
        ),
      );
    }

    final int adjX = widget.showCheckbox
        ? vicinity.xIndex - 1
        : vicinity.xIndex;
    final col = widget.columns[adjX];

    // Header cells
    if (isHeader) {
      return _buildHeaderCell(context, col);
    }

    // Data cells
    final rowIndex = vicinity.yIndex - 1;
    final item = widget.tableData[rowIndex];
    final cells = widget.rows(item);
    final isSelected = widget.selectedItems.contains(
      widget.itemKey?.call(item) ?? item,
    );

    final Widget cellContent = col.cellBuilder != null
        ? col.cellBuilder!(item, rowIndex)
        : (adjX < cells.length ? cells[adjX] : const SizedBox.shrink());

    return TableViewCell(
      child: MouseRegion(
        onEnter: (_) {
          if (widget.enableHover) _hoveredRowNotifier.value = rowIndex;
        },
        onExit: (_) {
          if (widget.enableHover) _hoveredRowNotifier.value = null;
        },
        child: GestureDetector(
          onTap: widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
          child: ValueListenableBuilder<int?>(
            valueListenable: _hoveredRowNotifier,
            builder: (context, hoveredRowIndex, _) {
              final isHovered =
                  widget.enableHover && hoveredRowIndex == rowIndex;
              final Color rowColor = _resolveRowColor(
                context,
                rowIndex,
                isSelected,
                isHovered,
              );
              return Container(
                decoration: BoxDecoration(
                  color: rowColor,
                  border: Border(
                    bottom: BorderSide(
                      color: context.colors.borderLight.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                alignment: col.alignment,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: cellContent,
              );
            },
          ),
        ),
      ),
    );
  }

  TableViewCell _buildHeaderCell(BuildContext context, TableColumn<T> col) {
    final sortKey = col.key ?? col.title;
    final isSorted = widget.sortState?.columnKey == sortKey;
    final isAscending = widget.sortState?.ascending ?? true;

    Widget headerContent =
        col.headerWidget ??
        Text(
          col.title.toUpperCase(),
          style: context.textTheme.labelMedium
              ?.colour(
                isSorted
                    ? context.colors.secondary
                    : context.colors.onSurfaceSecondary,
              )
              .size(AppSpacing.md - 0.5)
              .bold()
              .textSpacing(0.6),
        );

    if (col.sortable && widget.onSort != null) {
      headerContent = InkWell(
        onTap: () => widget.onSort!(sortKey, isSorted ? !isAscending : true),
        borderRadius: AppRadius.smRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs / 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: headerContent),
              AppSpacing.xs.w,
              Icon(
                isSorted
                    ? (isAscending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded)
                    : Icons.unfold_more_rounded,
                size: AppSpacing.md + 2,
                color: isSorted
                    ? context.colors.secondary
                    : context.colors.onSurfaceSecondary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      );
    }

    return _headerCellWidget(
      context: context,
      alignment: col.alignment,
      child: headerContent,
    );
  }

  TableViewCell _headerCellWidget({
    required BuildContext context,
    required Widget child,
    Alignment alignment = Alignment.center,
  }) {
    return TableViewCell(
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.backgroundLight,
          border: Border(
            bottom: BorderSide(
              color: context.colors.borderLight.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
        ),
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2),
        child: child,
      ),
    );
  }

  Color _resolveRowColor(
    BuildContext context,
    int index,
    bool isSelected,
    bool isHovered,
  ) {
    if (isSelected) {
      return context.colors.secondary.withValues(alpha: 0.08);
    }
    if (isHovered) {
      return context.colors.secondary.withValues(alpha: 0.04);
    }
    if (widget.striped) {
      return index % 2 == 0
          ? context.colors.surface
          : context.colors.backgroundLight.withValues(alpha: 0.5);
    }
    return context.colors.surface;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REORDERABLE TABLE VIEW (Drag & Drop Mode)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildReorderableTable(BuildContext context) {
    return Column(
      children: [
        _buildReorderableHeader(context),
        Divider(
          height: 1,
          color: context.colors.borderLight.withValues(alpha: 0.7),
        ),
        Expanded(
          child: ReorderableListView.builder(
            scrollController: widget.vCtrl,
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            itemCount: widget.tableData.length,
            onReorderItem: (oldIndex, newIndex) =>
                widget.onReorder!(oldIndex, newIndex),
            itemBuilder: (_, index) {
              final item = widget.tableData[index];
              final cells = widget.rows(item);
              final keyVal = widget.itemKey?.call(item) ?? index;
              return _buildReorderableRow(
                context: context,
                key: ValueKey(keyVal),
                index: index,
                item: item,
                cells: cells,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReorderableHeader(BuildContext context) {
    final int dataColCount = widget.columns.length - 2;

    return Container(
      color: context.colors.backgroundLight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          SizedBox(
            width: _handleWidth,
            child: Center(
              child: Tooltip(
                message: 'Drag to reorder',
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Icon(
                    Icons.swap_vert_rounded,
                    size: AppSpacing.lg + 2,
                    color: context.colors.onSurfaceSecondary,
                  ),
                ),
              ),
            ),
          ),
          if (widget.showCheckbox) ...[
            _spacing.w,
            SizedBox(
              width: _checkWidth,
              child: Center(
                child: CupertinoCheckbox(
                  value:
                      widget.tableData.isNotEmpty &&
                      widget.tableData.every(
                        (item) => widget.selectedItems.contains(
                          widget.itemKey?.call(item) ?? item,
                        ),
                      ),
                  activeColor: context.colors.secondary,
                  onChanged: (val) =>
                      widget.onSelectAll?.call(val, widget.tableData),
                ),
              ),
            ),
          ],
          _spacing.w,
          SizedBox(
            width: _numberWidth,
            child: Center(
              child: Text(
                'NO.',
                style: context.textTheme.labelMedium
                    ?.colour(context.colors.onSurfaceSecondary)
                    .size(AppSpacing.md)
                    .bold()
                    .textSpacing(0.5),
              ),
            ),
          ),
          _spacing.w,
          for (int i = 1; i <= dataColCount; i++)
            if (widget.columns[i].width != null)
              SizedBox(
                width: widget.columns[i].width!,
                child: Align(
                  alignment: widget.columns[i].alignment,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Text(
                      widget.columns[i].title.toUpperCase(),
                      style: context.textTheme.labelMedium
                          ?.colour(context.colors.onSurfaceSecondary)
                          .size(AppSpacing.md)
                          .bold()
                          .textSpacing(0.5),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                flex: widget.columns[i].flex,
                child: Align(
                  alignment: widget.columns[i].alignment,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Text(
                      widget.columns[i].title.toUpperCase(),
                      style: context.textTheme.labelMedium
                          ?.colour(context.colors.onSurfaceSecondary)
                          .size(AppSpacing.md)
                          .bold()
                          .textSpacing(0.5),
                    ),
                  ),
                ),
              ),
          SizedBox(
            width: widget.actionColumnWidth,
            child: Center(
              child: Text(
                widget.columns.last.title.toUpperCase(),
                style: context.textTheme.labelMedium
                    ?.colour(context.colors.onSurfaceSecondary)
                    .size(AppSpacing.md)
                    .bold()
                    .textSpacing(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableRow({
    required BuildContext context,
    required Key key,
    required int index,
    required T item,
    required List<Widget> cells,
  }) {
    final int dataColCount = widget.columns.length - 2;
    final isSelected = widget.selectedItems.contains(
      widget.itemKey?.call(item) ?? item,
    );
    return MouseRegion(
      key: key,
      onEnter: (_) {
        if (widget.enableHover) _hoveredRowNotifier.value = index;
      },
      onExit: (_) {
        if (widget.enableHover) _hoveredRowNotifier.value = null;
      },
      child: GestureDetector(
        onTap: widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
        child: ValueListenableBuilder<int?>(
          valueListenable: _hoveredRowNotifier,
          builder: (context, hoveredRowIndex, _) {
            final isHovered = widget.enableHover && hoveredRowIndex == index;
            final Color rowColor = _resolveRowColor(
              context,
              index,
              isSelected,
              isHovered,
            );
            return Container(
              color: rowColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: (AppSpacing.xs / 2),
                    ),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: SizedBox(
                            width: _handleWidth,
                            height: widget.rowHeight,
                            child: Center(child: _buildDragHandle(context)),
                          ),
                        ),
                        if (widget.showCheckbox) ...[
                          _spacing.w,
                          SizedBox(
                            width: _checkWidth,
                            child: Center(
                              child: CupertinoCheckbox(
                                value: isSelected,
                                activeColor: context.colors.secondary,
                                onChanged: (val) =>
                                    widget.onSelectRow?.call(item, val),
                              ),
                            ),
                          ),
                        ],
                        _spacing.w,
                        SizedBox(
                          width: _numberWidth,
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: context.textTheme.bodySmall
                                  ?.size(AppSpacing.md + 0.5)
                                  .medium()
                                  .colour(context.colors.onSurfaceSecondary),
                            ),
                          ),
                        ),
                        _spacing.w,
                        for (int i = 1; i <= dataColCount; i++)
                          if (widget.columns[i].width != null)
                            SizedBox(
                              width: widget.columns[i].width!,
                              child: Container(
                                height: widget.rowHeight,
                                alignment: widget.columns[i].alignment,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                child: widget.columns[i].cellBuilder != null
                                    ? widget.columns[i].cellBuilder!(
                                        item,
                                        index,
                                      )
                                    : (i < cells.length
                                          ? cells[i]
                                          : const SizedBox.shrink()),
                              ),
                            )
                          else
                            Expanded(
                              flex: widget.columns[i].flex,
                              child: Container(
                                height: widget.rowHeight,
                                alignment: widget.columns[i].alignment,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                child: widget.columns[i].cellBuilder != null
                                    ? widget.columns[i].cellBuilder!(
                                        item,
                                        index,
                                      )
                                    : (i < cells.length
                                          ? cells[i]
                                          : const SizedBox.shrink()),
                              ),
                            ),
                        SizedBox(
                          width: widget.actionColumnWidth,
                          height: widget.rowHeight,
                          child: Center(child: cells.last),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: context.colors.borderLight.withValues(alpha: 0.5),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    if (widget.isSaving) {
      return SizedBox(
        width: AppSpacing.lg,
        height: AppSpacing.lg,
        child: CircularProgressIndicator(strokeWidth: AppSpacing.xs / 2),
      );
    }
    return Tooltip(
      message: 'Drag to reorder',
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Icon(
          Icons.drag_indicator_rounded,
          size: AppSpacing.xl,
          color: context.colors.onSurfaceSecondary,
        ),
      ),
    );
  }
}
