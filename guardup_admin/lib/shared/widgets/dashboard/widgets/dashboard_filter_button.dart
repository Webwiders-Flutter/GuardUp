import 'dart:math' as math;

import 'package:flutter/material.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_layout.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/menu.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '../../misc/app_hover_builder.dart';

/// One option in a [DashboardFilterButton] menu.
typedef DashboardFilterEntry<T> = ({
  T value,
  String label,
  IconData? icon,
  bool isSelected,

  /// Draws a divider above this entry (e.g. before "Custom range…").
  bool dividerBefore,
});

/// Compact filter pill used in dashboard card headers (status, date range).
///
/// Shows an optional [icon], a muted [prefix] and the current [label]; the
/// chevron flips while the menu is open. The menu lists [entries] with a
/// check mark on the selected one and an optional [menuTitle]. Tints with
/// the primary color when [isActive] (a non-default value is applied).
class DashboardFilterButton<T> extends StatefulWidget {
  const DashboardFilterButton({
    super.key,
    required this.label,
    required this.entries,
    required this.onSelected,
    this.prefix,
    this.icon,
    this.menuTitle,
    this.tooltip,
    this.isActive = false,
    this.maxLabelWidth = 140,
  });

  final String label;
  final List<DashboardFilterEntry<T>> entries;
  final ValueChanged<T> onSelected;
  final String? prefix;
  final IconData? icon;
  final String? menuTitle;
  final String? tooltip;
  final bool isActive;
  final double maxLabelWidth;

  @override
  State<DashboardFilterButton<T>> createState() =>
      _DashboardFilterButtonState<T>();
}

class _DashboardFilterButtonState<T> extends State<DashboardFilterButton<T>> {
  final ValueNotifier<bool> _isOpenNotifier = ValueNotifier<bool>(false);

  /// Menu items need room for the check mark even when the pill is narrow.
  static const double _minMenuWidth = 200;

  @override
  void dispose() {
    _isOpenNotifier.dispose();
    super.dispose();
  }

  Future<void> _open(BuildContext anchor) async {
    final anchorWidth = (anchor.findRenderObject()! as RenderBox).size.width;
    _isOpenNotifier.value = true;

    // Menu values are indices so nullable option values (e.g. "All") stay
    // distinguishable from a dismissed menu.
    final index = await anchor.showAnchoredMenu<int>(
      gap: AppSpacing.xs + 2,
      constraints: BoxConstraints(
        minWidth: math.max(anchorWidth, _minMenuWidth),
      ),
      items: [
        if (widget.menuTitle != null) ...[
          PopupMenuItem<int>(
            enabled: false,
            height: AppLayout.controlHeightSm,
            child: Text(
              widget.menuTitle!.toUpperCase(),
              style: anchor.textTheme.labelSmall
                  ?.bold()
                  .textSpacing(0.8)
                  .colour(anchor.colors.onSurfaceSecondary),
            ),
          ),
        ],
        for (final (i, entry) in widget.entries.indexed) ...[
          if (entry.dividerBefore) const PopupMenuDivider(height: 1),
          PopupMenuItem<int>(
            value: i,
            height: AppLayout.menuItemHeight,
            child: _MenuRow(entry: entry),
          ),
        ],
      ],
    );

    if (!mounted) return;
    _isOpenNotifier.value = false;
    if (index != null) widget.onSelected(widget.entries[index].value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isActive = widget.isActive;
    final accent = colors.primary;

    final button = Builder(
      builder: (anchor) => AppHoverBuilder(
        cursor: SystemMouseCursors.click,
        builder: (context, isHovered, _) => ValueListenableBuilder<bool>(
          valueListenable: _isOpenNotifier,
          builder: (context, isOpen, _) {
            final highlighted = isHovered || isOpen;
            final Color fill = isActive
                ? accent.withValues(alpha: 0.08)
                : highlighted
                ? colors.surfaceMuted
                : colors.surface;
            final Color border = isActive || isOpen
                ? accent.withValues(alpha: 0.45)
                : colors.borderLight;
            final Color foreground = isActive ? accent : colors.onSurface;

            return GestureDetector(
              onTap: () => _open(anchor),
              child: AnimatedContainer(
                duration: AppDurations.instant,
                height: AppLayout.controlHeightSm,
                padding: const EdgeInsets.only(
                  left: AppSpacing.sm + 2,
                  right: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(color: border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: AppLayout.iconXs,
                        color: isActive ? accent : colors.onSurfaceSecondary,
                      ),
                      (AppSpacing.xs + 2).w,
                    ],
                    if (widget.prefix != null) ...[
                      Text(
                        widget.prefix!,
                        style: context.textTheme.labelMedium?.medium().colour(
                          colors.onSurfaceSecondary,
                        ),
                      ),
                      AppSpacing.xs.w,
                    ],
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: widget.maxLabelWidth,
                      ),
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelMedium?.semiBold().colour(
                          foreground,
                        ),
                      ),
                    ),
                    AppSpacing.xs.w,
                    AnimatedRotation(
                      turns: isOpen ? 0.5 : 0,
                      duration: AppDurations.fast,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: AppLayout.iconSm,
                        color: isActive ? accent : colors.onSurfaceSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(
      message: widget.tooltip!,
      waitDuration: AppDurations.slow,
      child: button,
    );
  }
}

class _MenuRow<T> extends StatelessWidget {
  const _MenuRow({required this.entry});

  final DashboardFilterEntry<T> entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isSelected = entry.isSelected;

    return Row(
      children: [
        if (entry.icon != null) ...[
          Icon(
            entry.icon,
            size: AppLayout.iconSm,
            color: isSelected ? colors.primary : colors.onSurfaceSecondary,
          ),
          AppSpacing.sm.w,
        ],
        Expanded(
          child: Text(
            entry.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (isSelected
                        ? context.textTheme.bodyMedium?.semiBold()
                        : context.textTheme.bodyMedium?.medium())
                    ?.colour(isSelected ? colors.primary : colors.onSurface),
          ),
        ),
        AppSpacing.md.w,
        AnimatedOpacity(
          duration: AppDurations.instant,
          opacity: isSelected ? 1 : 0,
          child: Icon(
            Icons.check_rounded,
            size: AppLayout.iconSm,
            color: colors.primary,
          ),
        ),
      ],
    );
  }
}
