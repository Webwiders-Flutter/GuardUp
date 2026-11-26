import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/core/constants/app_constants.dart';
import 'package:guardup/core/error/api_exception.dart';
import 'package:guardup/core/state/api_state.dart';
import 'package:guardup/features/auth/data/enum/user_status.enum.dart';
import 'package:guardup/features/body_guard/bloc/bodyguards/bodyguards_bloc.dart';
import 'package:guardup/features/body_guard/data/enum/bodyguard_availability_status.enum.dart';
import 'package:guardup/features/body_guard/data/model/body_guard.model.dart';
import 'package:guardup/features/body_guard/data/model/bodyguard_filters.model.dart';
import 'package:guardup/features/body_guard/data/repositories/bodyguard.repository.dart';
import 'package:guardup/shared/bloc/pagination/pagination.dart';
import 'package:mocktail/mocktail.dart';

class MockBodyguardRepository extends Mock implements BodyguardRepository {}

class FakeBodyguardFilters extends Fake implements BodyguardFilters {}

BodyGuardModel _makeGuard(String id) =>
    BodyGuardModel(id: id, name: 'Guard $id', hourlyRate: 50.0);

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBodyguardFilters());
  });

  group('BodyguardsBloc', () {
    late MockBodyguardRepository mockRepo;

    setUp(() {
      mockRepo = MockBodyguardRepository();
    });

    test('initial state defaults to ACTIVE solo guards', () {
      final bloc = BodyguardsBloc(mockRepo);
      expect(bloc.state.filters, BodyguardFilters.customerDefault);
      bloc.close();
    });

    blocTest<BodyguardsBloc, BodyguardsState>(
      'loads page 1 with initialFilters',
      build: () {
        when(
          () => mockRepo.getPaginated(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filters: any(named: 'filters'),
            search: any(named: 'search'),
          ),
        ).thenAnswer((_) async => (data: [_makeGuard('g1')], total: 1));
        return BodyguardsBloc(
          mockRepo,
          initialFilters: const BodyguardFilters(
            companyId: 'comp-1',
            statuses: [UserStatus.active],
          ),
        );
      },
      act: (bloc) => bloc.add(const PaginationLoadRequested()),
      expect: () => [
        isA<BodyguardsState>().having(
          (s) => s.pagination.isLoading,
          'isLoading',
          true,
        ),
        isA<BodyguardsState>()
            .having((s) => s.pagination.status.isSuccess, 'isSuccess', true)
            .having((s) => s.pagination.items.length, 'items length', 1)
            .having((s) => s.pagination.items.first.id, 'first id', 'g1'),
      ],
      verify: (_) {
        verify(
          () => mockRepo.getPaginated(
            page: 1,
            pageSize: AppConstants.paginationLimit,
            filters: const BodyguardFilters(
              companyId: 'comp-1',
              statuses: [UserStatus.active],
            ),
            search: null,
          ),
        ).called(1);
      },
    );

    blocTest<BodyguardsBloc, BodyguardsState>(
      'BodyguardsFiltersChanged updates filters and reloads page 1',
      build: () {
        when(
          () => mockRepo.getPaginated(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filters: any(named: 'filters'),
            search: any(named: 'search'),
          ),
        ).thenAnswer((_) async => (data: [_makeGuard('g2')], total: 1));
        return BodyguardsBloc(mockRepo);
      },
      act: (bloc) => bloc.add(
        const BodyguardsFiltersChanged(
          BodyguardFilters(
            statuses: [UserStatus.active],
            availability: BodyguardAvailabilityStatus.available,
          ),
        ),
      ),
      expect: () => [
        isA<BodyguardsState>().having(
          (s) => s.filters.availability,
          'availability',
          BodyguardAvailabilityStatus.available,
        ),
        isA<BodyguardsState>().having(
          (s) => s.pagination.isLoading,
          'isLoading',
          true,
        ),
        isA<BodyguardsState>().having(
          (s) => s.pagination.status.isSuccess,
          'isSuccess',
          true,
        ),
      ],
      verify: (_) {
        verify(
          () => mockRepo.getPaginated(
            page: 1,
            pageSize: AppConstants.paginationLimit,
            filters: const BodyguardFilters(
              statuses: [UserStatus.active],
              availability: BodyguardAvailabilityStatus.available,
            ),
            search: null,
          ),
        ).called(1);
      },
    );

    blocTest<BodyguardsBloc, BodyguardsState>(
      'search trims query and passes to repository',
      build: () {
        when(
          () => mockRepo.getPaginated(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filters: any(named: 'filters'),
            search: any(named: 'search'),
          ),
        ).thenAnswer((_) async => (data: <BodyGuardModel>[], total: 0));
        return BodyguardsBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const PaginationSearchChanged('  john  ')),
      verify: (_) {
        verify(
          () => mockRepo.getPaginated(
            page: 1,
            pageSize: AppConstants.paginationLimit,
            filters: BodyguardFilters.customerDefault,
            search: 'john',
          ),
        ).called(1);
      },
    );

    blocTest<BodyguardsBloc, BodyguardsState>(
      'emits failure carrying ApiException when repository throws',
      build: () {
        when(
          () => mockRepo.getPaginated(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filters: any(named: 'filters'),
            search: any(named: 'search'),
          ),
        ).thenThrow(ApiException('Database error', type: ApiErrorType.server));
        return BodyguardsBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const PaginationLoadRequested()),
      expect: () => [
        isA<BodyguardsState>().having(
          (s) => s.pagination.isLoading,
          'isLoading',
          true,
        ),
        isA<BodyguardsState>().having(
          (s) => s.pagination.status,
          'status',
          isA<ApiFailure<void>>()
              .having((f) => f.message, 'message', 'Database error')
              .having((f) => f.error, 'error', isA<ApiException>()),
        ),
      ],
    );
  });
}
