import 'package:flutter/material.dart';
import 'package:guardup/shared/widgets/state/app_state_view.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import 'pagination.controller.dart';
import 'pagination.state.dart';

/// A robust, reusable pagination widget that manages initial loading, empty states,
/// error handling, pull-to-refresh, infinite scroll loading, and footer states.
///
/// Can be driven by either a [PaginationController] or directly via a [PaginationState].
class AppPagination<T> extends StatefulWidget {
  /// External controller driving this pagination view.
  final PaginationController<T>? controller;

  /// External state (e.g. from a Bloc/Cubit). When provided without a controller,
  /// an internal controller is managed automatically.
  final PaginationState<T>? state;

  /// Custom builder for constructing the underlying scrollable widget
  /// (e.g. ListView, GridView, CustomScrollView).
  final Widget Function(
    ScrollController controller,
    IndexedWidgetBuilder itemBuilder,
    int itemCount,
  )
  builder;

  /// Builds individual list items.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Optional header widget placed at the top of the scrollable list.
  final Widget? header;

  /// Custom builder for full-screen initial loading state.
  final WidgetBuilder? initialLoaderBuilder;

  /// Custom builder for empty items state.
  final WidgetBuilder? emptyBuilder;

  /// Custom builder for the footer spinner when loading subsequent pages.
  final WidgetBuilder? loadMoreBuilder;

  /// Custom builder for the full-screen error state.
  final Widget Function(BuildContext context, String? errorMessage)?
  errorBuilder;

  /// Custom builder for the footer error state when loading more items fails.
  final Widget Function(BuildContext context, VoidCallback onRetry)?
  loadMoreErrorBuilder;

  /// Custom builder shown at the end of the list when all items have been fetched.
  final WidgetBuilder? noMoreDataBuilder;

