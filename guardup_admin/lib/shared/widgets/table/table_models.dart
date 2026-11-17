import 'package:flutter/widgets.dart';

/// Data tuple for a single filter chip displayed in [TableFilterChipBar].
typedef TableFilterChip = ({String label, dynamic value});

/// Data model for an active, dismissible/cancellable filter chip.
typedef TableRemovableFilter = ({
  String label,
  VoidCallback onRemove,
  IconData? icon,
  dynamic key,
});

/// Sort state specifying active column key and sort direction.
typedef TableSortState = ({String columnKey, bool ascending});

/// Placement position of the multi-select toggle trigger.
enum SelectionTogglePosition {
  /// Toggle chip placed at the beginning of the filter chip bar (before chips).
  start,

  /// Toggle chip placed at the end of the filter chip bar (after chips).
  end,

  /// Toggle icon button placed in the top-bar actions.
  topBar,
}

/// Rich column specification for [AdminTableBuilder].
///
/// Provides fine-grained control over column width, alignment,
/// sortability, and cell rendering.
class TableColumn<T> {
  /// The title displayed in the column header.
  final String title;

  /// Optional unique key identifying this column (e.g. for sorting).
  final String? key;

  /// Optional fixed width in pixels. If null, space is divided evenly
  /// or weighted by [flex].
  final double? width;

  /// Optional minimum width constraint in pixels.
  final double? minWidth;

  /// Optional maximum width constraint in pixels.
  final double? maxWidth;

  /// Flex weight when dividing remaining horizontal space.
  final int flex;

  /// Content alignment for both header and data cells in this column.
  final Alignment alignment;

  /// Whether clicking this column header triggers sorting.
  final bool sortable;

  /// Optional custom header widget overriding the default text title.
  final Widget? headerWidget;

  /// Optional typed cell builder for this specific column.
  /// If provided, supersedes the global `rows` callback for this column.
  final Widget Function(T item, int index)? cellBuilder;

  const TableColumn({
    required this.title,
    this.key,
    this.width,
    this.minWidth,
    this.maxWidth,
    this.flex = 1,
    this.alignment = Alignment.center,
    this.sortable = false,
    this.headerWidget,
    this.cellBuilder,
  });
}
