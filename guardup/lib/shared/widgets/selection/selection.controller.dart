import 'package:flutter/foundation.dart';

/// A robust, reusable controller for managing single or multi-selection state.
///
/// Can drive any selectable widget (e.g. custom cards, chips, radios, checkboxes).
class SelectionController<T> extends ValueNotifier<List<T>> {
  /// Whether this controller only allows a single item to be selected at a time.
  final bool isSingleSelection;

  /// Whether tapping an already-selected item deselects it in single-selection mode.
  ///
  /// Defaults to `false` for single selection (radio-like behavior where one item  remains active), and `true` for multi-selection.
  final bool allowDeselect;

  /// Optional callback invoked whenever selection state changes.
  final ValueChanged<List<T>>? onChanged;

  SelectionController(
    super.initial, {
    this.isSingleSelection = false,
    this.allowDeselect = true,
    this.onChanged,
  });

  /// Factory for single-selection mode (e.g. Role selection, Radio group).
  factory SelectionController.single({
    T? initial,
    bool allowDeselect = false,
    ValueChanged<T?>? onChanged,
  }) {
    return SelectionController<T>(
      initial != null ? [initial] : [],
      isSingleSelection: true,
      allowDeselect: allowDeselect,
      onChanged: onChanged != null
          ? (items) => onChanged(items.isEmpty ? null : items.first)
          : null,
    );
  }

  /// Factory for multi-selection mode (e.g. Filter chips, Checkbox group).
  factory SelectionController.multi({
    List<T> initial = const [],
    ValueChanged<List<T>>? onChanged,
  }) {
    return SelectionController<T>(
      initial,
      isSingleSelection: false,
      allowDeselect: true,
      onChanged: onChanged,
    );
  }

  /// Returns the currently selected item in single-selection mode, or `null`.
  T? get selectedItem => value.isEmpty ? null : value.first;

  /// Sets the currently selected item in single-selection mode.
  set selectedItem(T? item) {
    if (item == null) {
      clear();
    } else {
      select(item);
    }
  }

  /// An unmodifiable view of all currently selected items.
  List<T> get selectedItems => List.unmodifiable(value);

  /// Number of currently selected items.
  int get count => value.length;

  /// Whether any items are selected.
  bool get isNotEmpty => value.isNotEmpty;

  /// Whether no items are selected.
  bool get isEmpty => value.isEmpty;

  /// Returns true if [item] is currently selected.
  bool isSelected(T item) => value.contains(item);

  /// Toggles the selection status of [item].
  void toggle(T item) {
    if (isSingleSelection) {
      if (isSelected(item)) {
        if (allowDeselect) {
          value = [];
          onChanged?.call(value);
        }
      } else {
        value = [item];
        onChanged?.call(value);
      }
    } else {
      if (isSelected(item)) {
        value = [...value]..remove(item);
      } else {
        value = [...value, item];
      }
      onChanged?.call(value);
    }
  }

  /// Explicitly selects [item].
  void select(T item) {
    if (isSelected(item)) return;
    if (isSingleSelection) {
      value = [item];
    } else {
      value = [...value, item];
    }
    onChanged?.call(value);
  }

  /// Explicitly deselects [item].
  void deselect(T item) {
    if (!isSelected(item)) return;
    value = [...value]..remove(item);
    onChanged?.call(value);
  }

  /// Selects all [allItems] (multi-selection only).
  void selectAll(List<T> allItems) {
    if (isSingleSelection) return;
    value = List.of(allItems);
    onChanged?.call(value);
  }

  /// Replaces the current selection with [items].
  void setSelection(List<T> items) {
    value = isSingleSelection
        ? (items.isEmpty ? [] : [items.first])
        : List.of(items);
    onChanged?.call(value);
  }

  /// Clears all selections.
  void clear() {
    if (value.isEmpty) return;
    value = [];
    onChanged?.call(value);
  }
}
