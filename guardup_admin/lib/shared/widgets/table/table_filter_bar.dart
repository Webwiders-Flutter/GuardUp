import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_layout.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import 'table_models.dart';

/// Complete, modular filtering component for [AdminTableBuilder].
///
/// Supports:
/// - Category/status tab chips with active highlight
/// - Active cancellable/dismissible filters with cross (`✕`) icon
/// - "Clear all" action when multiple active filters are applied
/// - Selection mode toggle chip (at start or end of the row)
class TableFilterChipBar extends StatelessWidget {
  /// Category/status filter chips (e.g. [All, Pending, In Transit, Delivered]).
  final List<TableFilterChip> chips;

  /// Currently active value among [chips].
  final dynamic active;

  /// Callback when a category chip is tapped.
  final void Function(dynamic)? onTap;

  /// Active secondary or contextual filters that can be dismissed individually (e.g. Order ID, Driver, Transporter).
  final List<TableRemovableFilter> activeFilters;

  /// Optional callback to clear all active removable filters at once.
  final VoidCallback? onClearAllFilters;

  /// Whether to display the multi-select toggle trigger in this bar.
  final bool showSelectionToggle;

  /// Whether table multi-selection mode is currently active.
  final bool isSelectionModeActive;

  /// Callback when user clicks the multi-select toggle trigger.
  final VoidCallback? onToggleSelectionMode;

  /// Number of currently selected items across the table.
  final int selectedCount;

  /// Determines if the selection toggle chip is placed at the start or end of the row.
  final SelectionTogglePosition togglePosition;

  /// Maximum number of category chips displayed inline before collapsing overflow into a "+N" popup.
  /// Defaults to 5.
  final int maxVisibleChips;

  /// Maximum number of active removable filter badges displayed inline before collapsing overflow into a "+N" popup.
  /// Defaults to 5.
  final int maxVisibleRemovableFilters;

  const TableFilterChipBar({
    super.key,
    this.chips = const [],
    this.active,
    this.onTap,
    this.activeFilters = const [],
    this.onClearAllFilters,
    this.maxVisibleChips = 5,
    this.maxVisibleRemovableFilters = 5,
    this.showSelectionToggle = false,
    this.isSelectionModeActive = false,
    this.onToggleSelectionMode,
    this.selectedCount = 0,
    this.togglePosition = SelectionTogglePosition.start,
  });

