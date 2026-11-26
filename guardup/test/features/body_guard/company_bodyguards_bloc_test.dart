import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/core/constants/app_constants.dart';
import 'package:guardup/core/error/api_exception.dart';
import 'package:guardup/core/state/api_state.dart';
import 'package:guardup/features/auth/data/enum/user_status.enum.dart';
import 'package:guardup/features/body_guard/bloc/company_bodyguards/company_bodyguards_bloc.dart';
import 'package:guardup/features/body_guard/data/model/body_guard.model.dart';
import 'package:guardup/features/body_guard/data/model/bodyguard_filters.model.dart';
import 'package:guardup/features/body_guard/data/repositories/bodyguard.repository.dart';
import 'package:guardup/shared/bloc/pagination/pagination.dart';
import 'package:guardup/shared/widgets/pagination/pagination.state.dart';
import 'package:mocktail/mocktail.dart';

class MockBodyguardRepository extends Mock implements BodyguardRepository {}

class FakeBodyguardFilters extends Fake implements BodyguardFilters {}

BodyGuardModel _makeGuard(String id) => BodyGuardModel(
  id: id,
  companyId: 'comp-1',
  name: 'Guard $id',
  hourlyRate: 40.0,
);

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBodyguardFilters());
  });

  group('CompanyBodyguardsBloc', () {
    late MockBodyguardRepository mockRepo;

    setUp(() {
      mockRepo = MockBodyguardRepository();
      when(() => mockRepo.getMyCompanyId('user-comp'))
          .thenAnswer((_) async => 'comp-1');
    });

    blocTest<CompanyBodyguardsBloc, CompanyBodyguardsState>(
      'resolves and caches companyId across multiple loads',
      build: () {
        when(
          () => mockRepo.getPaginated(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filters: any(named: 'filters'),
            search: any(named: 'search'),
          ),
        ).thenAnswer((_) async => (data: [_makeGuard('g1')], total: 1));
        return CompanyBodyguardsBloc(mockRepo, companyUserId: 'user-comp');
      },
      act: (bloc) async {
        bloc.add(const PaginationLoadRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PaginationSearchChanged('alex'));
      },
      verify: (_) {
        verify(() => mockRepo.getMyCompanyId('user-comp')).called(1);
        verify(
          () => mockRepo.getPaginated(
            page: 1,
            pageSize: AppConstants.paginationLimit,
            filters: const BodyguardFilters(companyId: 'comp-1'),
            search: null,
          ),
        ).called(1);
        verify(
          () => mockRepo.getPaginated(
            page: 1,
            pageSize: AppConstants.paginationLimit,
            filters: const BodyguardFilters(companyId: 'comp-1'),
            search: 'alex',
          ),
        ).called(1);
      },
    );

    blocTest<CompanyBodyguardsBloc, CompanyBodyguardsState>(
      'maps pendingApproval status filter to [pendingApproval, incomplete]',
      build: () {
        when(
          () => mockRepo.getPaginated(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filters: any(named: 'filters'),
            search: any(named: 'search'),
          ),
        ).thenAnswer((_) async => (data: <BodyGuardModel>[], total: 0));
        return CompanyBodyguardsBloc(mockRepo, companyUserId: 'user-comp');
      },
      act: (bloc) => bloc.add(
        const CompanyBodyguardsStatusChanged(UserStatus.pendingApproval),
      ),
      verify: (_) {
        verify(
          () => mockRepo.getPaginated(
            page: 1,
            pageSize: AppConstants.paginationLimit,
            filters: const BodyguardFilters(
              companyId: 'comp-1',
              statuses: [UserStatus.pendingApproval, UserStatus.incomplete],
            ),
            search: null,
          ),
        ).called(1);
      },
    );

    blocTest<CompanyBodyguardsBloc, CompanyBodyguardsState>(
      'optimistically removes bodyguard on delete and emits success',
      build: () {
        when(() => mockRepo.delete('g1')).thenAnswer((_) async {});
        return CompanyBodyguardsBloc(mockRepo, companyUserId: 'user-comp');
      },
      seed: () => CompanyBodyguardsState(
        filters: const BodyguardFilters(),
        pagination: PaginationState<BodyGuardModel>(
          items: [_makeGuard('g1'), _makeGuard('g2')],
          total: 2,
          page: 1,
          status: const ApiState.success(null),
        ),
      ),
      act: (bloc) => bloc.add(CompanyBodyguardDeleted(_makeGuard('g1'))),
      expect: () => [
        isA<CompanyBodyguardsState>()
            .having((s) => s.pagination.items.length, 'items length', 1)
            .having((s) => s.pagination.total, 'total', 1)
            .having((s) => s.actionStatus.isLoading, 'isLoading', true),
        isA<CompanyBodyguardsState>()
            .having((s) => s.pagination.items.length, 'items length', 1)
            .having((s) => s.actionStatus.isSuccess, 'isSuccess', true),
      ],
      verify: (_) {
        verify(() => mockRepo.delete('g1')).called(1);
      },
    );

    blocTest<CompanyBodyguardsBloc, CompanyBodyguardsState>(
      'rolls back removed bodyguard and emits failure on delete error',
      build: () {
        when(() => mockRepo.delete('g1'))
            .thenThrow(ApiException('Permission denied'));
        return CompanyBodyguardsBloc(mockRepo, companyUserId: 'user-comp');
      },
      seed: () => CompanyBodyguardsState(
        filters: const BodyguardFilters(),
        pagination: PaginationState<BodyGuardModel>(
          items: [_makeGuard('g1'), _makeGuard('g2')],
          total: 2,
          page: 1,
          status: const ApiState.success(null),
        ),
      ),
      act: (bloc) => bloc.add(CompanyBodyguardDeleted(_makeGuard('g1'))),
      expect: () => [
        isA<CompanyBodyguardsState>()
            .having((s) => s.pagination.items.length, 'items length', 1)
            .having((s) => s.actionStatus.isLoading, 'isLoading', true),
        isA<CompanyBodyguardsState>()
            .having((s) => s.pagination.items.length, 'items length', 2)
            .having((s) => s.pagination.total, 'total', 2)
            .having(
              (s) => s.actionStatus,
              'actionStatus',
              isA<ApiFailure<void>>()
                  .having((f) => f.message, 'message', 'Permission denied')
                  .having((f) => f.error, 'error', isA<ApiException>()),
            ),
      ],
    );
  });
}
