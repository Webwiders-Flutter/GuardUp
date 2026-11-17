import 'package:guardup_admin/shared/models/selectable_item.model.dart';
import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import '/shared/controllers/selection.controller.dart';

/// Selection type mode for [AppRadio] widget: radio (circular) or checkbox (squared).
enum AppRadioType { radio, checkbox }

/// Size variants for [AppRadio], mirroring [ButtonSize] from [AppButton].
/// Controls typography scale, indicator size, touch padding, and spacing.
enum AppRadioSize { small, normal, medium, large }

/// Convenience alias for [AppRadioSize].
typedef RadioSize = AppRadioSize;

/// Resolved layout specification for an [AppRadioSize].
typedef _RadioSizeSpec = ({
  double indicatorScale,
  double titleFontSize,
  double subtitleFontSize,
  double gap,
  EdgeInsets padding,
});

/// Model representing an individual option in an [AppRadio] selection group.
class AppRadioOption<T> {
  final T value;
  final String label;
  final Widget? icon;
  final String? subtitle;
  final bool enabled;

  const AppRadioOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.enabled = true,
  });
}

/// Radio and checkbox selection group widget powered by Flutter's native
/// [Radio] and [Checkbox] controls for authentic Material states, animations,
/// hover splash rings, and keyboard accessibility, managed by a [SelectionController].
///
/// Supports responsive sizes ([AppRadioSize]), multi-line subtitles, dividers,
/// and horizontal/vertical orientations.
class AppRadio<T> extends StatelessWidget {
  final SelectionController<T> controller;
  final List<AppRadioOption<T>> optionsList;
  final AppRadioType type;
  final AppRadioSize size;
  final Axis direction;
  final bool isRow;
  final bool showDivider;
  final ValueChanged<T>? onChanged;
  final double spacing;
  final EdgeInsets? padding;

  const AppRadio({
    super.key,
    required this.controller,
    required this.optionsList,
    this.type = AppRadioType.radio,
    this.size = AppRadioSize.normal,
    this.direction = Axis.vertical,
    this.isRow = false,
    this.showDivider = false,
    this.onChanged,
    this.spacing = AppSpacing.md,
    this.padding,
  });

  /// Factory constructor to create [AppRadio] from a list of [SelectableItem<T, String>].
  factory AppRadio.fromItems({
    Key? key,
    required SelectionController<T> controller,
    required List<SelectableItem<T, String>> items,
    AppRadioType type = AppRadioType.radio,
    AppRadioSize size = AppRadioSize.normal,
    Axis direction = Axis.vertical,
    bool isRow = false,
    bool showDivider = false,
    ValueChanged<T>? onChanged,
    double spacing = AppSpacing.md,
    EdgeInsets? padding,
  }) {
    return AppRadio<T>(
      key: key,
      controller: controller,
      type: type,
      size: size,
      direction: direction,
      isRow: isRow,
      showDivider: showDivider,
      onChanged: onChanged,
      spacing: spacing,
      padding: padding,
      optionsList: items
          .map((item) => AppRadioOption<T>(value: item.id, label: item.data))
          .toList(),
    );
  }

