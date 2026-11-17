import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:guardup/core/extensions/number.extension.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/state/api_state.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/pagination/pagination.dart';
import '/shared/widgets/selection/selection.controller.dart';

/// Data class representing an item in [AppDropdown].
class SelectableItem<T, D> {
  final T id;
  final D data;
  final Widget? icon;
  final String? subtitle;

  const SelectableItem({
    required this.id,
    required this.data,
    this.icon,
    this.subtitle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectableItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          data == other.data &&
          subtitle == other.subtitle;

  @override
  int get hashCode => Object.hash(id, data, subtitle);
}

/// Convenience alias for string-labeled dropdown items.
typedef DropdownItem<T> = SelectableItem<T, String>;

class AppDropdown<V> extends StatefulWidget {
  final SelectionController<V> controller;
  final List<SelectableItem<V, String>> items;
  final Widget Function(bool isSelected)? dropdownItemChild;
  final Widget Function(GlobalKey fieldKey)? target;
  final String? hintText;
  final String? Function(String?)? validator;
  final Function(List<String> labels)? onItemTap;
  final ValueChanged<V>? onSelected;
  final bool? closeOnSelect;
  final Future<PaginationState<SelectableItem<V, String>>> Function({
    String? value,
    bool forceRefresh,
  })?
  onLoad;

  final bool isSearchEnabled;
  final bool useBottomSheet;
  final String? sheetTitle;

  const AppDropdown({
    super.key,
    required this.controller,
    required this.items,
    this.target,
    this.hintText,
    this.validator,
    this.onItemTap,
    this.onSelected,
    this.closeOnSelect,
    this.onLoad,
    this.dropdownItemChild,
    this.isSearchEnabled = false,
    this.useBottomSheet = false,
    this.sheetTitle,
  });

  @override
  State<AppDropdown<V>> createState() => _AppDropdownState<V>();
}

class _AppDropdownState<V> extends State<AppDropdown<V>> {
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  final _displayTextController = TextEditingController();
  final layerLink = LayerLink();
  OverlayEntry? entry;
  final GlobalKey fieldKey = GlobalKey();
  late final PaginationController<SelectableItem<V, String>>
  paginationController;

  @override
  void initState() {
    super.initState();
    _updateDisplayText();
    widget.controller.addListener(_onSelectionChanged);

    paginationController = PaginationController<SelectableItem<V, String>>(
      initialState: PaginationState<SelectableItem<V, String>>(
        items: widget.items,
        status: const ApiState.initial(),
        total: widget.items.length,
      ),
      onLoadMore: () async {
        final res = await widget.onLoad?.call(value: searchController.text);
        if (res != null) {
          paginationController.updateState(res);
        }
      },
      onRefresh: () async {
        final res = await widget.onLoad?.call(
          value: searchController.text,
          forceRefresh: true,
        );
        if (res != null) {
          paginationController.updateState(res);
        }
      },
    );
  }

  void _updateDisplayText() {
    final selected = widget.items.where((i) => widget.controller.value.contains(i.id));
    final displayText = selected.map((e) => e.data).join(', ');
    if (_displayTextController.text != displayText) {
      _displayTextController.text = displayText;
    }
  }

  void _onSelectionChanged() {
    _updateDisplayText();
  }

  @override
  void didUpdateWidget(covariant AppDropdown<V> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onSelectionChanged);
      widget.controller.addListener(_onSelectionChanged);
      _updateDisplayText();
    } else if (!listEquals(oldWidget.items, widget.items)) {
      _updateDisplayText();
    }

    if (!listEquals(oldWidget.items, widget.items)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        paginationController.updateState(
          paginationController.value.copyWith(
            items: widget.items,
            total: widget.items.length,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSelectionChanged);
    _removeDropdown();
    paginationController.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    _displayTextController.dispose();
    super.dispose();
  }

  Widget _buildTargetWidget(BuildContext context) {
    if (widget.target != null) {
      return widget.target!(fieldKey);
    }

    return AppTextField(
      key: fieldKey,
      controller: _displayTextController,
      readOnly: true,
      decoration: InputDecoration(
        hintText: widget.hintText ?? context.l10n.companyType,
        suffixIcon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: context.colors.onSurfaceVariant,
          size: 22,
        ),
      ),
      validator: widget.validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetWidget = GestureDetector(
      onTap: () {
        if (widget.useBottomSheet) {
          _showBottomSheet(context);
          return;
        }

        if (entry != null) {
          _removeDropdown();
          return;
        }

        final targetContext = fieldKey.currentContext;
        if (targetContext != null) {
          Scrollable.ensureVisible(
            targetContext,
            alignment: 0.15,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }

        _showDropdown();
        initDropDown();
      },
      child: AbsorbPointer(child: _buildTargetWidget(context)),
    );

    if (widget.useBottomSheet) {
      return targetWidget;
    }

    return Column(
      children: [
        CompositedTransformTarget(link: layerLink, child: targetWidget),
      ],
    );
  }

  void _removeDropdown() {
    entry?.remove();
    entry = null;

    searchController.clear();
    searchFocusNode.unfocus();
  }

  Future<void> _search(String value) async {
    if (widget.onLoad == null) {
      final filteredItems = widget.items
          .where((x) => x.data.toLowerCase().contains(value.toLowerCase()))
          .toList();

      paginationController.updateState(
        paginationController.value.copyWith(
          items: filteredItems,
          total: filteredItems.length,
        ),
      );

      return;
    }

    final newState = await widget.onLoad!(value: value, forceRefresh: true);

    if (!mounted) return;

    paginationController.updateState(newState);
  }

  void initDropDown() {
    if (widget.isSearchEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && entry != null) {
          searchFocusNode.requestFocus();
        }
      });
    }
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSpacing.sm.h,
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.colors.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      AppSpacing.md.h,
                      if (widget.sheetTitle != null &&
                          widget.sheetTitle!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.sheetTitle!,
                                style: context.textTheme.titleMedium?.bold(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.xs.h,
                      ],
                      if (widget.isSearchEnabled)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: AppTextField(
                            type: AppTextFieldType.search,
                            controller: searchController,
                            focusNode: searchFocusNode,
                            decoration: InputDecoration(
                              hintText: context.l10n.searchItem,
                            ),
                            onChanged: (val) async {
                              await _search(val);
                              setSheetState(() {});
                            },
                          ),
                        ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildDropdownList(
                            sheetContext,
                            isSheet: true,
                          ),
                        ),
                      ),
                      AppSpacing.md.h,
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      searchController.clear();
      _search('');
    });
  }

  void _showDropdown() {
    entry = OverlayEntry(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final screenSize = mediaQuery.size;
        final keyboardHeight = mediaQuery.viewInsets.bottom;
        final statusBarHeight = mediaQuery.padding.top;

        final renderBox =
            fieldKey.currentContext?.findRenderObject() as RenderBox?;
        final fieldWidth = renderBox?.hasSize == true
            ? renderBox!.size.width
            : null;
        final fieldHeight = renderBox?.hasSize == true
            ? renderBox!.size.height
            : 56.0;
        final fieldOffset = (renderBox != null && renderBox.attached)
            ? renderBox.localToGlobal(Offset.zero)
            : Offset.zero;

        final availableBottom = screenSize.height - keyboardHeight;
        final spaceBelow =
            availableBottom - (fieldOffset.dy + fieldHeight) - 12.0;
        final spaceAbove = fieldOffset.dy - statusBarHeight - 12.0;

        const double defaultMaxH = 260.0;
        final bool showAbove = spaceBelow < 180.0 && spaceAbove > spaceBelow;

        final double calculatedMaxH = showAbove
            ? spaceAbove.clamp(100.0, defaultMaxH)
            : spaceBelow.clamp(100.0, defaultMaxH);

        final targetAnchor = showAbove
            ? Alignment.topLeft
            : Alignment.bottomLeft;
        final followerAnchor = showAbove
            ? Alignment.bottomLeft
            : Alignment.topLeft;
        final offset = showAbove ? const Offset(0, -6) : const Offset(0, 6);
        final scaleAlignment = showAbove
            ? Alignment.bottomCenter
            : Alignment.topCenter;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeDropdown,
                behavior: HitTestBehavior.translucent,
              ),
            ),
            CompositedTransformFollower(
              link: layerLink,
              showWhenUnlinked: false,
              targetAnchor: targetAnchor,
              followerAnchor: followerAnchor,
              offset: offset,
              child: Material(
                color: context.colors.transparent,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  tween: Tween(begin: 0.95, end: 1),
                  builder: (context, scale, child) {
                    return Opacity(
                      opacity: scale,
                      child: Transform.scale(
                        scale: scale,
                        alignment: scaleAlignment,
                        child: child,
                      ),
                    );
                  },
                  child: QuickContainer(
                    w: fieldWidth,
                    maxH: calculatedMaxH,
                    color: context.colors.surfaceContainer,
                    radius: AppRadius.md,
                    border: Border.all(color: context.colors.outlineVariant),
                    shadows: [
                      BoxShadow(
                        color: context.colors.onSurface.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    child: ClipRRect(
                      borderRadius: AppRadius.md.toBorderRadius,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isSearchEnabled)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ).copyWith(bottom: 0),
                              child: AppTextField(
                                type: AppTextFieldType.search,
                                controller: searchController,
                                focusNode: searchFocusNode,
                                decoration: InputDecoration(
                                  hintText: context.l10n.searchItem,
                                ),
                                onChanged: _search,
                              ),
                            ),
                          Flexible(
                            child: _buildDropdownList(context, isSheet: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(entry!);
  }

  Widget _buildDropdownList(BuildContext context, {required bool isSheet}) {
    return ValueListenableBuilder<List<V>>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        return AppPagination<SelectableItem<V, String>>(
          controller: paginationController,
          builder: (scrollController, itemBuilder, itemCount) {
            return ListView.builder(
              controller: scrollController,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: itemCount,
              itemBuilder: itemBuilder,
            );
          },
          itemBuilder: (_, item, index) {
            final isSelected = widget.controller.isSelected(item.id);

            return InkWell(
              onTap: () {
                final shouldClose =
                    widget.closeOnSelect ?? widget.controller.isSingleSelection;
                if (shouldClose) {
                  if (isSheet) {
                    Navigator.of(context).pop();
                  } else {
                    _removeDropdown();
                  }
                }

                widget.controller.toggle(item.id);

                final labels = paginationController.value.items
                    .where((i) => widget.controller.value.contains(i.id))
                    .map((e) => e.data)
                    .toList();

                widget.onItemTap?.call(labels);
                widget.onSelected?.call(item.id);
              },
              child:
                  widget.dropdownItemChild?.call(isSelected) ??
                  QuickContainer(
                    px: AppSpacing.md,
                    py: AppSpacing.sm,
                    child: Row(
                      children: [
                        if (item.icon != null) ...[item.icon!, AppSpacing.sm.w],
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child:
                              isSelected && !widget.controller.isSingleSelection
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      key: const ValueKey(true),
                                      size: 18,
                                      color: context.colors.primary,
                                    ),
                                    AppSpacing.xs.w,
                                  ],
                                )
                              : const SizedBox.shrink(key: ValueKey(false)),
                        ),
                        Expanded(
                          child: Text(
                            item.data,
                            style: isSelected
                                ? context.textTheme.bodyMedium?.bold()
                                : context.textTheme.bodyMedium?.colour(
                                    context.colors.onSurfaceVariant,
                                  ),
                          ),
                        ),
                        if (isSelected && widget.controller.isSingleSelection)
                          Icon(
                            Icons.check,
                            size: 18,
                            color: context.colors.primary,
                          ),
                      ],
                    ),
                  ),
            );
          },
        );
      },
    );
  }
}
