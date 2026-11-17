import 'package:guardup_admin/shared/models/selectable_item.model.dart';
import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import '/shared/controllers/selection.controller.dart';
import '/shared/widgets/selection/app_selectable.dart';

/// A customizable, selectable chip widget backed by a [SelectionController].
class AppSelectableChip<V, D> extends StatelessWidget {
  final SelectableItem<V, D> item;
  final SelectionController<V> controller;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedBorderColor;
  final Color? unselectedBorderColor;
  final double? selectedBorderWidth;
  final double? unselectedBorderWidth;
  final TextStyle? textStyle;
  final TextStyle? selectedTextStyle;
  final Widget? icon;

  const AppSelectableChip({
    super.key,
    required this.item,
    required this.controller,
    this.padding,
    this.borderRadius,
    this.selectedColor,
    this.unselectedColor,
    this.selectedBorderColor,
    this.unselectedBorderColor,
    this.selectedBorderWidth = 1.0,
    this.unselectedBorderWidth = 1.0,
    this.textStyle,
    this.selectedTextStyle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isSelected = controller.isSelected(item.id);

        final defaultTextStyle = context.textTheme.labelMedium
            ?.semiBold()
            .colour(
              isSelected
                  ? context.colors.secondary
                  : context.colors.onSurfaceSecondary,
            );

        return AppSelectable(
          isSelected: isSelected,
          onTap: () => controller.toggle(item.id),
          padding: (padding as EdgeInsets?) ?? AppSpacing.md.allPadding,
          borderRadius: borderRadius ?? AppRadius.fullRadius,
          selectedColor:
              selectedColor ?? context.colors.secondary.withValues(alpha: 0.1),
          unselectedColor: unselectedColor ?? context.colors.surface,
          selectedBorderColor: selectedBorderColor ?? context.colors.secondary,
          unselectedBorderColor:
              unselectedBorderColor ??
              context.colors.borderLight.withValues(alpha: 0.5),
          selectedBorderWidth: selectedBorderWidth ?? 1.5,
          unselectedBorderWidth: unselectedBorderWidth ?? 1.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, AppSpacing.xs.w],
              Text(
                item.data.toString(),
                style: isSelected
                    ? (selectedTextStyle ?? defaultTextStyle)
                    : (textStyle ?? defaultTextStyle),
              ),
            ],
          ),
        );
      },
    );
  }
}
