import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_layout.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import '../feedbacks/widgets/app_dialog.dart';
import '../inputs/app_text_field.dart';
import '../misc/app_hover_builder.dart';
import '../state/app_state_view.dart';
import 'models.dart';

/// A searchable destination in the palette.
typedef _PaletteEntry = ({AdminNavItem item, String? group, String? parent});

/// Quick-navigation palette (⌘K / Ctrl+K) over every routable sidebar item.
///
/// Matches label, parent group, section and description. ↑ / ↓ move the
/// highlight, ↵ (submitted from the search field) opens it, Esc closes.
class AdminCommandPalette extends StatefulWidget {
  const AdminCommandPalette({
    super.key,
    required this.sections,
    required this.onSelect,
  });

  final List<AdminNavSection> sections;
  final ValueChanged<AdminNavItem> onSelect;

  static Future<void> show(
    BuildContext context, {
    required List<AdminNavSection> sections,
    required ValueChanged<AdminNavItem> onSelect,
  }) {
    return AppDialogs.showRaw<void>(
      context: context,
      child: AdminCommandPalette(sections: sections, onSelect: onSelect),
    );
  }

  @override
  State<AdminCommandPalette> createState() => _AdminCommandPaletteState();
}

class _AdminCommandPaletteState extends State<AdminCommandPalette> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _highlightNotifier = ValueNotifier<int>(0);
  final ValueNotifier<List<_PaletteEntry>> _resultsNotifier = ValueNotifier(
    const [],
  );

  late final List<_PaletteEntry> _entries = [
    for (final section in widget.sections)
      for (final item in section.items) ..._entriesFor(item, section.title),
  ];

  @override
  void initState() {
    super.initState();
    _resultsNotifier.value = _entries;
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    _highlightNotifier.dispose();
    _resultsNotifier.dispose();
    super.dispose();
  }

  Iterable<_PaletteEntry> _entriesFor(
    AdminNavItem item,
    String? group, {
    String? parent,
  }) sync* {
    if (item.route != null && item.enabled) {
      yield (item: item, group: group, parent: parent);
    }
    for (final child in item.children) {
      yield* _entriesFor(child, group, parent: item.label);
    }
  }

  void _onQueryChanged(String raw) {
    final query = raw.trim().toLowerCase();
    _resultsNotifier.value = query.isEmpty
        ? _entries
        : _entries.where((entry) {
            return [
              entry.item.label,
              entry.parent,
              entry.group,
              entry.item.description,
            ].any((field) => field?.toLowerCase().contains(query) ?? false);
          }).toList();
    _highlightNotifier.value = 0;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _moveHighlight(int delta) {
    final count = _resultsNotifier.value.length;
    if (count == 0) return;
    final next = (_highlightNotifier.value + delta) % count;
    _highlightNotifier.value = next < 0 ? next + count : next;
    _revealHighlighted();
  }

  void _revealHighlighted() {
    if (!_scrollController.hasClients) return;
    const extent = AppLayout.commandPaletteItemHeight;
    final position = _scrollController.position;
    final itemTop = _highlightNotifier.value * extent + AppSpacing.sm;
    final itemBottom = itemTop + extent;

    if (itemTop < position.pixels) {
      _scrollController.jumpTo(itemTop - AppSpacing.sm);
    } else if (itemBottom > position.pixels + position.viewportDimension) {
      _scrollController.jumpTo(
        itemBottom - position.viewportDimension + AppSpacing.sm,
      );
    }
  }

  /// Guards against a double pop (e.g. a click landing during the close
  /// animation), which would also close the route underneath.
  bool _isClosing = false;

  void _open(_PaletteEntry entry) {
    if (_isClosing) return;
    _isClosing = true;
    Navigator.of(context).pop();
    widget.onSelect(entry.item);
  }

  void _openHighlighted() {
    final results = _resultsNotifier.value;
    if (results.isEmpty) return;
    _open(results[_highlightNotifier.value]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final viewport = MediaQuery.sizeOf(context);

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(
          top: viewport.height * 0.12,
          left: AppSpacing.md,
          right: AppSpacing.md,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                  _moveHighlight(1),
              const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                  _moveHighlight(-1),
            },
            child: QuickContainer(
              maxW: AppLayout.commandPaletteWidth,
              maxH: AppLayout.commandPaletteHeight,
              color: colors.surface,
              radius: AppRadius.lg,
              border: Border.all(color: colors.borderLight),
              shadows: [
                BoxShadow(
                  color: colors.black.withValues(alpha: 0.18),
                  blurRadius: AppSpacing.xxxl,
                  offset: const Offset(0, AppSpacing.md),
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: AppSpacing.md.allPadding,
                    child: AppTextField.search(
                      controller: _queryController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Jump to a page…',
                      ),
                      onChanged: _onQueryChanged,
                      onFieldSubmitted: (_) => _openHighlighted(),
                    ),
                  ),
                  Divider(height: 1, color: colors.borderLight),
                  Flexible(child: _buildResults(context)),
                  _PaletteFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    return ValueListenableBuilder<List<_PaletteEntry>>(
      valueListenable: _resultsNotifier,
      builder: (context, results, _) {
        if (results.isEmpty) {
          return const AppStateView.noResults(
            isCompact: true,
            message: 'No matching pages',
            subtitle: 'Try a different keyword, like "pending" or "plans".',
          );
        }

        return ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          padding: AppSpacing.sm.allPadding,
          itemExtent: AppLayout.commandPaletteItemHeight,
          itemCount: results.length,
          itemBuilder: (context, index) => _PaletteRow(
            entry: results[index],
            index: index,
            highlightNotifier: _highlightNotifier,
            onTap: () => _open(results[index]),
          ),
        );
      },
    );
  }
}

// ─── Row ─────────────────────────────────────────────────────────────────────

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({
    required this.entry,
    required this.index,
    required this.highlightNotifier,
    required this.onTap,
  });

  final _PaletteEntry entry;
  final int index;
  final ValueNotifier<int> highlightNotifier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final item = entry.item;
    final caption =
        item.description ?? [entry.group, entry.parent].nonNulls.join(' › ');

    final content = Row(
      children: [
        _IconTile(icon: item.icon),
        AppSpacing.md.w,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.parent != null
                    ? '${entry.parent} · ${item.label}'
                    : item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.semiBold().colour(
                  colors.onSurface,
                ),
              ),
              if (caption.isNotEmpty)
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.colour(
                    colors.onSurfaceSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    return AppHoverBuilder(
      cursor: SystemMouseCursors.click,
      onHoverChanged: (isHovered) {
        if (isHovered) highlightNotifier.value = index;
      },
      builder: (context, _, child) => ValueListenableBuilder<int>(
        valueListenable: highlightNotifier,
        builder: (context, highlighted, child) {
          final isHighlighted = highlighted == index;
          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: AppDurations.instant,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? colors.primary.withValues(alpha: 0.08)
                    : colors.transparent,
                borderRadius: AppRadius.mdRadius,
              ),
              child: Row(
                children: [
                  Expanded(child: child!),
                  AnimatedOpacity(
                    duration: AppDurations.instant,
                    opacity: isHighlighted ? 1 : 0,
                    child: Icon(
                      Icons.keyboard_return_rounded,
                      size: AppLayout.iconSm,
                      color: colors.onSurfaceSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: child,
      ),
      child: content,
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return QuickContainer(
      w: AppLayout.controlHeightSm,
      h: AppLayout.controlHeightSm,
      alignment: Alignment.center,
      radius: AppRadius.sm,
      color: colors.primary.withValues(alpha: 0.1),
      child: Icon(icon, size: AppLayout.iconSm, color: colors.primary),
    );
  }
}

class _PaletteFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.textTheme.labelSmall?.colour(
      colors.onSurfaceSecondary,
    );

    Widget hint(String keys, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        QuickContainer(
          px: AppSpacing.xs + 1,
          py: 1,
          radius: AppRadius.xs,
          color: colors.surface,
          border: Border.all(color: colors.borderLight),
          child: Text(keys, style: style?.semiBold()),
        ),
        AppSpacing.xs.w,
        Text(label, style: style),
      ],
    );

    return QuickContainer(
      px: AppSpacing.lg,
      py: AppSpacing.sm,
      color: colors.surfaceMuted,
      border: Border(top: BorderSide(color: colors.borderLight)),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.xs,
        children: [
          hint('↑↓', 'Navigate'),
          hint('↵', 'Open'),
          hint('Esc', 'Close'),
        ],
      ),
    );
  }
}
