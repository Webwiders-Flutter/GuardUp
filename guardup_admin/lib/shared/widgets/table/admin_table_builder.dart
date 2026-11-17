import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '/shared/widgets/state/app_state_view.dart';
import 'table_models.dart';
import 'table_desktop_view.dart';
import 'table_filter_bar.dart';
import 'table_footer.dart';
import 'table_mobile_view.dart';
import 'table_skeleton_view.dart';
import 'table_top_bar.dart';

/// A 10/10 enterprise-grade generic admin data table with:
/// - Responsive desktop (two-dimensional virtualized spreadsheet) and mobile (card) layouts
/// - Type-safe [TableColumn] definitions with custom widths and alignment
/// - Column header sorting with animated indicators
/// - Row hover states and clickable rows (`onRowTap`)
/// - Row selection highlights with integrated batch actions
/// - Drag-and-drop row reordering (desktop and mobile)
/// - Modern search bar with instant clear button
/// - Page number pagination pills (`[1] [2] [3] ... [N]`)
/// - Integrated empty and loading states via [AppStateView]
class AdminTableBuilder<T> extends StatefulWidget {
  final String title;
  final String subtitle;

  /// Rich column definitions. If provided, takes precedence over [columnHeadings].
  final List<TableColumn<T>>? columns;

  /// Simple string column headings (provided for backward compatibility).
  final List<String> columnHeadings;

  /// The list of items to display in the table.
  final List<T> tableData;

  /// Row cell generator returning widgets corresponding to columns.
  final List<Widget> Function(T item)? rows;

  final int rowsPerPage;
  final TextEditingController searchController;
  final List<Widget> actions;
  final List<Widget> selectionActions;
  final int totalEntries;
  final bool load;
  final int currentPage;
  final double actionColumnWidth;
  final List<TableFilterChip> filterChips;
  final dynamic activeFilter;

  /// Active secondary or contextual filters that can be dismissed individually (e.g. Order ID, Driver, Transporter).
  final List<TableRemovableFilter> activeFilters;

  /// Optional callback invoked when the user clears all active removable filters.
  final VoidCallback? onClearAllFilters;

  // Row interactions & sorting
  final void Function(T item)? onRowTap;
  final TableSortState? sortState;
  final void Function(String columnKey, bool ascending)? onSort;
  final void Function(int page)? onPageSelected;
  final bool striped;
  final bool enableHover;

  // Checkbox multi-select
  final bool showSearchField;
  final bool showCheckbox;

  /// Optional external [ValueNotifier] exposing the list of currently selected items [T].
  /// If provided, [AdminTableBuilder] updates it automatically when users select/deselect rows.
  /// If null and selection is enabled, [AdminTableBuilder] manages an internal notifier.
  final ValueNotifier<List<T>>? selectedItemsNotifier;

  /// Optional builder for selection actions receiving the currently selected items [T].
  final List<Widget> Function(List<T> selectedItems)? selectionActionsBuilder;

  final Set<Object> selectedItems;
  final Object Function(T item)? itemKey;
  final void Function(bool? value, List<T> items)? onSelectAll;
  final void Function(T item, bool? value)? onSelectRow;

  final void Function(dynamic)? onFilterChanged;
  final void Function(dynamic)? onSearch;

  /// Debounce duration applied to [onSearch] to prevent excessive API requests while typing.
  /// Defaults to 500 milliseconds.
  final Duration searchDebounceDuration;
  final Future<void> Function()? onLoadMore;
  final Future<void> Function()? onRefresh;
  final void Function()? onPrevious;
  final void Function(int)? onLimitChange;

  /// Custom row height for table rows. Defaults to 52.0 ([AppSpacing.xxxl + AppSpacing.xl]).
  final double? rowHeight;

  // Drag & drop reorder
  final Future<void> Function(int oldIndex, int newIndex)? onReorder;
  final bool isSaving;

  /// Maximum number of category chips displayed inline before collapsing into a "+N" overflow popup.
  /// Defaults to 5.
  final int maxVisibleChips;

  /// Maximum number of active removable filter badges displayed inline before collapsing into a "+N" overflow popup.
  /// Defaults to 5.
  final int maxVisibleRemovableFilters;

