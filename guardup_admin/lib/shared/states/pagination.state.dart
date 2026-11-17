import 'package:freezed_annotation/freezed_annotation.dart';
part 'pagination.state.freezed.dart';

@freezed
abstract class PaginationState<T> with _$PaginationState<T> {
  const PaginationState._();

  const factory PaginationState({
    @Default([]) List<T> items,
    @Default(false) bool isLoading,
    @Default(false) bool hasError,
    @Default(false) bool hasLoadMoreError,
    @Default(1) int page,
    @Default(10) int pageSize,
    @Default(0) int total,
    @Default(null) bool? explicitIsLastPage,
  }) = _PaginationState<T>;

  /// Automatically computes if last page is reached based on total count
  /// (`items.length >= total`), or falls back to explicit `isLastPage` flag.
  bool get isLastPage {
    if (total > 0) {
      return items.length >= total;
    }
    return items.length < pageSize;
  }
}
