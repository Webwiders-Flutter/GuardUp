import 'dart:math';

import 'package:flutter/material.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_layout.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/menu.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import '../buttons/app_icon_button.dart';
import '../misc/app_hover_builder.dart';

/// Pagination footer for [AdminTableBuilder]: entry range, rows-per-page
/// selector and page navigation (numbered pills on wide layouts, a compact
/// "3 / 12" indicator on narrow ones).
class TableFooter extends StatelessWidget {
  final int totalEntries;
  final int rowsPerPage;
  final int currentPage;
  final int visibleCount;
  final ValueNotifier<bool> nextLoading;
  final void Function()? onPrevious;
  final Future<void> Function() onNext;
  final void Function(int page)? onPageSelected;
  final ValueNotifier<int>? limitNotifier;
  final ValueChanged<int>? onLimitChange;

  /// Options offered by the rows-per-page selector.
  final List<int> pageSizeOptions;

  const TableFooter({
    super.key,
    required this.totalEntries,
    required this.rowsPerPage,
    required this.currentPage,
    required this.visibleCount,
    required this.nextLoading,
    this.onPrevious,
    required this.onNext,
    this.onPageSelected,
    this.limitNotifier,
    this.onLimitChange,
    this.pageSizeOptions = const [10, 25, 50, 100],
  });

  int get _pageSize => rowsPerPage <= 0 ? 10 : rowsPerPage;

  int get _totalPages => max(1, (totalEntries / _pageSize).ceil());

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final start = totalEntries == 0 ? 0 : (currentPage - 1) * _pageSize + 1;
    final end = min(start + _pageSize - 1, totalEntries);
    final hasNext = end < totalEntries;

    final rangeLabel = Text(
      totalEntries == 0 ? 'No entries' : 'Showing $start–$end of $totalEntries',
      style: context.textTheme.bodySmall?.colour(colors.onSurfaceSecondary),
    );

    final pageSize = limitNotifier != null
        ? _PageSizeSelector(
            notifier: limitNotifier!,
            options: pageSizeOptions,
            onChanged: onLimitChange,
          )
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.borderLight)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < AppLayout.tableCardBreakpoint;

          final navigation = ValueListenableBuilder<bool>(
            valueListenable: nextLoading,
            builder: (context, isLoading, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIconButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Previous page',
                  onPressed: currentPage > 1 && !isLoading ? onPrevious : null,
                ),
                AppSpacing.xs.w,
                if (isNarrow)
                  _CompactIndicator(page: currentPage, total: _totalPages)
                else
                  ..._buildPills(context),
                AppSpacing.xs.w,
                AppIconButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Next page',
                  isLoading: isLoading,
                  onPressed: hasNext ? onNext : null,
                ),
              ],
            ),
          );

          if (isNarrow) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [rangeLabel, ?pageSize],
                ),
                AppSpacing.sm.h,
                navigation,
              ],
            );
          }

          return Row(
            children: [
              rangeLabel,
              if (pageSize != null) ...[AppSpacing.lg.w, pageSize],
              const Spacer(),
              navigation,
            ],
          );
        },
      ),
    );
  }

  /// Page numbers with ellipses: 1 … 4 [5] 6 … 12.
  List<Widget> _buildPills(BuildContext context) {
    final total = _totalPages;
    if (total <= 1) return const [];

    final pages = <int?>[];
    if (total <= 7) {
      pages.addAll(List.generate(total, (i) => i + 1));
    } else {
      final from = max(2, currentPage - 1);
      final to = min(total - 1, currentPage + 1);
      pages.add(1);
      if (from > 2) pages.add(null);
      for (var page = from; page <= to; page++) {
        pages.add(page);
      }
      if (to < total - 1) pages.add(null);
      pages.add(total);
    }

    return [
      for (final page in pages)
        page == null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  '…',
                  style: context.textTheme.bodySmall?.colour(
                    context.colors.onSurfaceSecondary,
                  ),
                ),
              )
            : _PagePill(
                page: page,
                isSelected: page == currentPage,
                onTap: onPageSelected == null || page == currentPage
                    ? null
                    : () => onPageSelected!(page),
              ),
    ];
  }
}

class _PagePill extends StatelessWidget {
  const _PagePill({
    required this.page,
    required this.isSelected,
    required this.onTap,
  });

  final int page;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
      child: AppHoverBuilder(
        enabled: onTap != null,
        cursor: SystemMouseCursors.click,
        builder: (context, isHovered, _) => GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppDurations.instant,
            constraints: const BoxConstraints(
              minWidth: AppLayout.controlHeight,
            ),
            height: AppLayout.controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary
                  : isHovered
                  ? colors.surfaceMuted
                  : colors.transparent,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Text(
              '$page',
              style: context.textTheme.labelMedium
                  ?.weight(isSelected ? FontWeight.w700 : FontWeight.w500)
                  .colour(isSelected ? colors.onPrimary : colors.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactIndicator extends StatelessWidget {
  const _CompactIndicator({required this.page, required this.total});

  final int page;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.sm.xPadding,
      child: Text(
        '$page / $total',
        style: context.textTheme.labelMedium?.semiBold().colour(
          context.colors.onSurface,
        ),
      ),
    );
  }
}

/// "Rows [10 ▾]" selector that opens a menu of [options].
class _PageSizeSelector extends StatelessWidget {
  const _PageSizeSelector({
    required this.notifier,
    required this.options,
    this.onChanged,
  });

  final ValueNotifier<int> notifier;
  final List<int> options;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final labelStyle = context.textTheme.bodySmall;

    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (context, value, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Rows', style: labelStyle?.colour(colors.onSurfaceSecondary)),
          AppSpacing.sm.w,
          Builder(
            builder: (anchor) => AppHoverBuilder(
              cursor: SystemMouseCursors.click,
              builder: (context, isHovered, _) => GestureDetector(
                onTap: () async {
                  final selected = await anchor.showAnchoredMenu<int>(
                    items: [
                      for (final option in options)
                        CheckedPopupMenuItem<int>(
                          value: option,
                          checked: option == value,
                          height: AppLayout.controlHeight,
                          child: Text('$option'),
                        ),
                    ],
                  );
                  if (selected == null || selected == value) return;
                  notifier.value = selected;
                  onChanged?.call(selected);
                },
                child: AnimatedContainer(
                  duration: AppDurations.instant,
                  height: AppLayout.controlHeight,
                  padding: const EdgeInsets.only(
                    left: AppSpacing.sm + 2,
                    right: AppSpacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: isHovered ? colors.surfaceMuted : colors.surface,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: colors.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$value',
                        style: labelStyle?.semiBold().colour(colors.onSurface),
                      ),
                      AppSpacing.xs.w,
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: AppLayout.iconSm,
                        color: colors.onSurfaceSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
