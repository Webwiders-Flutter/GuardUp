import 'package:equatable/equatable.dart';

import '/core/constants/app_constants.dart';
import '/core/state/api_state.dart';
import '/shared/widgets/pagination/pagination.state.dart';

/// State of a [PaginatedBloc]: the filters object, the search term, the page
/// data and the status of one-shot item actions (delete, toggle).
class PaginatedState<T, F> extends Equatable {
  const PaginatedState({
    required this.filters,
    required this.pagination,
    this.search = '',
    this.actionStatus = const ApiState.initial(),
  });

  /// Non-const on purpose: a const default cannot carry [T] and would infer
  /// `PaginationState<Never>`.
  factory PaginatedState.initial(
    F filters, {
    int pageSize = AppConstants.paginationLimit,
  }) => PaginatedState<T, F>(
    filters: filters,
    pagination: PaginationState<T>(pageSize: pageSize),
  );

  final F filters;
  final String search;
  final PaginationState<T> pagination;

  /// One-shot actions on items (delete, toggle). Goes
  /// `initial → loading → success | failure` on every attempt so listeners
  /// fire even for repeated identical failures.
  final ApiState<void> actionStatus;

  PaginatedState<T, F> copyWith({
    F? filters,
    String? search,
    PaginationState<T>? pagination,
    ApiState<void>? actionStatus,
  }) => PaginatedState<T, F>(
    filters: filters ?? this.filters,
    search: search ?? this.search,
    pagination: pagination ?? this.pagination,
    actionStatus: actionStatus ?? this.actionStatus,
  );

  @override
  List<Object?> get props => [filters, search, pagination, actionStatus];
}
