import 'package:flutter/material.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/sections/app_image.dart';
import 'selection.controller.dart';

/// A custom selectable card powered exclusively by [SelectionController].
///
/// Features smooth hardware-accelerated crossfades (no layout jumps or gradient
/// popping) and tactile touch feedback. Fully themed with Material 3 semantic tokens.
class AppSelectableCard<T> extends StatefulWidget {
  /// The [SelectionController] driving this card's selection state.
  final SelectionController<T> controller;

  /// The unique value associated with this card.
  final T value;

  /// Card title (primary text).
  final String title;

  /// Card subtitle (descriptive secondary text).
  final String subtitle;

  /// Optional asset path for the circular leading icon (SVG / PNG).
  final String? iconAssetPath;

  /// Optional custom leading widget overriding [iconAssetPath].
  final Widget? leading;

  /// Optional custom trailing widget overriding the circular arrow icon.
  final Widget? trailing;

  /// Card content padding. Defaults to `EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl)`.
  final EdgeInsetsGeometry? padding;

  /// Optional tap callback executed alongside selection toggle.
  final VoidCallback? onTap;

  /// Whether to render an ambient primary glow when selected. Defaults to true.
  final bool makeItGlow;

  /// Diameter of the leading circular icon container. Defaults to 58.0.
  final double leadingSize;

  /// Diameter of the trailing circular indicator. Defaults to 40.0.
  final double trailingSize;

  /// Icon size of the trailing indicator arrow. Defaults to 22.0.
  final double trailingIconSize;

  const AppSelectableCard({
    super.key,
    required this.controller,
    required this.value,
    required this.title,
    required this.subtitle,
    this.iconAssetPath,
    this.leading,
    this.trailing,
    this.padding,
    this.onTap,
    this.makeItGlow = true,
    this.leadingSize = 58.0,
    this.trailingSize = 40.0,
    this.trailingIconSize = 22.0,
  });

  @override
  State<AppSelectableCard<T>> createState() => _AppSelectableCardState<T>();
}

class _AppSelectableCardState<T> extends State<AppSelectableCard<T>> {
  late final ValueNotifier<bool> _isPressedNotifier;

  @override
  void initState() {
    super.initState();
    _isPressedNotifier = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _isPressedNotifier.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _isPressedNotifier.value = true;
  }

  void _onTapUp(TapUpDetails _) {
    _isPressedNotifier.value = false;
  }

  void _onTapCancel() {
    _isPressedNotifier.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<T>>(
      valueListenable: widget.controller,
      builder: (context, selection, _) {
        final isSelected = selection.contains(widget.value);
        final borderRadius = BorderRadius.circular(AppSpacing.lg);
        final innerRadius = BorderRadius.circular(AppSpacing.lg - 1.5);

        return ValueListenableBuilder<bool>(
          valueListenable: _isPressedNotifier,
          builder: (context, isPressed, _) {
            return AnimatedScale(
              scale: isPressed ? 0.985 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Base unselected card background & border (Fixed layout, zero shift)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: borderRadius,
                        border: Border.all(
                          color: context.colors.outlineVariant,
                          width: 1.2,
                        ),
                        gradient: context.colors.surfaceGradient,
                      ),
                    ),
                  ),

                  // 2. Selected gradient border layer & ambient glow (Smooth hardware crossfade)
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      opacity: isSelected ? 1.0 : 0.0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: borderRadius,
                          gradient: context.colors.primaryGradient,
                          boxShadow: widget.makeItGlow
                              ? [
                                  BoxShadow(
                                    color: context.colors.primary.withValues(
                                      alpha: 0.32,
                                    ),
                                    blurRadius: 28,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        padding: const EdgeInsets.all(1.5),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: innerRadius,
                            gradient: context.colors.surfaceGradient,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. InkWell touch & Content layer
                  Material(
                    color: context.colors.transparent,
                    borderRadius: borderRadius,
                    child: InkWell(
                      onTap: () {
                        widget.controller.toggle(widget.value);
                        widget.onTap?.call();
                      },
                      onTapDown: _onTapDown,
                      onTapUp: _onTapUp,
                      onTapCancel: _onTapCancel,
                      borderRadius: borderRadius,
                      splashColor: context.colors.primary.withValues(
                        alpha: 0.12,
                      ),
                      highlightColor: context.colors.primary.withValues(
                        alpha: 0.06,
                      ),
                      child: Padding(
                        padding:
                            widget.padding ??
                            const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.xl,
                            ),
                        child: Row(
                          children: [
                            // Leading Icon Badge
                            widget.leading ??
                                _buildLeadingIcon(context, isSelected),
                            AppSpacing.md.w,

                            // Title & Subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: context.textTheme.headlineSmall
                                        ?.bold()
                                        ,
                                  ),
                                  AppSpacing.xxs.h,
                                  Text(
                                    widget.subtitle,
                                    style: context.textTheme.bodyMedium?.colour(
                                      context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppSpacing.md.w,

                            // Trailing Arrow Indicator
                            widget.trailing ??
                                _buildTrailingIndicator(context, isSelected),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeadingIcon(BuildContext context, bool isSelected) {
    final size = widget.leadingSize;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Unselected circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.colors.outlineVariant,
                width: 1.2,
              ),
              color: context.colors.surfaceDim,
            ),
            padding: const EdgeInsets.all(AppSpacing.smd),
            child: widget.iconAssetPath != null
                ? AppImage.asset(
                    assetPath: widget.iconAssetPath!,
                    color: context.colors.onSurfaceVariant,
                  )
                : null,
          ),

          // Selected circle (fades smoothly in)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            opacity: isSelected ? 1.0 : 0.0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: context.colors.primaryGradient,
              ),
              padding: const EdgeInsets.all(1.2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.surfaceContainer,
                ),
                padding: const EdgeInsets.all(AppSpacing.smd),
                child: widget.iconAssetPath != null
                    ? AppImage.asset(
                        assetPath: widget.iconAssetPath!,
                        color: context.colors.primary,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingIndicator(BuildContext context, bool isSelected) {
    final size = widget.trailingSize;
    final iconSize = widget.trailingIconSize;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Unselected arrow
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.colors.outlineVariant,
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: iconSize,
              color: context.colors.onSurfaceVariant,
            ),
          ),

          // Selected arrow (fades smoothly in)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            opacity: isSelected ? 1.0 : 0.0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: context.colors.primaryGradient,
              ),
              padding: const EdgeInsets.all(1.2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.surfaceContainer,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: iconSize,
                  color: context.colors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
