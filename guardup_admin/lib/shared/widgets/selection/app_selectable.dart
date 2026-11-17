import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';

class AppSelectable extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;
  final bool nativeChangesDisabled;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedBorderColor;
  final Color? unselectedBorderColor;
  final double? selectedBorderWidth;
  final double? unselectedBorderWidth;
  final Duration duration;
  final Curve curve;

  const AppSelectable({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.child,
    this.nativeChangesDisabled = false,
    this.padding,
    this.borderRadius,
    this.selectedColor,
    this.unselectedColor,
    this.selectedBorderColor,
    this.unselectedBorderColor,
    this.selectedBorderWidth,
    this.unselectedBorderWidth,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCardSelected = !nativeChangesDisabled && isSelected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: duration,
          curve: curve,
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
          decoration: BoxDecoration(
            color: isCardSelected
                ? (selectedColor ?? colors.secondary.withValues(alpha: 0.15))
                : (unselectedColor ?? colors.surface),
            borderRadius: borderRadius ?? AppRadius.mdRadius,
            border: Border.all(
              color: isCardSelected
                  ? (selectedBorderColor ?? colors.secondary)
                  : (unselectedBorderColor ?? colors.borderLight),
              width: isCardSelected
                  ? (selectedBorderWidth ?? 2.0)
                  : (unselectedBorderWidth ?? 1.5),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