  // ---------------------------------------------------------------------
  // Size config — add a new AppRadioSize by adding ONE entry here.
  // ---------------------------------------------------------------------
  static const Map<AppRadioSize, _RadioSizeSpec> _sizeSpecs = {
    AppRadioSize.small: (
      indicatorScale: 0.8,
      titleFontSize: AppSpacing.md - 1, // 11
      subtitleFontSize: AppSpacing.sm + 2, // 10
      gap: AppSpacing.xs, // 4
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs / 2,
      ),
    ),
    AppRadioSize.normal: (
      indicatorScale: 0.9,
      titleFontSize: AppSpacing.md + 1, // 13
      subtitleFontSize: AppSpacing.md - 1, // 11
      gap: AppSpacing.xs + 2, // 6
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: AppSpacing.xs,
      ),
    ),
    AppRadioSize.medium: (
      indicatorScale: 1.0,
      titleFontSize: AppSpacing.md + 2, // 14
      subtitleFontSize: AppSpacing.md, // 12
      gap: AppSpacing.sm, // 8
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
    ),
    AppRadioSize.large: (
      indicatorScale: 1.15,
      titleFontSize: AppSpacing.lg - 1, // 15
      subtitleFontSize: AppSpacing.md + 1, // 13
      gap: AppSpacing.md, // 12
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    ),
  };

  _RadioSizeSpec _resolveSize() =>
      _sizeSpecs[size] ?? _sizeSpecs[AppRadioSize.normal]!;

  @override
  Widget build(BuildContext context) {
    final sizeSpec = _resolveSize();

    return ValueListenableBuilder<List<T>>(
      valueListenable: controller,
      builder: (context, selectedValues, _) {
        final children = optionsList.map((option) {
          final isSelected = controller.isSelected(option.value);
          return _buildOptionTile(context, option, isSelected, sizeSpec);
        }).toList();

        final useRowLayout = isRow || direction == Axis.horizontal;

        Widget content;
        if (useRowLayout) {
          content = Padding(
            padding: padding ?? EdgeInsets.zero,
            child: Wrap(
              spacing: spacing,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: children,
            ),
          );
        } else {
          content = Padding(
            padding: padding ?? EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) ...[
                    if (showDivider)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Divider(
                          height: 1,
                          color: context.colors.borderLight.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      )
                    else
                      spacing.h,
                  ],
                  children[i],
                ],
              ],
            ),
          );
        }

        if (type == AppRadioType.radio) {
          return RadioGroup<T>(
            groupValue: selectedValues.firstOrNull,
            onChanged: (val) {
              if (val != null) {
                controller.toggle(val);
                onChanged?.call(val);
              }
            },
            child: content,
          );
        }

        return content;
      },
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    AppRadioOption<T> option,
    bool isSelected,
    _RadioSizeSpec sizeSpec,
  ) {
    final colors = context.colors;
    final useRowLayout = isRow || direction == Axis.horizontal;
    final isRadio = type == AppRadioType.radio;

    final titleStyle =
        (option.subtitle != null
                ? (context.textTheme.bodyMedium ?? const TextStyle()).semiBold()
                : (context.textTheme.bodySmall ?? const TextStyle()).medium())
            .size(sizeSpec.titleFontSize)
            .colour(
              option.enabled ? colors.onSurface : colors.onSurfaceSecondary,
            );

    final subtitleStyle = (context.textTheme.bodySmall ?? const TextStyle())
        .size(sizeSpec.subtitleFontSize)
        .colour(colors.onSurfaceSecondary);

    final Widget textContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(option.label, style: titleStyle),
        if (option.subtitle != null) ...[
          2.h,
          Text(option.subtitle!, style: subtitleStyle),
        ],
      ],
    );

    final Widget control = isRadio
        ? Radio<T>(
            value: option.value,
            enabled: option.enabled,
            activeColor: colors.secondary,
            hoverColor: colors.secondary.withValues(alpha: 0.08),
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return colors.borderLight;
              }
              if (states.contains(WidgetState.selected)) {
                return colors.secondary;
              }
              if (states.contains(WidgetState.hovered)) {
                return colors.secondary;
              }
              return colors.borderLight;
            }),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(
              horizontal: VisualDensity.minimumDensity,
              vertical: VisualDensity.minimumDensity,
            ),
          )
        : Checkbox(
            value: isSelected,
            onChanged: option.enabled
                ? (_) {
                    controller.toggle(option.value);
                    onChanged?.call(option.value);
                  }
                : null,
            activeColor: colors.secondary,
            hoverColor: colors.secondary.withValues(alpha: 0.08),
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return colors.borderLight;
              }
              if (states.contains(WidgetState.selected)) {
                return colors.secondary;
              }
              if (states.contains(WidgetState.hovered)) {
                return colors.secondary;
              }
              return colors.borderLight;
            }),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(
              horizontal: VisualDensity.minimumDensity,
              vertical: VisualDensity.minimumDensity,
            ),
          );

    final scaledControl = Transform.scale(
      scale: sizeSpec.indicatorScale,
      alignment: Alignment.center,
      child: control,
    );

    final controlWidget = option.subtitle != null
        ? Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: scaledControl,
          )
        : scaledControl;

    return MouseRegion(
      cursor: option.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: InkWell(
        onTap: option.enabled
            ? () {
                controller.toggle(option.value);
                onChanged?.call(option.value);
              }
            : null,
        borderRadius: AppRadius.smRadius,
        hoverColor: colors.secondary.withValues(alpha: 0.04),
        splashColor: colors.secondary.withValues(alpha: 0.08),
        highlightColor: colors.secondary.withValues(alpha: 0.04),
        child: Padding(
          padding: padding ?? sizeSpec.padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: option.subtitle != null
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              controlWidget,
              sizeSpec.gap.w,
              if (option.icon != null) ...[option.icon!, AppSpacing.sm.w],

              if (useRowLayout) textContent else Expanded(child: textContent),
            ],
          ),
        ),
      ),
    );
  }
}
