import 'package:flutter/material.dart';

class SelectionController<T> extends ValueNotifier<List<T>> {
  SelectionController(super.initial, {this.isSingleSelection = false});
  final bool isSingleSelection;

  bool isSelected(T value) => this.value.contains(value);

  void toggle(T value) {
    if (isSingleSelection) {
      this.value = [value];
    } else {
      if (isSelected(value)) {
        this.value = [...this.value]..remove(value);
      } else {
        this.value = [...this.value, value];
      }
    }
  }
}
