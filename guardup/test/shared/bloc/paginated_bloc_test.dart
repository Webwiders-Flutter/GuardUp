import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/core/error/api_exception.dart';
import 'package:guardup/shared/bloc/pagination/pagination.dart';

typedef _Fetch = Future<({List<int> data, int total})> Function(
  int page,
  String filters,
  String search,
);

class _TestBloc extends PaginatedBloc<int, String> {
  _TestBloc(this.fetch) : super(initialFilters: 'all', pageSize: 2) {
    on<_FiltersChanged>((e, emit) => applyFilters(e.filters, emit));
  }

  _Fetch fetch;
  final calls = <(int, String, String)>[];

  @override
  Future<({List<int> data, int total})> fetchPage({
    required int page,
    required int pageSize,
    required String filters,
    required String search,
  }) {
    calls.add((page, filters, search));
    return fetch(page, filters, search);
  }
}

final class _FiltersChanged extends PaginationEvent {
  const _FiltersChanged(this.filters);
  final String filters;
  @override
  List<Object?> get props => [filters];
}

Future<({List<int> data, int total})> _pages(
  int page,
  String _,
  String _,
) async => switch (page) {
  1 => (data: [1, 2], total: 3),
  2 => (data: [3], total: 3),
  _ => (data: <int>[], total: 3),
};

void main() {
  blocTest<_TestBloc, PaginatedState<int, String>>(
    'load emits loading then success with page 1',
    build: () => _TestBloc(_pages),
    act: (b) => b.add(const PaginationLoadRequested()),
    verify: (b) {
      expect(b.state.pagination.items, [1, 2]);
      expect(b.state.pagination.total, 3);
      expect(b.state.pagination.status.isSuccess, isTrue);
      expect(b.state.pagination.isLastPage, isFalse);
    },
  );

  blocTest<_TestBloc, PaginatedState<int, String>>(
    'next page appends and reaches last page; further requests are ignored',
    build: () => _TestBloc(_pages),
    act: (b) async {
      b.add(const PaginationLoadRequested());
      await Future<void>.delayed(Duration.zero);
      b.add(const PaginationNextPageRequested());
      await Future<void>.delayed(Duration.zero);
      b.add(const PaginationNextPageRequested());
    },
    verify: (b) {
      expect(b.state.pagination.items, [1, 2, 3]);
      expect(b.state.pagination.page, 2);
      expect(b.state.pagination.isLastPage, isTrue);
      expect(b.calls.map((c) => c.$1), [1, 2]);
    },
  );

  blocTest<_TestBloc, PaginatedState<int, String>>(
    'search trims, stores the term and reloads page 1',
    build: () => _TestBloc(_pages),
    act: (b) => b.add(const PaginationSearchChanged('  joe ')),
    verify: (b) {
      expect(b.state.search, 'joe');
      expect(b.calls.single, (1, 'all', 'joe'));
    },
  );

  blocTest<_TestBloc, PaginatedState<int, String>>(
    'typed filters event updates filters and reloads',
    build: () => _TestBloc(_pages),
    act: (b) => b.add(const _FiltersChanged('active')),
    verify: (b) {
      expect(b.state.filters, 'active');
      expect(b.calls.single, (1, 'active', ''));
    },
  );

  blocTest<_TestBloc, PaginatedState<int, String>>(
    'errors become ApiState.failure carrying the ApiException',
    build: () => _TestBloc((_, _, _) async => throw ApiException('boom')),
    act: (b) => b.add(const PaginationLoadRequested()),
    verify: (b) {
      final status = b.state.pagination.status;
      expect(status.isFailure, isTrue);
      expect(status.errorMessageOrNull, 'boom');
    },
  );

  test('a stale page-1 response is dropped when a newer load starts', () async {
    final slow = Completer<({List<int> data, int total})>();
    final bloc = _TestBloc((_, _, search) {
      if (search == 'old') return slow.future;
      return Future.value((data: [9], total: 1));
    });

    bloc.add(const PaginationSearchChanged('old'));
    await Future<void>.delayed(Duration.zero);
    bloc.add(const PaginationSearchChanged('new'));
    await Future<void>.delayed(Duration.zero);
    slow.complete((data: [1, 2], total: 2));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.search, 'new');
    expect(bloc.state.pagination.items, [9]);
    await bloc.close();
  });
}
