import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import 'table_models.dart';
import 'table_parts.dart';

/// Card layout for [AdminTableBuilder] on narrow widths.
///
/// Column roles: the first column is the card's lead (e.g. index or name),
/// the last column is the trailing slot (usually actions) and every column in
/// between becomes a label / value line. Tables with one or two columns
/// simply omit the missing slots.
class TableMobileView<T> extends StatelessWidget {
  final List<TableColumn<T>> columns;
  final List<T> tableData;
  final List<Widget> Function(T) rows;
  final ScrollController vCtrl;
  final bool showCheckbox;
  final Set<Object> selectedItems;
  final Object Function(T item)? itemKey;
  final void Function(T item, bool? value)? onSelectRow;
  final void Function(T item)? onRowTap;
  final Future<void> Function(int oldIndex, int newIndex)? onReorder;
  final bool isSaving;

  const TableMobileView({
    super.key,
    required this.columns,
    required this.tableData,
    required this.rows,
    required this.vCtrl,
    required this.showCheckbox,
    required this.selectedItems,
    this.itemKey,
    this.onSelectRow,
    this.onRowTap,
    this.onReorder,
    this.isSaving = false,
  });

  Object _keyOf(T item) => itemKey?.call(item) ?? item as Object;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.all(AppSpacing.lg);
    final reorder = onReorder;

    return Scrollbar(
      controller: vCtrl,
      child: reorder != null
          ? ReorderableListView.builder(
              scrollController: vCtrl,
              buildDefaultDragHandles: false,
              padding: padding,
              itemCount: tableData.length,
              onReorderItem: (oldIndex, newIndex) =>
                  reorder(oldIndex, newIndex),
              itemBuilder: (context, index) => Padding(
                key: ValueKey(_keyOf(tableData[index])),
                padding: AppSpacing.md.bPadding,
                child: _buildCard(context, index, isReorderable: true),
              ),
            )
          : ListView.separated(
              controller: vCtrl,
              padding: padding,
              itemCount: tableData.length,
              separatorBuilder: (_, _) => AppSpacing.md.h,
              itemBuilder: (context, index) =>
                  _buildCard(context, index, isReorderable: false),
            ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    int index, {
    required bool isReorderable,
  }) {
    final colors = context.colors;
    final item = tableData[index];
    final isSelected = showCheckbox && selectedItems.contains(_keyOf(item));

    Widget cellAt(int columnIndex) => columns[columnIndex].buildCell(
      item,
      index,
      columnIndex,
      () => rows(item),
    );

    final hasLead = columns.isNotEmpty;
    final hasTrailing = columns.length > 1;
    final bodyColumns = columns.length > 2
        ? List.generate(columns.length - 2, (i) => i + 1)
        : const <int>[];

    final header = Row(
      children: [
        if (isReorderable)
          ReorderableDragStartListener(
            index: index,
            enabled: !isSaving,
            child: Padding(
              padding: AppSpacing.sm.rPadding,
              child: TableDragHandle(isSaving: isSaving),
            ),
          ),
        if (showCheckbox)
          TableCheckbox(
            value: isSelected,
            onChanged: (value) => onSelectRow?.call(item, value),
          ),
        if (hasLead)
          Flexible(
            child: QuickContainer(
              px: AppSpacing.sm + 2,
              py: AppSpacing.xs,
              radius: AppRadius.sm,
              color: colors.surfaceMuted,
              child: DefaultTextStyle.merge(
                style: context.textTheme.bodySmall?.bold().colour(
                  colors.onSurface,
                ),
                child: cellAt(0),
              ),
            ),
          ),
        const Spacer(),
        if (hasTrailing) cellAt(columns.length - 1),
      ],
    );

    return AnimatedContainer(
      duration: AppDurations.instant,
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primary.withValues(alpha: 0.06)
            : colors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.4)
              : colors.borderLight,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onRowTap != null ? () => onRowTap!(item) : null,
          borderRadius: AppRadius.lgRadius,
          child: Padding(
            padding: AppSpacing.lg.allPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                if (bodyColumns.isNotEmpty) ...[
                  Padding(
                    padding: AppSpacing.md.yPadding,
                    child: Divider(height: 1, color: colors.borderExtraLight),
                  ),
                  for (final columnIndex in bodyColumns)
                    _FieldLine(
                      label: columns[columnIndex].title,
                      isLast: columnIndex == bodyColumns.last,
                      child: cellAt(columnIndex),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLine extends StatelessWidget {
  const _FieldLine({
    required this.label,
    required this.isLast,
    required this.child,
  });

  final String label;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: isLast ? EdgeInsets.zero : (AppSpacing.sm + 2).bPadding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodySmall?.medium().colour(
                colors.onSurfaceSecondary,
              ),
            ),
          ),
          AppSpacing.md.w,
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: DefaultTextStyle.merge(
                textAlign: TextAlign.right,
                style: context.textTheme.bodySmall?.semiBold().colour(
                  colors.onSurface,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
