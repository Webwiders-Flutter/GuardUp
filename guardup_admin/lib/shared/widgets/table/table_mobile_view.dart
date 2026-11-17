import 'package:guardup_admin/core/extensions/textstyle_extension.dart';
import 'package:guardup_admin/shared/widgets/table/table_models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';

/// Mobile card-based table view, used by [AdminTableBuilder] on narrow screens.
///
/// Supports both standard scrolling and drag-and-drop reordering seamlessly
/// using a unified modern card layout.
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

  bool get _isReorderable => onReorder != null;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: vCtrl,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: AppSpacing.sm - 2,
      radius: const Radius.circular(AppRadius.md),
      child: _isReorderable
          ? ReorderableListView.builder(
              scrollController: vCtrl,
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: tableData.length,
              onReorderItem: (oldIndex, newIndex) =>
                  onReorder!(oldIndex, newIndex),
              itemBuilder: (ctx, index) => _buildCard(ctx, index),
            )
          : ListView.separated(
              controller: vCtrl,
              itemCount: tableData.length,
              separatorBuilder: (_, _) => AppSpacing.md.h,
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemBuilder: (ctx, index) => _buildCard(ctx, index),
            ),
    );
  }

  Widget _buildCard(BuildContext context, int index) {
    final item = tableData[index];
    final cells = rows(item);
    final keyVal = itemKey?.call(item) ?? index;
    final bool isSelected = showCheckbox
        ? selectedItems.contains(keyVal)
        : false;

    final surfaceColor = isSelected
        ? context.colors.secondary.withValues(alpha: 0.1)
        : context.colors.surface;
    final borderColor = isSelected
        ? context.colors.secondary.withValues(alpha: 0.4)
        : context.colors.borderLight.withValues(alpha: 0.6);
    final surface2Color = context.colors.backgroundLight;
    final textColor = context.colors.onSurface;
    final mutedColor = context.colors.onSurfaceSecondary;

    return Container(
      key: ValueKey(keyVal),
      margin: _isReorderable
          ? const EdgeInsets.only(bottom: AppSpacing.md)
          : null,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: context.colors.black.withValues(alpha: 0.03),
            blurRadius: AppSpacing.sm + 2,
            offset: const Offset(0, AppSpacing.xs - 1),
          ),
        ],
      ),
      child: Material(
        color: context.colors.transparent,
        borderRadius: AppRadius.lgRadius,
        child: InkWell(
          onTap: onRowTap != null ? () => onRowTap!(item) : null,
          borderRadius: AppRadius.lgRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: drag handle + S.No. badge (+ optional checkbox) + action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (_isReorderable)
                          ReorderableDragStartListener(
                            index: index,
                            child: Padding(
                              padding: AppSpacing.sm.rPadding,
                              child: _buildDragHandle(context),
                            ),
                          ),
                        if (showCheckbox)
                          CupertinoCheckbox(
                            value: isSelected,
                            activeColor: context.colors.secondary,
                            onChanged: (val) => onSelectRow?.call(item, val),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 2,
                            vertical: AppSpacing.xs + 1,
                          ),
                          decoration: BoxDecoration(
                            color: surface2Color,
                            borderRadius: AppRadius.smRadius,
                          ),
                          child: DefaultTextStyle(
                            style:
                                (context.textTheme.bodySmall ??
                                        context.textTheme.bodyMedium!)
                                    .bold()
                                    .colour(textColor),
                            child: cells.isNotEmpty
                                ? cells.first
                                : Text('${index + 1}'),
                          ),
                        ),
                      ],
                    ),
                    if (cells.isNotEmpty) cells.last,
                  ],
                ),
                Padding(
                  padding: AppSpacing.md.yPadding,
                  child: Divider(
                    height: 1,
                    color: context.colors.borderLight.withValues(alpha: 0.4),
                  ),
                ),
                // Body field/value rows
                for (int c = 1; c < columns.length - 1; c++)
                  Padding(
                    padding: (AppSpacing.sm + 2).bPadding,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            columns[c].title,
                            style: context.textTheme.bodySmall
                                ?.size(AppSpacing.md)
                                .medium()
                                .colour(mutedColor),
                          ),
                        ),
                        AppSpacing.md.w,
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: DefaultTextStyle(
                              style:
                                  (context.textTheme.bodySmall ??
                                          context.textTheme.bodyMedium!)
                                      .size(AppSpacing.md + 1)
                                      .semiBold()
                                      .colour(textColor),
                              textAlign: TextAlign.right,
                              child: columns[c].cellBuilder != null
                                  ? columns[c].cellBuilder!(item, index)
                                  : (c < cells.length
                                        ? cells[c]
                                        : const SizedBox.shrink()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    if (isSaving) {
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
