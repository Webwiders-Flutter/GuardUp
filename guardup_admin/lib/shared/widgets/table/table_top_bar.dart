import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';

/// Top-bar of [AdminTableBuilder] containing the table title, record count,
/// search field, refresh button, and custom actions.
///
/// Switches seamlessly to a selection-mode bar when [selectedCount] > 0.
/// The display-limit (rows-per-page) selector has been relocated to [TableFooter].
class TableTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showSearchField;
  final TextEditingController searchController;

  // Keep the notifier param so the API stays backward-compatible,
  // but the pill itself is now rendered in the footer.
  final ValueNotifier<int> limitNotifier;
  final void Function(dynamic)? onSearch;
  final ValueChanged<int>? onLimitChange;
  final Future<void> Function()? onRefresh;
  final List<Widget> actions;

  // Selection props
  final int selectedCount;
  final List<Widget> selectionActions;
  final VoidCallback onClearSelection;
  final bool showSelectionToggle;
  final bool isSelectionModeActive;
  final VoidCallback? onToggleSelectionMode;

  const TableTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchController,
    required this.limitNotifier,
    this.onSearch,
    this.onLimitChange,
    this.showSearchField = false,
    this.onRefresh,
    required this.actions,
    required this.selectedCount,
    required this.selectionActions,
    required this.onClearSelection,
    this.showSelectionToggle = false,
    this.isSelectionModeActive = false,
    this.onToggleSelectionMode,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelectionMode = selectedCount > 0;
    final accentDimColor = context.colors.secondary.withValues(alpha: 0.08);
    final surfaceColor = context.colors.surface;
    final borderColor = context.colors.borderLight.withValues(alpha: 0.6);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md + 2,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        color: isSelectionMode ? accentDimColor : surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isSelectionMode
            ? _buildSelectionMode(context)
            : _buildNormalMode(context),
      ),
    );
  }

  Widget _buildNormalMode(BuildContext context) {
    final textColor = context.colors.onSurface;
    final mutedColor = context.colors.onSurfaceSecondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        if (isMobile) {
          return Column(
            key: const ValueKey('normal_mobile'),
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title + subtitle row
              if (title.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: context.textTheme.titleMedium?.bold().colour(
                              textColor,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            (AppSpacing.xs / 2).h,
                            Text(
                              subtitle,
                              style: context.textTheme.bodySmall
                                  ?.size(AppSpacing.md)
                                  .colour(mutedColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showSelectionToggle) ...[
                      GhostIconButton(
                        icon: Icons.checklist_rounded,
                        tooltip: isSelectionModeActive
                            ? 'Exit selection'
                            : 'Select items',
                        isActive: isSelectionModeActive,
                        onTap: onToggleSelectionMode ?? () {},
                      ),
                      (AppSpacing.xs + 2).w,
                    ],
                    if (onRefresh != null)
                      GhostIconButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Refresh',
                        onTap: onRefresh!,
                      ),
                    ...actions.map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xs + 2),
                        child: a,
                      ),
                    ),
                  ],
                ),
              if (showSearchField) ...[
                AppSpacing.md.h,
                _SearchField(
                  controller: searchController,
                  onChanged: onSearch,
                  fullWidth: true,
                ),
              ],
            ],
          );
        }

        // Desktop / tablet layout
        return Row(
          key: const ValueKey('normal_desktop'),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: title + subtitle
            if (title.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium
                          ?.bold()
                          .colour(textColor)
                          .copyWith(letterSpacing: -0.2),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      (AppSpacing.xs / 2).h,
                      Text(
                        subtitle,
                        style: context.textTheme.bodySmall
                            ?.size(AppSpacing.md)
                            .colour(mutedColor),
                      ),
                    ],
                  ],
                ),
              )
            else
              const Spacer(),

            // Right: search, refresh, actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSelectionToggle) ...[
                  GhostIconButton(
                    icon: Icons.checklist_rounded,
                    tooltip: isSelectionModeActive
                        ? 'Exit selection mode'
                        : 'Select items',
                    isActive: isSelectionModeActive,
                    onTap: onToggleSelectionMode ?? () {},
                  ),
                  AppSpacing.sm.w,
                ],
                if (showSearchField)
                  _SearchField(
                    controller: searchController,
                    onChanged: onSearch,
                    fullWidth: false,
                  ),
                if (showSearchField) AppSpacing.sm.w,
                if (onRefresh != null) ...[
                  GhostIconButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Refresh data',
                    onTap: onRefresh!,
                  ),
                  AppSpacing.sm.w,
                ],
                ...actions.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs + 2),
                    child: a,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectionMode(BuildContext context) {
    final accentColor = context.colors.secondary;

    return Row(
      key: const ValueKey('selection_mode'),
      children: [
        InkWell(
          onTap: onClearSelection,
          borderRadius: AppRadius.roundRadius,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.close_rounded,
              color: accentColor,
              size: AppSpacing.lg,
            ),
          ),
        ),
        AppSpacing.md.w,
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: AppRadius.roundRadius,
          ),
          child: Text(
            '$selectedCount selected',
            style: context.textTheme.labelSmall?.bold().colour(
              context.colors.onPrimary,
            ),
          ),
        ),
        const Spacer(),
        ...selectionActions.map(
          (a) => Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: a,
          ),
        ),
      ],
    );
  }
}

// ─── Search Field With Clear Button ───────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(dynamic)? onChanged;
  final bool fullWidth;

  const _SearchField({
    required this.controller,
    this.onChanged,
    required this.fullWidth,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = context.colors.onSurface;
    final mutedColor = context.colors.onSurfaceSecondary;
    final accentColor = context.colors.secondary;
    final borderColor = context.colors.borderLight.withValues(alpha: 0.6);
    final fieldHeight = AppSpacing.md * 3;

    final field = SizedBox(
      height: fieldHeight,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return TextField(
            controller: controller,
            onChanged: onChanged,
            style: context.textTheme.bodySmall
                ?.size(AppSpacing.md + 1)
                .colour(textColor),
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: context.textTheme.bodySmall
                  ?.size(AppSpacing.md + 1)
                  .colour(mutedColor),
              prefixIcon: Icon(
                CupertinoIcons.search,
                color: mutedColor,
                size: AppSpacing.lg,
              ),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        size: AppSpacing.lg,
                        color: mutedColor,
                      ),
                      onPressed: () {
                        controller.clear();
                        onChanged?.call('');
                      },
                      tooltip: 'Clear search',
                    )
                  : null,
              filled: true,
              fillColor: context.colors.backgroundLight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.mdRadius,
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.mdRadius,
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          );
        },
      ),
    );

    if (fullWidth) return field;
    return SizedBox(width: (AppSpacing.xxxl * 7) + AppSpacing.lg, child: field);
  }
}

// ─── Ghost Icon Button ────────────────────────────────────────────────────────

/// Bordered icon-only button with hover feedback.
class GhostIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool isActive;
  final Color? activeColor;

  const GhostIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? context.colors.secondary;
    final borderColor = isActive
        ? color.withValues(alpha: 0.45)
        : context.colors.borderLight.withValues(alpha: 0.6);
    final bgColor = isActive
        ? color.withValues(alpha: 0.12)
        : context.colors.backgroundLight;
    final iconColor = isActive ? color : context.colors.onSurface;

    final btn = Material(
      color: bgColor,
      borderRadius: AppRadius.mdRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdRadius,
        child: Container(
          width: AppSpacing.md * 3,
          height: AppSpacing.md * 3,
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, size: AppSpacing.lg + 2, color: iconColor),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}
