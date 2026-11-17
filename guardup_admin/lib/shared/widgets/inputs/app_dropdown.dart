import 'package:guardup_admin/shared/models/selectable_item.model.dart';
import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '../../../core/extensions/localization.extension.dart';
import '../../../core/extensions/spacing.extension.dart';

import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import '/shared/controllers/pagination.controller.dart';
import '/shared/controllers/selection.controller.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '../../states/pagination.state.dart';

class AppDropdown<V> extends StatefulWidget {
  final SelectionController<V> controller;
  final List<SelectableItem<V, String>> items;
  final Widget Function(bool)? dropdownItemChild;
  final Widget Function(GlobalKey) target;
  final Function(List<String>)? onItemTap;
  final Future<PaginationState<SelectableItem<V, String>>> Function({
    String? value,
    bool forceRefresh,
  })?
  onLoad;

  final bool isSearchEnabled;

  const AppDropdown({
    super.key,
    required this.controller,
    required this.items,
    required this.target,
    required this.onItemTap,
    this.onLoad,
    this.dropdownItemChild,
    this.isSearchEnabled = false,
  });

  @override
  State<AppDropdown<V>> createState() => _AppDropdownState<V>();
}

class _AppDropdownState<V> extends State<AppDropdown<V>> {
  final fieldController = TextEditingController();
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  final layerLink = LayerLink();
  OverlayEntry? entry;
  final GlobalKey fieldKey = GlobalKey();
  late final PaginationController<SelectableItem<V, String>>
  paginationController;

  @override
  void initState() {
    super.initState();
    paginationController = PaginationController<SelectableItem<V, String>>(
      initialState: PaginationState(
        items: widget.items,
        isLoading: widget.onLoad != null,
        total: widget.onLoad == null ? widget.items.length : 0,
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

    widget.onLoad?.call().then((value) {
      paginationController.updateState(value);
    });
  }

  @override
  void dispose() {
    paginationController.dispose();
    fieldController.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CompositedTransformTarget(
          link: layerLink,
          child: GestureDetector(
            onTap: () {
              initDropDown();
              _showDropdown();
            },
            child: AbsorbPointer(child: widget.target(fieldKey)),
          ),
        ),
      ],
    );
  }

  void _removeDropdown() {
    entry?.remove();
    entry = null;
  }

  void _search(String value) async {
    if (widget.onLoad == null) {
      final filteredItems = widget.items
          .where((x) => x.data.toLowerCase().contains(value.toLowerCase()))
          .toList();

      paginationController.updateState(
        paginationController.value.copyWith(items: filteredItems),
      );
    } else {
      final newState = await widget.onLoad!(value: value, forceRefresh: true);
      paginationController.updateState(newState);
    }
  }

  void initDropDown() {
    searchFocusNode.requestFocus();
  }

  void _showDropdown() {
    final targetRenderBox =
        fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final targetHeight = targetRenderBox?.size.height ?? 44.0;
    final targetWidth = targetRenderBox?.size.width;

    entry = OverlayEntry(
      builder: (context) {
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
              offset: Offset(0, targetHeight + 4),
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
                        alignment: Alignment.topCenter,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: targetWidth,
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(color: context.colors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.black.withValues(alpha: 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: context.colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.mdRadius,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isSearchEnabled)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm + 2,
                              ).copyWith(bottom: AppSpacing.xs),
                              child: AppTextField(
                                type: AppTextFieldType.search,
                                size: AppInputSize.small,
                                controller: searchController,
                                focusNode: searchFocusNode,
                                decoration: InputDecoration(
                                  hintText: context.l10n.searchItem,
                                ),
                                onChanged: _search,
                              ),
                            ),
                          Flexible(
                            child: ValueListenableBuilder(
                              valueListenable: widget.controller,
                              builder: (context, value, child) {
                                return AppPagination(
                                  controller: paginationController,
                                  builder:
                                      (
                                        scrollController,
                                        itemBuilder,
                                        itemCount,
                                      ) {
                                        return ListView.separated(
                                          controller: scrollController,
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: AppSpacing.xs,
                                          ),
                                          itemCount: itemCount,
                                          separatorBuilder: (_, _) => Divider(
                                            height: 1,
                                            color: context.colors.borderLight
                                                .withValues(alpha: 0.4),
                                          ),
                                          itemBuilder: itemBuilder,
                                        );
                                      },
                                  itemBuilder: (_, item, index) {
                                    final isSelected = widget.controller
                                        .isSelected(item.id);

                                    return Material(
                                      color: isSelected
                                          ? context.colors.secondary.withValues(
                                              alpha: 0.08,
                                            )
                                          : context.colors.transparent,
                                      child: InkWell(
                                        hoverColor: context.colors.secondary
                                            .withValues(alpha: 0.05),
                                        onTap: () {
                                          widget.controller.toggle(item.id);
                                          final labels = widget.items
                                              .where(
                                                (item) => widget
                                                    .controller
                                                    .value
                                                    .contains(item.id),
                                              )
                                              .map((e) => e.data)
                                              .toList();
                                          widget.onItemTap?.call(labels);
                                          if (widget
                                              .controller
                                              .isSingleSelection) {
                                            _removeDropdown();
                                          }
                                        },
                                        child:
                                            widget.dropdownItemChild?.call(
                                              isSelected,
                                            ) ??
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.md,
                                                    vertical: AppSpacing.sm + 2,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.data,
                                                      style: isSelected
                                                          ? context
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.semiBold()
                                                                .colour(
                                                                  context
                                                                      .colors
                                                                      .secondary,
                                                                )
                                                          : context
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.colour(
                                                                  context
                                                                      .colors
                                                                      .onSurface,
                                                                ),
                                                    ),
                                                  ),
                                                  if (isSelected) ...[
                                                    AppSpacing.xs.w,
                                                    Icon(
                                                      Icons.check_rounded,
                                                      size: AppSpacing.lg,
                                                      color: context
                                                          .colors
                                                          .secondary,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
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
}