  /// Resolves the visible chips ensuring that the currently applied active filter is brought to the front.
  static List<TableFilterChip> _resolveVisibleChips(
    List<TableFilterChip> allChips,
    dynamic active,
    int maxVisible,
  ) {
    if (allChips.length <= maxVisible) return allChips;

    final activeIndex = allChips.indexWhere((c) => c.value == active);

    // If active is not found, or is already within the visible bracket (< maxVisible),
    // preserve the natural chip order without moving it to the front.
    if (activeIndex < maxVisible) {
      return allChips.take(maxVisible).toList();
    }

    // Active filter is in the overflow (+N) bracket (activeIndex >= maxVisible).
    // Bring it forward into the visible chips.
    final hasAllFirst = allChips.first.value == null;
    if (hasAllFirst) {
      // Keep 'All' at index 0, place the active chip at index 1:
      final result = <TableFilterChip>[allChips[0], allChips[activeIndex]];
      for (int i = 1; i < allChips.length && result.length < maxVisible; i++) {
        if (i != activeIndex) {
          result.add(allChips[i]);
        }
      }
      return result;
    } else {
      // Place the active chip at index 0:
      final result = <TableFilterChip>[allChips[activeIndex]];
      for (int i = 0; i < allChips.length && result.length < maxVisible; i++) {
        if (i != activeIndex) {
          result.add(allChips[i]);
        }
      }
      return result;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentDimColor = colors.primary.withValues(alpha: 0.12);
    final accentColor = colors.primary;
    final borderColor = colors.borderLight;
    final mutedColor = colors.onSurfaceSecondary;

    final shouldShowToggle =
        showSelectionToggle && togglePosition != SelectionTogglePosition.topBar;
    final hasCategoryRow = chips.isNotEmpty || shouldShowToggle;
    final hasActiveFiltersRow = activeFilters.isNotEmpty;

    if (!hasCategoryRow && !hasActiveFiltersRow) {
      return const SizedBox.shrink();
    }

    Widget buildSelectionToggleChip() {
      return _SelectionToggleChip(
        isActive: isSelectionModeActive,
        selectedCount: selectedCount,
        onTap: onToggleSelectionMode,
      );
    }

    Widget buildSeparator() {
      return Container(
        width: 1,
        height: AppSpacing.xl,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        color: borderColor,
      );
    }

    final visibleChips = _resolveVisibleChips(chips, active, maxVisibleChips);
    final hasChipsOverflow = chips.length > maxVisibleChips;
    final chipsOverflowCount = chips.length - visibleChips.length;

    final chipWidgets = List.generate(visibleChips.length, (i) {
      final chip = visibleChips[i];
      final isActive = active == chip.value;
      return Material(
        color: isActive ? accentDimColor : colors.surface,
        borderRadius: AppRadius.xlRadius,
        child: InkWell(
          onTap: () => onTap?.call(chip.value),
          borderRadius: AppRadius.xlRadius,
          child: QuickContainer(
            px: AppSpacing.md + 2,
            py: AppSpacing.sm - 2,
            radius: AppRadius.xl,
            border: Border.all(color: isActive ? accentColor : borderColor),
            child: Text(
              chip.label,
              style: context.textTheme.labelSmall
                  ?.size(AppSpacing.md - 1)
                  .semiBold()
                  .colour(isActive ? accentColor : mutedColor),
            ),
          ),
        ),
      );
    });

    final wrapChildren = <Widget>[];

    if (shouldShowToggle && togglePosition == SelectionTogglePosition.start) {
      wrapChildren.add(buildSelectionToggleChip());
      if (chips.isNotEmpty) {
        wrapChildren.add(buildSeparator());
      }
    }

    wrapChildren.addAll(chipWidgets);

    if (hasChipsOverflow) {
      wrapChildren.add(
        _OverflowFilterChipsButton(
          overflowCount: chipsOverflowCount,
          allChips: chips,
          active: active,
          onTap: onTap,
        ),
      );
    }

    if (shouldShowToggle && togglePosition == SelectionTogglePosition.end) {
      if (chips.isNotEmpty) {
        wrapChildren.add(buildSeparator());
      }
      wrapChildren.add(buildSelectionToggleChip());
    }

    final hasRemovableOverflow =
        activeFilters.length > maxVisibleRemovableFilters;
    final visibleRemovable = hasRemovableOverflow
        ? activeFilters.take(maxVisibleRemovableFilters).toList()
        : activeFilters;
    final removableOverflowCount =
        activeFilters.length - visibleRemovable.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Category / Status Chips Row ───────────────────────────
          if (hasCategoryRow)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: wrapChildren,
            ),

          // ── Subtle divider between category tabs and active filters
          if (hasCategoryRow && hasActiveFiltersRow) ...[
            AppSpacing.sm.h,
            Divider(height: 1, color: borderColor.withValues(alpha: 0.6)),
            AppSpacing.sm.h,
          ],

          // ── Removable Active Filters Row ──────────────────────────
          if (hasActiveFiltersRow)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt_outlined,
                      size: AppLayout.iconXs,
                      color: mutedColor,
                    ),
                    (AppSpacing.xs + 1).w,
                    Text(
                      'Active:',
                      style: context.textTheme.labelSmall
                          ?.size(AppSpacing.md - 1)
                          .medium()
                          .colour(mutedColor),
                    ),
                    AppSpacing.sm.w,
                  ],
                ),
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...visibleRemovable.map(
                        (filter) => _RemovableFilterBadge(filter: filter),
                      ),
                      if (hasRemovableOverflow)
                        _OverflowRemovableFiltersButton(
                          overflowCount: removableOverflowCount,
                          allFilters: activeFilters,
                          onClearAll: onClearAllFilters,
                        ),
                      if (activeFilters.length > 1 && onClearAllFilters != null)
                        _ClearAllFiltersButton(onClear: onClearAllFilters!),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A stylish badge for an active, cancellable filter.
class _RemovableFilterBadge extends StatelessWidget {
  final TableRemovableFilter filter;

