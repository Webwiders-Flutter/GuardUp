import 'package:flutter/material.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_layout.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import '../buttons/app_icon_button.dart';

/// Header of [AdminTableBuilder]: title, record count, search, refresh and
/// custom [actions]. Switches to a tinted selection bar with
/// [selectionActions] while rows are selected.
class TableTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showSearchField;
  final TextEditingController searchController;

  /// Kept for API compatibility; the page-size selector lives in the footer.
  final ValueNotifier<int> limitNotifier;
  final void Function(dynamic)? onSearch;
  final ValueChanged<int>? onLimitChange;
  final Future<void> Function()? onRefresh;
  final List<Widget> actions;

  // Selection
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
    final colors = context.colors;
    final isSelecting = selectedCount > 0;

    return AnimatedContainer(
      duration: AppDurations.fast,
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md + 2,
      ),
      decoration: BoxDecoration(
        color: isSelecting
            ? colors.primary.withValues(alpha: 0.06)
            : colors.surface,
        border: Border(bottom: BorderSide(color: colors.borderLight)),
      ),
      child: AnimatedSwitcher(
        duration: AppDurations.fast,
        child: isSelecting
            ? _buildSelectionBar(context)
            : LayoutBuilder(
                key: const ValueKey('default'),
                builder: (context, constraints) => _buildDefaultBar(
                  context,
                  isNarrow:
                      constraints.maxWidth < AppLayout.tableCardBreakpoint,
                ),
              ),
      ),
    );
  }

  List<Widget> _buildTools() {
    return [
      if (showSelectionToggle)
        AppIconButton(
          icon: Icons.checklist_rounded,
          tooltip: isSelectionModeActive ? 'Exit selection' : 'Select rows',
          isActive: isSelectionModeActive,
          onPressed: onToggleSelectionMode,
        ),
      if (onRefresh != null)
        AppIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Refresh',
          onPressed: onRefresh,
        ),
      ...actions,
    ];
  }

  Widget _buildDefaultBar(BuildContext context, {required bool isNarrow}) {
    final heading = _Heading(title: title, subtitle: subtitle);
    final tools = _buildTools();

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: heading),
              for (final tool in tools) ...[AppSpacing.sm.w, tool],
            ],
          ),
          if (showSearchField) ...[
            AppSpacing.md.h,
            _SearchField(controller: searchController, onChanged: onSearch),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: heading),
        if (showSearchField) ...[
          AppSpacing.lg.w,
          SizedBox(
            width: AppLayout.tableSearchWidth,
            child: _SearchField(
              controller: searchController,
              onChanged: onSearch,
            ),
          ),
        ],
        for (final tool in tools) ...[AppSpacing.sm.w, tool],
      ],
    );
  }

  Widget _buildSelectionBar(BuildContext context) {
    final colors = context.colors;

    return Row(
      key: const ValueKey('selection'),
      children: [
        AppIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Clear selection',
          variant: AppIconButtonVariant.ghost,
          onPressed: onClearSelection,
        ),
        AppSpacing.sm.w,
        Text(
          '$selectedCount selected',
          style: context.textTheme.titleSmall?.semiBold().colour(
            colors.onSurface,
          ),
        ),
        const Spacer(),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: selectionActions,
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (title.isEmpty && subtitle.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleMedium
                ?.bold()
                .textSpacing(-0.2)
                .colour(colors.onSurface),
          ),
        if (subtitle.isNotEmpty) ...[
          (AppSpacing.xs / 2).h,
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall?.colour(
              colors.onSurfaceSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Search field ────────────────────────────────────────────────────────────

/// Compact search input with an inline clear button. The clear button
/// listens to the controller, so typing never rebuilds the top bar.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, this.onChanged});

  final TextEditingController controller;
  final void Function(dynamic)? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyle = context.textTheme.bodySmall?.size(AppSpacing.md + 1);

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    return SizedBox(
      height: AppLayout.controlHeight,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: textStyle?.colour(colors.onSurface),
        decoration: InputDecoration(
          hintText: 'Search…',
          hintStyle: textStyle?.colour(colors.onSurfaceSecondary),
          isDense: true,
          filled: true,
          fillColor: colors.surfaceMuted,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: AppLayout.iconSm,
            color: colors.onSurfaceSecondary,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Clear search',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close_rounded,
                  size: AppLayout.iconSm,
                  color: colors.onSurfaceSecondary,
                ),
                onPressed: () {
                  controller.clear();
                  onChanged?.call('');
                },
              );
            },
          ),
          enabledBorder: border(colors.borderLight),
          focusedBorder: border(colors.primary, 1.5),
        ),
      ),
    );
  }
}
