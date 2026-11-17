import 'package:guardup_admin/core/extensions/context.extension.dart';
import 'package:guardup_admin/core/extensions/localization.extension.dart';
import 'package:guardup_admin/core/extensions/spacing.extension.dart';
import 'package:guardup_admin/core/extensions/textstyle_extension.dart';
import 'package:flutter/material.dart';

import '/core/constants/app_spacing.dart';
import '../../controllers/pagination.controller.dart';
import '../../states/pagination.state.dart';

class AppPagination<T> extends StatefulWidget {
  final PaginationController<T>? controller;
  final PaginationState<T>? state;

  final Widget Function(
    ScrollController controller,
    IndexedWidgetBuilder itemBuilder,
    int itemCount,
  )
  builder;

  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget? header;

  final WidgetBuilder? initialLoaderBuilder;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? loadMoreBuilder;
  final WidgetBuilder? errorBuilder;
  final WidgetBuilder? loadMoreErrorBuilder;
  final WidgetBuilder? noMoreDataBuilder;

  const AppPagination({
    super.key,
    this.controller,
    this.state,
    this.header,
    required this.builder,
    required this.itemBuilder,
    this.initialLoaderBuilder,
    this.emptyBuilder,
    this.loadMoreBuilder,
    this.noMoreDataBuilder,
    this.errorBuilder,
    this.loadMoreErrorBuilder,
  }) : assert(
         controller != null || state != null,
         'Either controller or state must be provided to AppPagination.',
       );

  @override
  State<AppPagination<T>> createState() => _AppPaginationState<T>();
}

class _AppPaginationState<T> extends State<AppPagination<T>> {
  PaginationController<T>? _internalController;

  PaginationController<T> get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    _initControllerIfNeeded();
  }

  void _initControllerIfNeeded() {
    if (widget.controller == null) {
      _internalController = PaginationController<T>(initialState: widget.state);
    }
  }

  @override
  void didUpdateWidget(covariant AppPagination<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _internalController?.dispose();
        _internalController = null;
      }
      _initControllerIfNeeded();
    } else if (widget.controller == null && widget.state != oldWidget.state) {
      if (widget.state != null) {
        _internalController?.updateState(widget.state!);
      }
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  Widget _itemBuilder(
    BuildContext context,
    PaginationState<T> state,
    int index,
  ) {
    if (widget.header != null) {
      if (index == 0) {
        return widget.header!;
      }
      index -= 1;
    }

    if (index < state.items.length) {
      return widget.itemBuilder(context, state.items[index], index);
    }

    /// Footer
    if (state.hasLoadMoreError) {
      return widget.loadMoreErrorBuilder?.call(context) ??
          Padding(
            padding: AppSpacing.lg.allPadding,
            child: Center(
              child: Text(
                context.l10n.failedToLoadMore,
                style: context.textTheme.bodyMedium?.colour(
                  context.colors.error,
                ),
              ),
            ),
          );
    }

    if (state.isLastPage) {
      return widget.noMoreDataBuilder?.call(context) ?? const SizedBox.shrink();
    }

    return widget.loadMoreBuilder?.call(context) ??
        widget.initialLoaderBuilder?.call(context) ??
        Padding(
          padding: AppSpacing.lg.allPadding,
          child: const Center(child: CircularProgressIndicator()),
        );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PaginationState<T>>(
      valueListenable: _effectiveController,
      builder: (context, state, _) {
        /// Initial Loading
        if (state.items.isEmpty && state.isLoading) {
          if (widget.header != null) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                widget.header!,
                widget.initialLoaderBuilder?.call(context) ??
                    Padding(
                      padding: AppSpacing.xl.allPadding,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
              ],
            );
          }
          return widget.initialLoaderBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        /// Error
        if (state.items.isEmpty && state.hasError) {
          if (widget.header != null) {
            return RefreshIndicator(
              onRefresh: () async => _effectiveController.refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  widget.header!,
                  widget.errorBuilder?.call(context) ??
                      Center(
                        child: Padding(
                          padding: AppSpacing.xl.allPadding,
                          child: Text(
                            context.l10n.somethingWentWrong,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colors.error,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            );
          }
          return widget.errorBuilder?.call(context) ??
              Center(
                child: Text(
                  context.l10n.somethingWentWrong,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              );
        }

        /// Empty
        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => _effectiveController.refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                if (widget.header != null) widget.header!,
                SizedBox(
                  child: Center(
                    child:
                        widget.emptyBuilder?.call(context) ??
                        Padding(
                          padding: AppSpacing.xl.allPadding,
                          child: Text(
                            context.l10n.noDataFound,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colors.onSurfaceSecondary,
                            ),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          );
        }

        /// Main Builder (List / Grid / Anything)
        final int headerCount = widget.header != null ? 1 : 0;
        return RefreshIndicator(
          onRefresh: () async => _effectiveController.refresh(),
          child: widget.builder(
            _effectiveController.scrollController,
            (ctx, idx) => _itemBuilder(ctx, state, idx),
            state.items.length + 1 + headerCount,
          ),
        );
      },
    );
  }
}
