import 'package:flutter/material.dart';

import '/shared/controllers/selection.controller.dart';
import '../models/dashboard_stats_models.dart';
import 'dashboard_filter_button.dart';

/// Dropdown filter pill for [DashboardStatsCard] headers (e.g. "Status").
/// Optionally driven by a [SelectionController] for shared selection state.
class DashboardDropdownFilter<T> extends StatelessWidget {
  final String? prefixLabel;
  final SelectionController<T>? controller;
  final T? selectedValue;
  final List<DashboardDropdownOption<T>> options;
  final ValueChanged<T?>? onSelected;
  final bool Function(T? value)? isOptionActive;
  final double maxWidth;

  const DashboardDropdownFilter({
    super.key,
    this.prefixLabel,
    this.controller,
    this.selectedValue,
    required this.options,
    this.onSelected,
    this.isOptionActive,
    this.maxWidth = 140.0,
  });

  T? get _currentValue {
    if (controller != null && controller!.value.isNotEmpty) {
      return controller!.value.first;
    }
    return selectedValue;
  }

  String get _currentLabel {
    final val = _currentValue;
    for (final opt in options) {
      if (opt.value == val) return opt.label;
    }
    return options.isNotEmpty ? options.first.label : '';
  }

  bool get _isActive {
    final val = _currentValue;
    if (isOptionActive != null) return isOptionActive!(val);
    if (val == null) return false;
    if (options.isNotEmpty && options.first.value == val) return false;
    return true;
  }

  void _handleSelect(T? value) {
    if (controller != null) {
      if (value != null) {
        controller!.toggle(value);
      } else {
        controller!.value = [];
      }
    }
    onSelected?.call(value);
  }

  Widget _buildButton() {
    final current = _currentValue;
    return DashboardFilterButton<T?>(
      label: _currentLabel,
      prefix: prefixLabel,
      icon: Icons.filter_list_rounded,
      menuTitle: prefixLabel != null ? 'Filter by $prefixLabel' : null,
      tooltip: prefixLabel != null ? 'Filter by $prefixLabel' : null,
      isActive: _isActive,
      maxLabelWidth: maxWidth,
      entries: [
        for (final option in options)
          (
            value: option.value,
            label: option.label,
            icon: option.icon,
            isSelected: option.value == current,
            dividerBefore: false,
          ),
      ],
      onSelected: _handleSelect,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) return _buildButton();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _buildButton(),
    );
  }
}