  const _RemovableFilterBadge({required this.filter});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      borderRadius: AppRadius.xlRadius,
      child: Container(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.xs + 2,
          top: AppSpacing.xs,
          bottom: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.08),
          borderRadius: AppRadius.xlRadius,
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (filter.icon != null) ...[
              Icon(filter.icon, size: AppSpacing.md - 1, color: colors.primary),
              (AppSpacing.xs + 1).w,
            ],
            Text(
              filter.label,
              style: context.textTheme.labelSmall
                  ?.size(AppSpacing.md - 1)
                  .semiBold()
                  .colour(colors.primary),
            ),
            (AppSpacing.xs + 2).w,
            Tooltip(
              message: 'Remove filter',
              child: InkWell(
                onTap: filter.onRemove,
                borderRadius: AppRadius.fullRadius,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: AppLayout.iconXs - 1,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact button to clear all active filters at once.
class _ClearAllFiltersButton extends StatelessWidget {
  final VoidCallback onClear;

  const _ClearAllFiltersButton({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Tooltip(
      message: 'Clear all active filters',
      child: Material(
        color: colors.surface,
        borderRadius: AppRadius.xlRadius,
        child: InkWell(
          onTap: onClear,
          borderRadius: AppRadius.xlRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md - 2,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.06),
              borderRadius: AppRadius.xlRadius,
              border: Border.all(
                color: colors.error.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_alt_off_outlined,
                  size: AppLayout.iconXs - 1,
                  color: colors.error,
                ),
                AppSpacing.xs.w,
                Text(
                  'Clear all',
                  style: context.textTheme.labelSmall
                      ?.size(AppSpacing.md - 1)
                      .semiBold()
                      .colour(colors.error),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionToggleChip extends StatelessWidget {
  final bool isActive;
  final int selectedCount;
  final VoidCallback? onTap;

  const _SelectionToggleChip({
    required this.isActive,
    required this.selectedCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentDimColor = context.colors.primary.withValues(alpha: 0.12);
    final accentColor = context.colors.primary;
    final borderColor = context.colors.borderLight;
    final mutedColor = context.colors.onSurfaceSecondary;

    return Tooltip(
      message: isActive ? 'Exit multi-select mode' : 'Select multiple items',
      child: Material(
        color: isActive ? accentDimColor : context.colors.surface,
        borderRadius: AppRadius.xlRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.xlRadius,
          child: QuickContainer(
            px: AppSpacing.md + 1,
            py: AppSpacing.sm - 2,
            radius: AppRadius.xl,
            border: Border.all(
              color: isActive ? accentColor : borderColor,
              width: isActive ? 1.2 : 1.0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: AppLayout.iconXs,
                  color: isActive ? accentColor : mutedColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A button that displays the "+N" overflow chip and opens a popup menu with all filter chips.
class _OverflowFilterChipsButton extends StatelessWidget {
  final int overflowCount;
  final List<TableFilterChip> allChips;
  final dynamic active;
  final void Function(dynamic)? onTap;

  const _OverflowFilterChipsButton({
    required this.overflowCount,
    required this.allChips,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderColor = colors.borderLight;
    final mutedColor = colors.onSurfaceSecondary;
    final accentColor = colors.primary;
    final accentDimColor = colors.primary.withValues(alpha: 0.12);

    return PopupMenuButton<int>(
      tooltip: 'More filters ($overflowCount)',
      offset: const Offset(0, 36),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdRadius,
        side: BorderSide(color: borderColor),
      ),
      color: colors.surface,
      onSelected: (int index) {
        if (index >= 0 && index < allChips.length) {
          onTap?.call(allChips[index].value);
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<int>(
            enabled: false,
            height: AppLayout.controlHeightSm - AppSpacing.xs,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'ALL FILTERS (${allChips.length})',
              style: context.textTheme.labelSmall
                  ?.size(AppSpacing.sm + 2)
                  .bold()
                  .colour(mutedColor),
            ),
          ),
          ...List.generate(allChips.length, (index) {
            final chip = allChips[index];
            final isSelected = active == chip.value;
            return PopupMenuItem<int>(
              value: index,
              height: AppSpacing.xxl + 4,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs + 2,
                vertical: 2,
              ),
              child: QuickContainer(
                px: AppSpacing.md,
                py: AppSpacing.sm - 2,
                radius: AppRadius.sm,
                color: isSelected ? accentDimColor : colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        chip.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium
                            ?.colour(
                              isSelected ? accentColor : colors.onSurface,
                            )
                            .weight(
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                      ),
                    ),
                    if (isSelected) ...[
                      AppSpacing.sm.w,
                      Icon(
                        Icons.check_rounded,
                        size: AppLayout.iconSm,
                        color: accentColor,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ];
      },
      child: Material(
        color: colors.surface,
        borderRadius: AppRadius.xlRadius,
        child: QuickContainer(
          px: AppSpacing.md,
          py: AppSpacing.sm - 2,
          radius: AppRadius.xl,
          border: Border.all(color: borderColor),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+$overflowCount',
                style: context.textTheme.labelSmall
                    ?.size(AppSpacing.md - 1)
                    .semiBold()
                    .colour(mutedColor),
              ),
              (2).w,
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: AppLayout.iconSm,
                color: mutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A button that displays the "+N more" overflow badge for active removable filters.
class _OverflowRemovableFiltersButton extends StatelessWidget {
  final int overflowCount;
  final List<TableRemovableFilter> allFilters;
  final VoidCallback? onClearAll;

  const _OverflowRemovableFiltersButton({
    required this.overflowCount,
    required this.allFilters,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderColor = colors.borderLight;
    final mutedColor = colors.onSurfaceSecondary;
    final accentColor = colors.primary;
    final accentDimColor = colors.primary.withValues(alpha: 0.08);

    return PopupMenuButton<int>(
      tooltip: 'More active filters ($overflowCount)',
      offset: const Offset(0, 36),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdRadius,
        side: BorderSide(color: borderColor),
      ),
      color: colors.surface,
      onSelected: (int index) {
        if (index == -1) {
          onClearAll?.call();
        } else if (index >= 0 && index < allFilters.length) {
          allFilters[index].onRemove();
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<int>(
            enabled: false,
            height: AppLayout.controlHeightSm - AppSpacing.xs,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'ACTIVE FILTERS (${allFilters.length})',
              style: context.textTheme.labelSmall
                  ?.size(AppSpacing.sm + 2)
                  .bold()
                  .colour(mutedColor),
            ),
          ),
          ...List.generate(allFilters.length, (index) {
            final filter = allFilters[index];
            return PopupMenuItem<int>(
              value: index,
              height: AppSpacing.xxl + 4,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs + 2,
                vertical: 2,
              ),
              child: QuickContainer(
                px: AppSpacing.md,
                py: AppSpacing.sm - 2,
                radius: AppRadius.sm,
                color: accentDimColor,
                border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                child: Row(
                  children: [
                    if (filter.icon != null) ...[
                      Icon(
                        filter.icon,
                        size: AppLayout.iconXs,
                        color: accentColor,
                      ),
                      AppSpacing.xs.w,
                    ],
                    Expanded(
                      child: Text(
                        filter.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium
                            ?.colour(accentColor)
                            .semiBold(),
                      ),
                    ),
                    AppSpacing.sm.w,
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withValues(alpha: 0.14),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: AppLayout.iconXs - 1,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (allFilters.length > 1 && onClearAll != null) ...[
            const PopupMenuDivider(height: 1),
            PopupMenuItem<int>(
              value: -1,
              height: AppSpacing.xxl,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt_off_outlined,
                    size: AppLayout.iconXs,
                    color: colors.error,
                  ),
                  AppSpacing.xs.w,
                  Text(
                    'Clear all active filters',
                    style: context.textTheme.labelSmall
                        ?.size(AppSpacing.md - 1)
                        .semiBold()
                        .colour(colors.error),
                  ),
                ],
              ),
            ),
          ],
        ];
      },
      child: Material(
        color: colors.surface,
        borderRadius: AppRadius.xlRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: AppRadius.xlRadius,
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_alt_outlined,
                size: AppLayout.iconXs - 1,
                color: colors.primary,
              ),
              (AppSpacing.xs).w,
              Text(
                '+$overflowCount more',
                style: context.textTheme.labelSmall
                    ?.size(AppSpacing.md - 1)
                    .semiBold()
                    .colour(colors.primary),
              ),
              2.w,
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: AppLayout.iconXs,
                color: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
