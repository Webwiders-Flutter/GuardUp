import 'package:equatable/equatable.dart';

/// Base events understood by every [PaginatedBloc].
///
/// Not generic on purpose: `on<SomeEvent<F>>` would not match
/// `add(SomeEvent())` (runtime type `SomeEvent<dynamic>`) and bloc would throw
/// "add(...) was called without a registered event handler". Filters live in
/// state; feature blocs change them through their own typed events.
///
/// Not sealed: feature blocs extend it with their own events.
abstract class PaginationEvent extends Equatable {
  const PaginationEvent();

  @override
  List<Object?> get props => const [];
}

/// (Re)loads page 1 with the current filters and search.
final class PaginationLoadRequested extends PaginationEvent {
  const PaginationLoadRequested();
}

/// Replaces the search term and reloads page 1.
final class PaginationSearchChanged extends PaginationEvent {
  const PaginationSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Appends the next page, unless one is already loading or the list is complete.
final class PaginationNextPageRequested extends PaginationEvent {
  const PaginationNextPageRequested();
}