  /// Whether pull-to-refresh is enabled. Defaults to `true`.
  final bool enablePullToRefresh;

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
    this.enablePullToRefresh = true,
  }) : assert(
         controller != null || state != null,
         'Either controller or state must be provided to AppPagination.',
       );

  /// Convenient factory constructor for a standard separated/non-separated [ListView].
  factory AppPagination.list({
    Key? key,
    PaginationController<T>? controller,
    PaginationState<T>? state,
    Widget? header,
    required Widget Function(BuildContext context, T item, int index)
    itemBuilder,
    Widget Function(BuildContext context, int index)? separatorBuilder,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    WidgetBuilder? initialLoaderBuilder,
    WidgetBuilder? emptyBuilder,
    WidgetBuilder? loadMoreBuilder,
    WidgetBuilder? noMoreDataBuilder,
    Widget Function(BuildContext context, String? errorMessage)? errorBuilder,
    Widget Function(BuildContext context, VoidCallback onRetry)?
    loadMoreErrorBuilder,
    bool enablePullToRefresh = true,
    bool shrinkWrap = false,
  }) {
    return AppPagination<T>(
      key: key,
      controller: controller,
      state: state,
      header: header,
      itemBuilder: itemBuilder,
      initialLoaderBuilder: initialLoaderBuilder,
      emptyBuilder: emptyBuilder,
      loadMoreBuilder: loadMoreBuilder,
      noMoreDataBuilder: noMoreDataBuilder,
      errorBuilder: errorBuilder,
      loadMoreErrorBuilder: loadMoreErrorBuilder,
      enablePullToRefresh: enablePullToRefresh,
      builder: (scrollController, internalItemBuilder, itemCount) {
        if (separatorBuilder != null) {
          return ListView.separated(
            controller: shrinkWrap ? null : scrollController,
            shrinkWrap: shrinkWrap,
            physics:
                physics ??
                (shrinkWrap
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics()),
            padding: padding,
            itemCount: itemCount,
            separatorBuilder: (context, index) {
              // If header is present and index is 0, don't show separator
              if (header != null && index == 0) {
                return const SizedBox.shrink();
              }
              // If last item (footer/loader), don't show separator
              if (index >= itemCount - 1) {
                return const SizedBox.shrink();
              }
              return separatorBuilder(context, index);
            },
            itemBuilder: internalItemBuilder,
          );
        }

        return ListView.builder(
          controller: shrinkWrap ? null : scrollController,
          shrinkWrap: shrinkWrap,
          physics:
              physics ??
              (shrinkWrap
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics()),
          padding: padding,
          itemCount: itemCount,
          itemBuilder: internalItemBuilder,
        );
      },
    );
  }

  /// Convenient factory constructor for a [GridView].
  factory AppPagination.grid({
    Key? key,
    PaginationController<T>? controller,
    PaginationState<T>? state,
    Widget? header,
    required SliverGridDelegate gridDelegate,
    required Widget Function(BuildContext context, T item, int index)
    itemBuilder,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    WidgetBuilder? initialLoaderBuilder,
    WidgetBuilder? emptyBuilder,
    WidgetBuilder? loadMoreBuilder,
    WidgetBuilder? noMoreDataBuilder,
    Widget Function(BuildContext context, String? errorMessage)? errorBuilder,
    Widget Function(BuildContext context, VoidCallback onRetry)?
    loadMoreErrorBuilder,
    bool enablePullToRefresh = true,
  }) {
    return AppPagination<T>(
      key: key,
      controller: controller,
      state: state,
      header: header,
      itemBuilder: itemBuilder,
      initialLoaderBuilder: initialLoaderBuilder,
      emptyBuilder: emptyBuilder,
      loadMoreBuilder: loadMoreBuilder,
      noMoreDataBuilder: noMoreDataBuilder,
      errorBuilder: errorBuilder,
      loadMoreErrorBuilder: loadMoreErrorBuilder,
      enablePullToRefresh: enablePullToRefresh,
      builder: (scrollController, internalItemBuilder, itemCount) {
        return GridView.builder(
          controller: scrollController,
          physics: physics ?? const AlwaysScrollableScrollPhysics(),
          padding: padding,
          gridDelegate: gridDelegate,
          itemCount: itemCount,
          itemBuilder: internalItemBuilder,
        );
      },
    );
  }

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

  Widget _buildRefreshable({required Widget child}) {
    if (!widget.enablePullToRefresh) return child;
    return RefreshIndicator(
      color: context.colors.primary,
      backgroundColor: context.colors.surface,
      onRefresh: () async => _effectiveController.refresh(),
      child: child,
    );
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

    /// Footer - Error Loading More
    if (state.hasLoadMoreError) {
      if (widget.loadMoreErrorBuilder != null) {
        return widget.loadMoreErrorBuilder!(
          context,
          () => _effectiveController.loadMore(),
        );
      }
      return Padding(
        padding: AppSpacing.lg.allPadding,
        child: InkWell(
          onTap: () => _effectiveController.loadMore(),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Padding(
            padding: AppSpacing.sm.allPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: context.colors.error,
                ),
                AppSpacing.sm.w,
                Text(
                  state.loadMoreErrorMessage ?? context.l10n.failedToLoadMore,
                  style: context.textTheme.bodyMedium?.colour(
                    context.colors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    /// Footer - Reached Last Page
    if (state.isLastPage) {
      return widget.noMoreDataBuilder?.call(context) ?? const SizedBox.shrink();
    }

    /// Footer - Loading More Progress
    return widget.loadMoreBuilder?.call(context) ??
        widget.initialLoaderBuilder?.call(context) ??
        Padding(
          padding: AppSpacing.lg.allPadding,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: context.colors.primary,
              ),
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PaginationState<T>>(
      valueListenable: _effectiveController,
      builder: (context, state, _) {
        /// 1. Initial Loading (Empty List + Actively Loading)
        if (state.items.isEmpty && state.isLoading) {
          if (widget.header != null) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                widget.header!,
                widget.initialLoaderBuilder?.call(context) ??
                    Padding(
                      padding: AppSpacing.xl.allPadding,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: context.colors.primary,
                        ),
                      ),
                    ),
              ],
            );
          }

          return widget.initialLoaderBuilder?.call(context) ??
              Center(
                child: CircularProgressIndicator(color: context.colors.primary),
              );
        }

        /// 2. Initial Error (Empty List + Has Error)
        if (state.items.isEmpty && state.hasError) {
          final errorWidget =
              widget.errorBuilder?.call(context, state.errorMessage) ??
              Center(
                child: Padding(
                  padding: AppSpacing.xl.allPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: context.colors.error,
                      ),
                      AppSpacing.sm.h,
                      Text(
                        state.errorMessage ?? context.l10n.somethingWentWrong,
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.colour(
                          context.colors.error,
                        ),
                      ),
                      AppSpacing.md.h,
                      TextButton.icon(
                        onPressed: () => _effectiveController.refresh(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(context.l10n.retry),
                      ),
                    ],
                  ),
                ),
              );

          return _buildRefreshable(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (widget.header != null) widget.header!,
                errorWidget,
              ],
            ),
          );
        }

        /// 3. Empty State (Empty List + Idle)
        if (state.items.isEmpty) {
          final emptyWidget =
              widget.emptyBuilder?.call(context) ?? AppStateView.empty();

          return _buildRefreshable(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                if (widget.header != null) widget.header!,
                emptyWidget,
              ],
            ),
          );
        }

        /// 4. Main Paginated List / Grid
        final int headerCount = widget.header != null ? 1 : 0;
        final int footerCount = state.isLastPage ? 0 : 1;
        final int totalItemCount =
            state.items.length + headerCount + footerCount;

        return _buildRefreshable(
          child: widget.builder(
            _effectiveController.scrollController,
            (ctx, idx) => _itemBuilder(ctx, state, idx),
            totalItemCount,
          ),
        );
      },
    );
  }
}
