import 'package:flutter/material.dart';

import '../states/pagination.state.dart';

class PaginationController<T> extends ValueNotifier<PaginationState<T>> {
  final ScrollController scrollController;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;

  final bool _ownsScrollController;
  bool _isFetchingMore = false;

  PaginationController({
    PaginationState<T>? initialState,
    ScrollController? scrollController,
    this.onRefresh,
    this.onLoadMore,
  }) : scrollController = scrollController ?? ScrollController(),
       _ownsScrollController = scrollController == null,
       super(
         initialState ??
             PaginationState<T>(
               items: [],
               isLoading: false,
               hasError: false,
               hasLoadMoreError: false,
             ),
       ) {
    this.scrollController.addListener(_onScroll);
  }

  void updateState(PaginationState<T> newState) {
    value = newState;
    _checkAndLoadMoreIfNeeded();
  }

  void _onScroll() async {
    if (!scrollController.hasClients) return;

    final position = scrollController.position;

    if (position.maxScrollExtent <= 0) return;

    if (position.pixels >=
        position.maxScrollExtent - position.viewportDimension * 0.2) {
      await loadMore();
    }
  }

  Future<void> loadMore() async {
    if (_isFetchingMore || value.isLoading || value.isLastPage) {
      return;
    }

    try {
      _isFetchingMore = true;
      await onLoadMore?.call();
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<void> refresh() async {
    await onRefresh?.call();
  }

  void _checkAndLoadMoreIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!scrollController.hasClients) return;

      final position = scrollController.position;

      if (position.maxScrollExtent <= 0) {
        await loadMore();
      }
    });
  }

  void scrollToTop({Duration duration = const Duration(milliseconds: 300)}) {
    if (scrollController.hasClients) {
      scrollController.animateTo(0, duration: duration, curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    if (_ownsScrollController) {
      scrollController.dispose();
    }
    super.dispose();
  }
}
