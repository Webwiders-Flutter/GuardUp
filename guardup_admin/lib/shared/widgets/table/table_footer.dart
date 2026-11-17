import 'dart:math';

import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';

/// Modern pagination footer for [AdminTableBuilder].
///
/// Features:
/// - "Showing X to Y of Z entries" record counter
/// - Inline rows-per-page selector (moved from top-bar)
/// - Direct page-number pills (1, 2, 3 … N)
/// - Previous / Next navigation with async loading indicator
/// - Fully responsive — collapses gracefully on narrow viewports
class TableFooter extends StatelessWidget {
  final int totalEntries;
  final int rowsPerPage;
  final int currentPage;
  final int visibleCount;
  final ValueNotifier<bool> nextLoading;
  final void Function()? onPrevious;
  final Future<void> Function() onNext;
  final void Function(int page)? onPageSelected;

  /// Page-size selector props (moved from TableTopBar)
  final ValueNotifier<int>? limitNotifier;
  final ValueChanged<int>? onLimitChange;

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
  });

  int get _effectiveRowsPerPage => rowsPerPage <= 0 ? 10 : rowsPerPage;

  int get _totalPages =>
      (totalEntries / _effectiveRowsPerPage).ceil().clamp(1, 999999);

  @override
  Widget build(BuildContext context) {
    final int rpp = _effectiveRowsPerPage;
    final int start = totalEntries == 0 ? 0 : (currentPage - 1) * rpp + 1;
    final int end = min(start + rpp - 1, totalEntries);
    final borderColor = context.colors.borderLight.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: borderColor)),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.lg),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;

          if (isNarrow) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Entries counter + page size selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing $start–$end of $totalEntries',
                      style: context.textTheme.bodySmall
                          ?.size(AppSpacing.md)
                          .colour(context.colors.onSurfaceSecondary),
                    ),
                    if (limitNotifier != null)
                      _PageSizeSelector(
                        notifier: limitNotifier!,
                        onChanged: onLimitChange,
                      ),
                  ],
                ),
                AppSpacing.md.h,
                ValueListenableBuilder<bool>(
                  valueListenable: nextLoading,
                  builder: (_, loading, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PaginationNavButton(
                        icon: Icons.chevron_left_rounded,
                        label: 'Prev',
                        onTap: (currentPage > 1 && !loading)
                            ? onPrevious
                            : null,
                      ),
                      AppSpacing.sm.w,
                      _buildCompactPageIndicator(context),
                      AppSpacing.sm.w,
                      _PaginationNavButton(
                        icon: Icons.chevron_right_rounded,
                        label: 'Next',
                        reverse: true,
                        loading: loading,
                        onTap: (end < totalEntries && !loading) ? onNext : null,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: record count + page size selector
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Showing $start to $end of $totalEntries entries',
                    style: context.textTheme.bodySmall
                        ?.size(AppSpacing.md + 1)
                        .colour(context.colors.onSurfaceSecondary),
                  ),
                  if (limitNotifier != null) ...[
                    AppSpacing.lg.w,
                    _PageSizeSelector(
                      notifier: limitNotifier!,
                      onChanged: onLimitChange,
                    ),
                  ],
                ],
              ),

              // Right: pagination controls
              ValueListenableBuilder<bool>(
                valueListenable: nextLoading,
                builder: (_, loading, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PaginationNavButton(
                      icon: Icons.chevron_left_rounded,
                      label: 'Previous',
                      onTap: (currentPage > 1 && !loading) ? onPrevious : null,
                    ),
                    AppSpacing.sm.w,
                    ..._buildPagePills(context),
                    AppSpacing.sm.w,
                    _PaginationNavButton(
                      icon: Icons.chevron_right_rounded,
                      label: 'Next',
                      reverse: true,
                      loading: loading,
                      onTap: (end < totalEntries && !loading) ? onNext : null,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactPageIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: context.colors.backgroundLight,
        borderRadius: AppRadius.smRadius,
        border: Border.all(
          color: context.colors.borderLight.withValues(alpha: 0.6),
        ),
      ),
      child: Text(
        '$currentPage / $_totalPages',
        style: context.textTheme.labelMedium?.bold().colour(
          context.colors.onSurface,
        ),
      ),
    );
  }

  List<Widget> _buildPagePills(BuildContext context) {
    final total = _totalPages;
    if (total <= 1) return const [];

    final List<Widget> pills = [];
    final List<int> pagesToShow = [];

    if (total <= 5) {
      for (int i = 1; i <= total; i++) {
        pagesToShow.add(i);
      }
    } else {
      pagesToShow.add(1);
      int startPage = max(2, currentPage - 1);
      int endPage = min(total - 1, currentPage + 1);

      if (startPage > 2) pagesToShow.add(-1); // ellipsis marker
      for (int i = startPage; i <= endPage; i++) {
        pagesToShow.add(i);
      }
      if (endPage < total - 1) pagesToShow.add(-2); // ellipsis marker
      pagesToShow.add(total);
    }

    for (final page in pagesToShow) {
      if (page < 0) {
        pills.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              '…',
              style: context.textTheme.bodySmall?.colour(
                context.colors.onSurfaceSecondary,
              ),
            ),
          ),
        );
      } else {
        final isSelected = page == currentPage;
        pills.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
            child: InkWell(
              onTap: onPageSelected != null && !isSelected
                  ? () => onPageSelected!(page)
                  : null,
              borderRadius: AppRadius.mdRadius,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: AppSpacing.xxxl + 2,
                height: AppSpacing.xxxl + 2,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colors.secondary
                      : context.colors.transparent,
                  borderRadius: AppRadius.mdRadius,
                  border: isSelected
                      ? null
                      : Border.all(
                          color: context.colors.borderLight.withValues(
                            alpha: 0.0,
                          ),
                        ),
                ),
                child: Text(
                  '$page',
                  style: context.textTheme.labelMedium
                      ?.weight(isSelected ? FontWeight.w700 : FontWeight.w500)
                      .colour(
                        isSelected
                            ? context.colors.onPrimary
                            : context.colors.onSurface,
                      ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return pills;
  }
}

// ─── Inline Page-Size Selector ────────────────────────────────────────────────

/// Compact dropdown for selecting displayed rows per page.
/// Relocated from [TableTopBar] to [TableFooter] for better UX.
class _PageSizeSelector extends StatelessWidget {
  final ValueNotifier<int> notifier;
  final ValueChanged<int>? onChanged;

  const _PageSizeSelector({required this.notifier, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final textColor = context.colors.onSurface;
    final mutedColor = context.colors.onSurfaceSecondary;
    final borderColor = context.colors.borderLight.withValues(alpha: 0.6);

    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (_, value, _) {
        return Container(
          height: AppSpacing.md * 3 - 2,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.backgroundLight,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Show:',
                style: context.textTheme.bodySmall
                    ?.size(AppSpacing.md + 1)
                    .colour(mutedColor),
              ),
              AppSpacing.xs.w,
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: value,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: AppSpacing.lg,
                    color: mutedColor,
                  ),
                  borderRadius: AppRadius.mdRadius,
                  style: context.textTheme.bodySmall
                      ?.size(AppSpacing.md + 1)
                      .medium()
                      .colour(textColor),
                  items: const [10, 25, 50, 100]
                      .map(
                        (n) => DropdownMenuItem(
                          value: n,
                          child: Text(
                            '$n',
                            style: context.textTheme.bodySmall
                                ?.size(AppSpacing.md + 1)
                                .colour(textColor),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (n) {
                    if (n != null) {
                      notifier.value = n;
                      onChanged?.call(n);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Bordered Navigation Button ───────────────────────────────────────────────

class _PaginationNavButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData icon;
  final bool reverse;
  final bool loading;

  const _PaginationNavButton({
    required this.label,
    this.onTap,
    required this.icon,
    this.reverse = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;
    final mutedColor = context.colors.onSurfaceSecondary;
    final textColor = context.colors.onSurface;
    final borderColor = context.colors.borderLight.withValues(alpha: 0.6);

    return Material(
      color: context.colors.surface,
      borderRadius: AppRadius.mdRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdRadius,
        child: Container(
          height: AppSpacing.xxxl + 2,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: borderColor),
          ),
          child: loading
              ? Center(
                  child: SizedBox(
                    width: AppSpacing.md + 2,
                    height: AppSpacing.md + 2,
                    child: CircularProgressIndicator(
                      strokeWidth: AppSpacing.xs / 2,
                      color: context.colors.secondary,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!reverse) ...[
                      Icon(
                        icon,
                        size: AppSpacing.lg,
                        color: disabled
                            ? mutedColor.withValues(alpha: 0.4)
                            : textColor,
                      ),
                      AppSpacing.xs.w,
                    ],
                    Text(
                      label,
                      style: context.textTheme.bodySmall?.semiBold().colour(
                        disabled
                            ? mutedColor.withValues(alpha: 0.4)
                            : textColor,
                      ),
                    ),
                    if (reverse) ...[
                      AppSpacing.xs.w,
                      Icon(
                        icon,
                        size: AppSpacing.lg,
                        color: disabled
                            ? mutedColor.withValues(alpha: 0.4)
                            : textColor,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
