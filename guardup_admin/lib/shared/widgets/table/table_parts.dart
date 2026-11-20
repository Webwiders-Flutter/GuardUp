import 'package:flutter/material.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_layout.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import 'table_models.dart';

/// Shared visual building blocks for the [AdminTableBuilder] views, so the
/// virtualized, reorderable, mobile and skeleton layouts stay identical.

/// Background of a data row for its state. Priority: selected > hovered >
/// zebra stripe > surface.
Color tableRowColor(
  BuildContext context, {
  required int rowIndex,
  bool isSelected = false,
  bool isHovered = false,
  bool striped = false,
}) {
  final colors = context.colors;
  if (isSelected) return colors.primary.withValues(alpha: 0.08);
  if (isHovered) return colors.primary.withValues(alpha: 0.04);
  if (striped && rowIndex.isOdd) {
    return colors.surfaceMuted.withValues(alpha: 0.7);
  }
  return colors.surface;
}

/// Hairline between rows.
BorderSide tableRowDivider(BuildContext context) =>
    BorderSide(color: context.colors.borderExtraLight);

/// Hairline under the header row.
BorderSide tableHeaderDivider(BuildContext context) =>
    BorderSide(color: context.colors.borderLight);

/// Uppercase column title with an optional sort affordance.
class TableHeaderLabel<T> extends StatelessWidget {
  const TableHeaderLabel({
    super.key,
    required this.column,
    this.sortState,
    this.onSort,
  });

  final TableColumn<T> column;
  final TableSortState? sortState;
  final void Function(String columnKey, bool ascending)? onSort;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isSorted = sortState?.columnKey == column.sortKey;
    final isAscending = sortState?.ascending ?? true;
    final isSortable = column.sortable && onSort != null;
    final color = isSorted ? colors.primary : colors.onSurfaceSecondary;

    final label =
        column.headerWidget ??
        Text(
          column.title.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelMedium
              ?.size(AppSpacing.md - 0.5)
              .bold()
              .textSpacing(0.6)
              .colour(color),
        );

    if (!isSortable) return label;

    return InkWell(
      onTap: () => onSort!(column.sortKey, isSorted ? !isAscending : true),
      borderRadius: AppRadius.smRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs / 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: label),
            AppSpacing.xs.w,
            AnimatedSwitcher(
              duration: AppDurations.fast,
              child: Icon(
                !isSorted
                    ? Icons.unfold_more_rounded
                    : isAscending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                key: ValueKey('${isSorted}_$isAscending'),
                size: AppLayout.iconXs,
                color: isSorted ? color : color.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Themed row/header selection checkbox. A null [value] renders the
/// indeterminate state (some rows selected).
class TableCheckbox extends StatelessWidget {
  const TableCheckbox({super.key, required this.value, this.onChanged});

  final bool? value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      tristate: value == null,
      onChanged: onChanged == null
          ? null
          : (next) => onChanged!(value == null ? true : next),
    );
  }
}

/// Header-checkbox value for the visible rows: all, none, or partial (null).
bool? tableSelectAllValue<T>(
  List<T> rows,
  Set<Object> selectedKeys,
  Object Function(T item) keyOf,
) {
  if (rows.isEmpty) return false;
  final selected = rows.where((row) => selectedKeys.contains(keyOf(row)));
  if (selected.isEmpty) return false;
  return selected.length == rows.length ? true : null;
}

/// Grab handle for drag-and-drop reordering (spinner while saving).
class TableDragHandle extends StatelessWidget {
  const TableDragHandle({super.key, this.isSaving = false});

  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (isSaving) {
      return SizedBox.square(
        dimension: AppLayout.iconSm,
        child: CircularProgressIndicator(
          strokeWidth: AppSpacing.xs / 2,
          color: colors.primary,
        ),
      );
    }

    return Tooltip(
      message: 'Drag to reorder',
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Icon(
          Icons.drag_indicator_rounded,
          size: AppLayout.iconLg,
          color: colors.onSurfaceSecondary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