  /// Placement position for the multi-select toggle trigger.
  /// Defaults to [SelectionTogglePosition.start] (inline at the start of filter chips).
  final SelectionTogglePosition selectionTogglePosition;

  const AdminTableBuilder({
    super.key,
    this.title = 'Table',
    this.subtitle = '',
    this.columns,
    this.columnHeadings = const [],
    required this.tableData,
    this.rows,
    required this.searchController,
    this.actions = const [],
    this.selectionActions = const [],
    this.selectionActionsBuilder,
    this.selectedItemsNotifier,
    this.rowsPerPage = 10,
    this.actionColumnWidth = 140,
    required this.currentPage,
    required this.totalEntries,
    this.load = false,
    this.filterChips = const [],
    this.activeFilter,
    this.activeFilters = const [],
    this.onClearAllFilters,
    this.maxVisibleChips = 5,
    this.maxVisibleRemovableFilters = 5,
    this.onRowTap,
    this.sortState,
    this.onSort,
    this.onPageSelected,
    this.striped = true,
    this.enableHover = true,
    this.rowHeight,
    this.onFilterChanged,
    this.onSearch,
    this.searchDebounceDuration = const Duration(milliseconds: 500),
    this.onLimitChange,
    this.onLoadMore,
    this.onRefresh,
    this.onPrevious,
    this.showCheckbox = false,
    this.selectionTogglePosition = SelectionTogglePosition.start,
    this.showSearchField = false,
    this.selectedItems = const {},
    this.itemKey,
    this.onSelectAll,
    this.onSelectRow,
    this.onReorder,
    this.isSaving = false,
  }) : assert(
         columns != null || columnHeadings.length > 0,
         'Either columns or columnHeadings must be provided.',
       );

  @override
  State<AdminTableBuilder<T>> createState() => _AdminTableBuilderState<T>();
}

class _AdminTableBuilderState<T> extends State<AdminTableBuilder<T>> {
  final ScrollController _hCtrl = ScrollController();
  final ScrollController _vCtrl = ScrollController();
  late final ValueNotifier<int> _limitNotifier;
  late final ValueNotifier<bool> _isSelectionActiveNotifier;
  late final ValueNotifier<List<T>> _internalSelectedNotifier;
  final ValueNotifier<bool> _nextLoading = ValueNotifier(false);
  Timer? _searchDebounceTimer;

  ValueNotifier<List<T>> get _effectiveSelectedNotifier =>
      widget.selectedItemsNotifier ?? _internalSelectedNotifier;

  @override
  void initState() {
    super.initState();
    final initialLimit = widget.rowsPerPage == 0 ? 10 : widget.rowsPerPage;
    _limitNotifier = ValueNotifier<int>(initialLimit);
    _internalSelectedNotifier = ValueNotifier<List<T>>([]);
    _isSelectionActiveNotifier = ValueNotifier<bool>(
      _effectiveSelectedNotifier.value.isNotEmpty ||
          widget.selectedItems.isNotEmpty,
    );
  }

  @override
  void didUpdateWidget(covariant AdminTableBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rowsPerPage != oldWidget.rowsPerPage) {
      _limitNotifier.value = widget.rowsPerPage == 0 ? 10 : widget.rowsPerPage;
    }
    if ((_effectiveSelectedNotifier.value.isNotEmpty ||
            widget.selectedItems.isNotEmpty) &&
        !_isSelectionActiveNotifier.value) {
      _isSelectionActiveNotifier.value = true;
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _hCtrl.dispose();
    _vCtrl.dispose();
    _limitNotifier.dispose();
    _internalSelectedNotifier.dispose();
    _isSelectionActiveNotifier.dispose();
    _nextLoading.dispose();
    super.dispose();
  }

  bool get _canSelect => widget.showCheckbox;

  Object _resolveKey(T item) => widget.itemKey?.call(item) ?? (item as Object);

  void _handleSelectRow(T item, bool? value) {
    final currentList = List<T>.from(_effectiveSelectedNotifier.value);
    final key = _resolveKey(item);

    if (value == true) {
      final exists = currentList.any((e) => _resolveKey(e) == key);
      if (!exists) {
        currentList.add(item);
      }
    } else {
      currentList.removeWhere((e) => _resolveKey(e) == key);
    }

    _effectiveSelectedNotifier.value = currentList;
    widget.onSelectRow?.call(item, value);
  }

