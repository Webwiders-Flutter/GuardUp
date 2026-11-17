import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/controllers/selection.controller.dart';
import '../models/dashboard_stats_models.dart';

/// Clean, standardized dropdown filter pill for [DashboardStatsCard].
/// Built with [QuickContainer] without icons, optionally powered by [SelectionController]
/// for unified state management and minimal redundancy across the app.
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
    this.maxWidth = 160.0,
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

  @override
  Widget build(BuildContext context) {
    final borderColor = context.colors.borderLight;
    final primaryColor = context.colors.primary;

    Widget buildButton(T? currentValue) {
      final isActive = _isActive;

      return PopupMenuButton<int>(
        tooltip: prefixLabel != null
            ? 'Filter by $prefixLabel'
            : 'Select Filter',
        offset: const Offset(0, 36),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdRadius,
          side: BorderSide(color: borderColor),
        ),
        elevation: 4,
        color: context.colors.surface,
        onSelected: (int index) {
          if (index >= 0 && index < options.length) {
            _handleSelect(options[index].value);
          }
        },
        itemBuilder: (context) {
          return List.generate(options.length, (index) {
            final option = options[index];
            final isSelected = currentValue == option.value;
            return PopupMenuItem<int>(
              value: index,
              height: AppSpacing.xxl + 4,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs + 2,
                vertical: 2,
              ),
              child: QuickContainer(
                px: AppSpacing.md,
                py: AppSpacing.sm,
                radius: AppRadius.sm,
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.1)
                    : context.colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.3)
                      : context.colors.transparent,
                ),
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium
                      ?.colour(
                        isSelected ? primaryColor : context.colors.onSurface,
                      )
                      .weight(isSelected ? FontWeight.w600 : FontWeight.w400),
                ),
              ),
            );
          });
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: QuickContainer(
            px: AppSpacing.sm + 2,
            py: AppSpacing.xs + 2,
            radius: AppRadius.md,
            color: isActive
                ? primaryColor.withValues(alpha: 0.08)
                : context.colors.backgroundLight,
            border: Border.all(
              color: isActive
                  ? primaryColor.withValues(alpha: 0.5)
                  : borderColor,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    prefixLabel != null
                        ? '$prefixLabel: $_currentLabel'
                        : _currentLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelMedium?.semiBold().colour(
                      isActive ? primaryColor : context.colors.onSurface,
                    ),
                  ),
                ),
                AppSpacing.xs.w,
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: AppSpacing.lg,
                  color: isActive
                      ? primaryColor
                      : context.colors.onSurfaceSecondary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (controller != null) {
      return ListenableBuilder(
        listenable: controller!,
        builder: (context, _) => buildButton(_currentValue),
      );
    }

    return buildButton(_currentValue);
  }
}
