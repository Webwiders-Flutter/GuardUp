import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '/core/constants/app_layout.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import 'table_models.dart';
import 'table_parts.dart';

/// Desktop table for [AdminTableBuilder].
///
/// - Standard mode: a 2D-virtualized [TableView] with a pinned header row and
///   pinned leading column, so wide tables scroll in both axes and only
///   visible cells are built.
/// - Reorder mode (when [onReorder] is set): a [ReorderableListView] with a
///   drag handle column, scrolling horizontally when the columns don't fit.
///
/// Row hover is tracked in a single [ValueNotifier]; only the cells of the
/// rows entering/leaving hover repaint.
class TableDesktopView<T> extends StatefulWidget {
  final List<TableColumn<T>> columns;
  final List<T> tableData;
  final List<Widget> Function(T) rows;
  final ScrollController hCtrl;
  final ScrollController vCtrl;

  /// Width of one flex unit.
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
    this.rowHeight = AppLayout.tableRowHeight,
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

  Object _keyOf(T item) => widget.itemKey?.call(item) ?? item as Object;

  bool _isSelected(T item) => widget.selectedItems.contains(_keyOf(item));

  void _onRowEnter(int rowIndex) {
    if (widget.enableHover) _hoveredRowNotifier.value = rowIndex;
  }

  void _onRowExit(int rowIndex) {
    // Only clear if no other row has claimed hover in the meantime.
    if (_hoveredRowNotifier.value == rowIndex) _hoveredRowNotifier.value = null;
  }

  Widget _headerCheckbox() => TableCheckbox(
    value: tableSelectAllValue(widget.tableData, widget.selectedItems, _keyOf),
    onChanged: (value) => widget.onSelectAll?.call(value, widget.tableData),
  );

  @override
  Widget build(BuildContext context) {
    return widget.onReorder != null
        ? _buildReorderable(context)
        : _buildVirtualized(context);
  }