  void _handleSelectAll(bool? value, List<T> items) {
    if (value == true) {
      final currentList = List<T>.from(_effectiveSelectedNotifier.value);
      final currentKeys = currentList.map(_resolveKey).toSet();
      for (final item in items) {
        if (!currentKeys.contains(_resolveKey(item))) {
          currentList.add(item);
        }
      }
      _effectiveSelectedNotifier.value = currentList;
    } else {
      final currentList = List<T>.from(_effectiveSelectedNotifier.value);
      final visibleKeys = items.map(_resolveKey).toSet();
      currentList.removeWhere((e) => visibleKeys.contains(_resolveKey(e)));
      _effectiveSelectedNotifier.value = currentList;
    }
    widget.onSelectAll?.call(value, items);
  }

  void _handleClearSelection() {
    _effectiveSelectedNotifier.value = [];
    widget.onSelectAll?.call(false, widget.tableData);
  }

  void _toggleSelectionMode() {
    final next = !_isSelectionActiveNotifier.value;
    _isSelectionActiveNotifier.value = next;
    if (!next) {
      _handleClearSelection();
    }
  }

  void _handleSearch(dynamic query) {
    if (widget.onSearch == null) return;

    final queryStr = query?.toString() ?? '';
    // If search is cleared immediately, cancel timer and fire immediately
    if (queryStr.isEmpty) {
      _searchDebounceTimer?.cancel();
      widget.onSearch!(query);
      return;
    }

    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(widget.searchDebounceDuration, () {
      if (mounted) {
        widget.onSearch!(query);
      }
    });
  }

  List<TableColumn<T>> get _resolvedColumns {
    if (widget.columns != null && widget.columns!.isNotEmpty) {
      return widget.columns!;
    }
    return widget.columnHeadings.asMap().entries.map((e) {
      final idx = e.key;
      final heading = e.value;
      return TableColumn<T>(
        title: heading,
        key: heading,
        alignment: idx == 0
            ? Alignment.center
            : (idx == widget.columnHeadings.length - 1
                  ? Alignment.center
                  : Alignment.centerLeft),
      );
    }).toList();
  }

