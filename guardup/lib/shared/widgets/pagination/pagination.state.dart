import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/state/api_state.dart';

part 'pagination.state.freezed.dart';

@freezed
sealed class PaginationState<T> with _$PaginationState<T> {
  const PaginationState._();

  const factory PaginationState({
    @Default([]) List<T> items,
    @Default(ApiState.initial()) ApiState<void> status,
    @Default(ApiState.initial()) ApiState<void> loadMoreStatus,
    @Default(1) int page,
    @Default(10) int pageSize,
    @Default(0) int total,
    @Default(null) bool? explicitIsLastPage,
  }) = _PaginationState<T>;

  /// True when the first page or refresh is actively loading.
  bool get isLoading => status.isLoading;

  /// True when page 1 or refresh resulted in an error.
  bool get hasError => status.isFailure;
  String? get errorMessage => status.errorMessageOrNull;

  /// True when page 2+ (infinite scroll) is actively loading.
  bool get isLoadingMore => loadMoreStatus.isLoading;

  /// True when loading more (page 2+) resulted in an error.
  bool get hasLoadMoreError => loadMoreStatus.isFailure;
  String? get loadMoreErrorMessage => loadMoreStatus.errorMessageOrNull;

  /// Automatically computes if last page is reached based on total count
  /// (`items.length >= total`), or falls back to explicit `isLastPage` flag.
  bool get isLastPage {
    if (explicitIsLastPage != null) return explicitIsLastPage!;
    if (total > 0) {
      return items.length >= total;
    }
    return items.isNotEmpty && items.length < pageSize;
  }
}