  Widget _scrollbars({required Widget child}) {
    return Scrollbar(
      controller: widget.vCtrl,
      thumbVisibility: true,
      notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
      child: Scrollbar(
        controller: widget.hCtrl,
        thumbVisibility: true,
        notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
        child: child,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Virtualized mode
  // ═══════════════════════════════════════════════════════════════════════════

  int get _leadingColumns => widget.showCheckbox ? 1 : 0;

  Widget _buildVirtualized(BuildContext context) {
    final dataRows = widget.tableData.length;
    // Header + data + bottom breathing room.
    final rowCount = dataRows + 2;

    return _scrollbars(
      child: TableView.builder(
        columnCount: widget.columns.length + _leadingColumns,
        rowCount: rowCount,
        pinnedRowCount: 1,
        pinnedColumnCount: _leadingColumns + (widget.columns.isEmpty ? 0 : 1),
        horizontalDetails: ScrollableDetails.horizontal(
          controller: widget.hCtrl,
        ),
        verticalDetails: ScrollableDetails.vertical(controller: widget.vCtrl),
        columnBuilder: _columnSpan,
        rowBuilder: (index) => _rowSpan(index, rowCount),
        cellBuilder: _buildCell,
      ),
    );
  }

  TableSpan _columnSpan(int index) {
    if (index < _leadingColumns) {
      return const TableSpan(
        extent: FixedTableSpanExtent(AppLayout.tableCheckboxColumnWidth),
      );
    }
    final column = widget.columns[index - _leadingColumns];
    return TableSpan(
      extent: FixedTableSpanExtent(column.resolveWidth(widget.colWidth)),
    );
  }

  TableSpan _rowSpan(int index, int rowCount) {
    if (index == 0) {
      return const TableSpan(
        extent: FixedTableSpanExtent(AppLayout.tableHeaderHeight),
      );
    }
    if (index == rowCount - 1) {
      return const TableSpan(extent: FixedTableSpanExtent(AppSpacing.lg));
    }

    final rowIndex = index - 1;
    final onRowTap = widget.onRowTap;

    return TableSpan(
      extent: FixedTableSpanExtent(widget.rowHeight),
      onEnter: (_) => _onRowEnter(rowIndex),
      onExit: (_) => _onRowExit(rowIndex),
      cursor: onRowTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      // Cell-level buttons are hit-tested first, so they keep winning the
      // tap arena over this row-level recognizer.
      recognizerFactories: onRowTap == null
          ? const <Type, GestureRecognizerFactory>{}
          : <Type, GestureRecognizerFactory>{
              TapGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                    TapGestureRecognizer.new,
                    (recognizer) =>
                        recognizer.onTap = () =>
                            onRowTap(widget.tableData[rowIndex]),
                  ),
            },
    );
  }

  TableViewCell _buildCell(BuildContext context, TableVicinity vicinity) {
    final rowIndex = vicinity.row - 1;
    final isCheckboxColumn = vicinity.column < _leadingColumns;

    if (vicinity.row == 0) {
      if (isCheckboxColumn) {
        return TableViewCell(
          child: _HeaderCell(
            alignment: Alignment.center,
            child: _headerCheckbox(),
          ),
        );
      }
      final column = widget.columns[vicinity.column - _leadingColumns];
      return TableViewCell(
        child: _HeaderCell(
          alignment: column.alignment,
          child: TableHeaderLabel<T>(
            column: column,
            sortState: widget.sortState,
            onSort: widget.onSort,
          ),
        ),
      );
    }

    if (rowIndex >= widget.tableData.length) {
      return const TableViewCell(child: SizedBox.shrink());
    }

    final item = widget.tableData[rowIndex];
    final isSelected = _isSelected(item);

    if (isCheckboxColumn) {
      return TableViewCell(
        child: _RowCell(
          rowIndex: rowIndex,
          hoveredRowNotifier: widget.enableHover ? _hoveredRowNotifier : null,
          isSelected: isSelected,
          striped: widget.striped,
          alignment: Alignment.center,
          child: TableCheckbox(
            value: isSelected,
            onChanged: (value) => widget.onSelectRow?.call(item, value),
          ),
        ),
      );
    }

    final columnIndex = vicinity.column - _leadingColumns;
    final column = widget.columns[columnIndex];

    return TableViewCell(
      child: _RowCell(
        rowIndex: rowIndex,
        hoveredRowNotifier: widget.enableHover ? _hoveredRowNotifier : null,
        isSelected: isSelected,
        striped: widget.striped,
        alignment: column.alignment,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: column.buildCell(
          item,
          rowIndex,
          columnIndex,
          () => widget.rows(item),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Reorder mode
  // ═══════════════════════════════════════════════════════════════════════════

  double get _reorderMinWidth {
    var width = AppLayout.tableDragHandleWidth;
    if (widget.showCheckbox) width += AppLayout.tableCheckboxColumnWidth;
    for (final column in widget.columns) {
      width += column.width ?? AppLayout.tableMinFlexColumnWidth * column.flex;
    }
    return width;
  }

  /// Leading fixed slots + every column (fixed width or flex share).
  List<Widget> _reorderCells({
    required Widget handle,
    required Widget? checkbox,
    required Widget Function(TableColumn<T> column, int index) cell,
  }) {
    return [
      SizedBox(
        width: AppLayout.tableDragHandleWidth,
        child: Center(child: handle),
      ),
      if (checkbox != null)
        SizedBox(
          width: AppLayout.tableCheckboxColumnWidth,
          child: Center(child: checkbox),
        ),
      for (final (index, column) in widget.columns.indexed)
        if (column.width != null)
          SizedBox(width: column.width, child: cell(column, index))
        else
          Expanded(flex: column.flex, child: cell(column, index)),
    ];
  }

  Widget _buildReorderable(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(constraints.maxWidth, _reorderMinWidth);

        final table = SizedBox(
          width: tableWidth,
          child: Column(
            children: [
              _buildReorderHeader(context),
              Expanded(
                child: ReorderableListView.builder(
                  scrollController: widget.vCtrl,
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  itemCount: widget.tableData.length,
                  proxyDecorator: (child, _, animation) =>
                      _DragProxy(animation: animation, child: child),
                  onReorderItem: (oldIndex, newIndex) =>
                      widget.onReorder!(oldIndex, newIndex),
                  itemBuilder: (context, index) =>
                      _buildReorderRow(context, index),
                ),
              ),
            ],
          ),
        );

        if (tableWidth <= constraints.maxWidth) {
          return Scrollbar(
            controller: widget.vCtrl,
            thumbVisibility: true,
            child: table,
          );
        }

        return _scrollbars(
          child: SingleChildScrollView(
            controller: widget.hCtrl,
            scrollDirection: Axis.horizontal,
            child: table,
          ),
        );
      },
    );
  }

  Widget _buildReorderHeader(BuildContext context) {
    return Container(
      height: AppLayout.tableHeaderHeight,
      decoration: BoxDecoration(
        color: context.colors.surfaceMuted,
        border: Border(bottom: tableHeaderDivider(context)),
      ),
      child: Row(
        children: _reorderCells(
          handle: Icon(
            Icons.swap_vert_rounded,
            size: AppLayout.iconMd,
            color: context.colors.onSurfaceSecondary,
          ),
          checkbox: widget.showCheckbox ? _headerCheckbox() : null,
          cell: (column, _) => Container(
            alignment: column.alignment,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TableHeaderLabel<T>(
              column: column,
              sortState: widget.sortState,
              onSort: widget.onSort,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReorderRow(BuildContext context, int index) {
    final item = widget.tableData[index];
    final isSelected = _isSelected(item);
    final onRowTap = widget.onRowTap;

    final cells = Row(
      children: _reorderCells(
        handle: ReorderableDragStartListener(
          index: index,
          enabled: !widget.isSaving,
          child: SizedBox(
            width: AppLayout.tableDragHandleWidth,
            height: widget.rowHeight,
            child: Center(child: TableDragHandle(isSaving: widget.isSaving)),
          ),
        ),
        checkbox: widget.showCheckbox
            ? TableCheckbox(
                value: isSelected,
                onChanged: (value) => widget.onSelectRow?.call(item, value),
              )
            : null,
        cell: (column, columnIndex) => Container(
          alignment: column.alignment,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: column.buildCell(
            item,
            index,
            columnIndex,
            () => widget.rows(item),
          ),
        ),
      ),
    );

    return MouseRegion(
      key: ValueKey(_keyOf(item)),
      cursor: onRowTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => _onRowEnter(index),
      onExit: (_) => _onRowExit(index),
      child: GestureDetector(
        onTap: onRowTap != null ? () => onRowTap(item) : null,
        child: _RowCell(
          rowIndex: index,
          hoveredRowNotifier: widget.enableHover ? _hoveredRowNotifier : null,
          isSelected: isSelected,
          striped: widget.striped,
          height: widget.rowHeight,
          child: cells,
        ),
      ),
    );
  }
}

// ─── Cells ───────────────────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.alignment, required this.child});

  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceMuted,
        border: Border(bottom: tableHeaderDivider(context)),
      ),
      child: child,
    );
  }
}

/// A data cell (or whole reorderable row) painted with the row's state
/// color. Rebuilds only its decoration when hover changes; [child] is kept.
class _RowCell extends StatelessWidget {
  const _RowCell({
    required this.rowIndex,
    required this.hoveredRowNotifier,
    required this.isSelected,
    required this.striped,
    required this.child,
    this.alignment,
    this.padding,
    this.height,
  });

  final int rowIndex;

  /// Null when hover highlighting is disabled.
  final ValueNotifier<int?>? hoveredRowNotifier;
  final bool isSelected;
  final bool striped;
  final Alignment? alignment;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final Widget child;

  Widget _paint(BuildContext context, {required bool isHovered}) {
    return Container(
      height: height,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: tableRowColor(
          context,
          rowIndex: rowIndex,
          isSelected: isSelected,
          isHovered: isHovered,
          striped: striped,
        ),
        border: Border(bottom: tableRowDivider(context)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = hoveredRowNotifier;
    if (notifier == null) return _paint(context, isHovered: false);

    return ValueListenableBuilder<int?>(
      valueListenable: notifier,
      builder: (context, hoveredRow, _) =>
          _paint(context, isHovered: hoveredRow == rowIndex),
    );
  }
}

/// Lifted appearance of a row while it is being dragged.
class _DragProxy extends StatelessWidget {
  const _DragProxy({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeOut.transform(animation.value);
        return Material(
          elevation: t * AppSpacing.sm,
          color: context.colors.surface,
          shadowColor: context.colors.black.withValues(alpha: 0.25),
          borderRadius: AppRadius.smRadius,
          child: child,
        );
      },
      child: child,
    );
  }
}