  List<Widget> _resolvedRows(T item) {
    if (widget.rows != null) {
      return widget.rows!(item);
    }
    return _resolvedColumns.asMap().entries.map((e) {
      final idx = e.key;
      final col = e.value;
      if (col.cellBuilder != null) {
        return col.cellBuilder!(item, idx);
      }
      return const SizedBox.shrink();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isServerSide = widget.totalEntries > widget.tableData.length;
    final int pageStart = (widget.currentPage - 1) * widget.rowsPerPage;
    final bool hasPagedCache =
        widget.tableData.length > widget.rowsPerPage &&
        widget.tableData.length > pageStart;

    final int start = hasPagedCache
        ? pageStart
        : (isServerSide ? 0 : pageStart.clamp(0, widget.tableData.length));
    final int end = hasPagedCache
        ? min(start + widget.rowsPerPage, widget.tableData.length)
        : (isServerSide
              ? widget.tableData.length
              : min(start + widget.rowsPerPage, widget.tableData.length));

    return ValueListenableBuilder<bool>(
      valueListenable: _isSelectionActiveNotifier,
      builder: (context, isSelectionActive, _) {
        final bool effectiveShowCheckbox = _canSelect && isSelectionActive;

        return ValueListenableBuilder<List<T>>(
          valueListenable: _effectiveSelectedNotifier,
          builder: (context, selectedList, _) {
            final Set<Object> selectedKeys = {
              ...selectedList.map(_resolveKey),
              ...widget.selectedItems,
            };

            final List<Widget> resolvedSelectionActions =
                widget.selectionActionsBuilder != null
                ? widget.selectionActionsBuilder!(selectedList)
                : widget.selectionActions;
            final hasFilterChips =
                widget.filterChips.isNotEmpty ||
                widget.activeFilters.isNotEmpty;
            final showInFilterBar =
                _canSelect &&
                hasFilterChips &&
                widget.selectionTogglePosition !=
                    SelectionTogglePosition.topBar;
            final showInTopBar =
                _canSelect &&
                (!hasFilterChips ||
                    widget.selectionTogglePosition ==
                        SelectionTogglePosition.topBar);

            return Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: AppRadius.lgRadius,
                border: Border.all(
                  color: context.colors.borderLight.withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.black.withValues(alpha: 0.03),
                    blurRadius: AppSpacing.lg + 2,
                    offset: const Offset(0, AppSpacing.xs),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TableTopBar(
                    title: widget.title,
                    limitNotifier: _limitNotifier,
                    subtitle: widget.subtitle.isNotEmpty
                        ? widget.subtitle
                        : '${widget.totalEntries} total records',
                    searchController: widget.searchController,
                    onSearch: _handleSearch,
                    onRefresh: widget.onRefresh,
                    onLimitChange: widget.onLimitChange,
                    actions: widget.actions,
                    showSearchField: widget.showSearchField,
                    selectedCount: selectedKeys.length,
                    selectionActions: resolvedSelectionActions,
                    showSelectionToggle: showInTopBar,
                    isSelectionModeActive: effectiveShowCheckbox,
                    onToggleSelectionMode: _toggleSelectionMode,
                    onClearSelection: _handleClearSelection,
                  ),
                  if (hasFilterChips || showInFilterBar)
                    TableFilterChipBar(
                      chips: widget.filterChips,
                      active: widget.activeFilter,
                      onTap: widget.onFilterChanged,
                      activeFilters: widget.activeFilters,
                      onClearAllFilters: widget.onClearAllFilters,
                      maxVisibleChips: widget.maxVisibleChips,
                      maxVisibleRemovableFilters:
                          widget.maxVisibleRemovableFilters,
                      showSelectionToggle: showInFilterBar,
                      isSelectionModeActive: effectiveShowCheckbox,
                      onToggleSelectionMode: _toggleSelectionMode,
                      selectedCount: selectedKeys.length,
                      togglePosition: widget.selectionTogglePosition,
                    ),
                  Expanded(
                    child: widget.load
                        ? _buildLoadingState(
                            context,
                            start,
                            end,
                            isServerSide,
                            showCheckbox: effectiveShowCheckbox,
                            selectedItems: selectedKeys,
                            onSelectRow: _handleSelectRow,
                            onSelectAll: _handleSelectAll,
                          )
                        : widget.tableData.isEmpty
                        ? _buildEmptyState(context)
                        : _buildResponsiveTable(
                            start,
                            end,
                            isServerSide,
                            showCheckbox: effectiveShowCheckbox,
                            selectedItems: selectedKeys,
                            onSelectRow: _handleSelectRow,
                            onSelectAll: _handleSelectAll,
                          ),
                  ),
                  TableFooter(
                    totalEntries: widget.totalEntries,
                    rowsPerPage: widget.rowsPerPage,
                    currentPage: widget.currentPage,
                    visibleCount: widget.tableData.length,
                    nextLoading: _nextLoading,
                    onPrevious:
                        widget.onPrevious ??
                        (widget.onPageSelected != null
                            ? _handlePrevious
                            : null),
                    onNext: _handleNext,
                    onPageSelected: widget.onPageSelected,
                    limitNotifier: _limitNotifier,
                    onLimitChange: widget.onLimitChange,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  double _calculateColWidth(
    BoxConstraints constraints,
    List<TableColumn<T>> cols, {
    required bool showCheckbox,
  }) {
    const double checkWidth = AppSpacing.xxl + AppSpacing.xl + 2;

    double fixedWidths = showCheckbox ? checkWidth : 0;
    int totalFlex = 0;
    for (final col in cols) {
      if (col.width != null) {
        fixedWidths += col.width!;
      } else {
        totalFlex += col.flex;
      }
    }

    final double available = constraints.maxWidth - fixedWidths;
    final double flexUnit = totalFlex > 0 ? (available / totalFlex) : 160.0;
    return flexUnit < 140 ? 140.0 : flexUnit;
  }

  Widget _buildLoadingState(
    BuildContext context,
    int start,
    int end,
    bool isServerSide, {
    required bool showCheckbox,
    required Set<Object> selectedItems,
    required void Function(T item, bool? value) onSelectRow,
    required void Function(bool? value, List<T> items) onSelectAll,
  }) {
    if (widget.tableData.isEmpty) {
      return LayoutBuilder(
        builder: (ctx, constraints) {
          final resolvedCols = _resolvedColumns;
          final colWidth = _calculateColWidth(
            constraints,
            resolvedCols,
            showCheckbox: showCheckbox,
          );

          return TableSkeletonView<T>(
            columns: resolvedCols,
            showCheckbox: showCheckbox,
            colWidth: colWidth,
            actionColumnWidth: widget.actionColumnWidth,
            rowHeight: widget.rowHeight ?? (AppSpacing.xxxl + AppSpacing.xl),
            rowCount: widget.rowsPerPage.clamp(5, 8),
            striped: widget.striped,
            hCtrl: _hCtrl,
            vCtrl: _vCtrl,
          );
        },
      );
    }

    return Stack(
      children: [
        Opacity(
          opacity: 0.55,
          child: _buildResponsiveTable(
            start,
            end,
            isServerSide,
            showCheckbox: showCheckbox,
            selectedItems: selectedItems,
            onSelectRow: onSelectRow,
            onSelectAll: onSelectAll,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: LinearProgressIndicator(
            minHeight: 2.5,
            backgroundColor: context.colors.transparent,
            valueColor: AlwaysStoppedAnimation(context.colors.secondary),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final hasSearch = widget.searchController.text.trim().isNotEmpty;
    final hasFilter =
        widget.activeFilter != null || widget.activeFilters.isNotEmpty;

    if (hasSearch || hasFilter) {
      return AppStateView.noResults(
        onAction: () {
          widget.searchController.clear();
          widget.onFilterChanged?.call(null);
          widget.onClearAllFilters?.call();
        },
        actionText: 'Clear filters',
      );
    }

    return const AppStateView.empty();
  }

  Widget _buildResponsiveTable(
    int start,
    int end,
    bool isServerSide, {
    required bool showCheckbox,
    required Set<Object> selectedItems,
    required void Function(T item, bool? value) onSelectRow,
    required void Function(bool? value, List<T> items) onSelectAll,
  }) {
    final displayData =
        (isServerSide && widget.tableData.length <= widget.rowsPerPage)
        ? widget.tableData
        : (widget.tableData.length >= end
              ? widget.tableData.sublist(start, end)
              : widget.tableData);

    final resolvedCols = _resolvedColumns;

    return SelectionArea(
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          if (constraints.maxWidth < 640) {
            return TableMobileView<T>(
              columns: resolvedCols,
              tableData: displayData,
              rows: _resolvedRows,
              vCtrl: _vCtrl,
              showCheckbox: showCheckbox,
              selectedItems: selectedItems,
              itemKey: widget.itemKey,
              onSelectRow: onSelectRow,
              onRowTap: widget.onRowTap,
              onReorder: widget.onReorder,
              isSaving: widget.isSaving,
            );
          }

          final colWidth = _calculateColWidth(
            constraints,
            resolvedCols,
            showCheckbox: showCheckbox,
          );

          return TableDesktopView<T>(
            columns: resolvedCols,
            tableData: displayData,
            rows: _resolvedRows,
            hCtrl: _hCtrl,
            vCtrl: _vCtrl,
            actionColumnWidth: widget.actionColumnWidth,
            colWidth: colWidth,
            showCheckbox: showCheckbox,
            selectedItems: selectedItems,
            itemKey: widget.itemKey,
            onSelectAll: onSelectAll,
            onSelectRow: onSelectRow,
            onRowTap: widget.onRowTap,
            sortState: widget.sortState,
            onSort: widget.onSort,
            onReorder: widget.onReorder,
            isSaving: widget.isSaving,
            striped: widget.striped,
            enableHover: widget.enableHover,
            rowHeight: widget.rowHeight ?? (AppSpacing.xxxl + AppSpacing.xl),
          );
        },
      ),
    );
  }

  void _handlePrevious() {
    if (widget.onPrevious != null) {
      widget.onPrevious!();
    } else if (widget.onPageSelected != null && widget.currentPage > 1) {
      widget.onPageSelected!(widget.currentPage - 1);
    }
  }

  Future<void> _handleNext() async {
    _nextLoading.value = true;
    try {
      if (widget.onLoadMore != null) {
        await widget.onLoadMore!.call();
      } else if (widget.onPageSelected != null) {
        widget.onPageSelected!(widget.currentPage + 1);
      }
    } finally {
      if (mounted) {
        _nextLoading.value = false;
      }
    }
  }
}
