import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/core/constants/app_constants.dart';
import 'package:guardup/core/error/api_exception.dart';
import 'package:guardup/core/state/api_state.dart';
import 'package:guardup/features/auth/data/enum/user_status.enum.dart';
import 'package:guardup/features/company/bloc/companies/companies_bloc.dart';
import 'package:guardup/features/company/data/model/company.model.dart';
import 'package:guardup/features/company/data/model/company_filters.model.dart';
import 'package:guardup/features/company/data/repositories/company.repository.dart';
import 'package:guardup/shared/bloc/pagination/pagination.dart';
import 'package:mocktail/mocktail.dart';

class MockCompanyRepository extends Mock implements CompanyRepository {}

class FakeCompanyFilters extends Fake implements CompanyFilters {}

CompanyModel _makeCompany(String id) {
  return CompanyModel(
    id: id,
    userId: 'user-$id',
    companyName: 'Shield Corp $id',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCompanyFilters());
  });

  group('CompaniesBloc', () {
    late MockCompanyRepository mockRepo;

    setUp(() {
      mockRepo = MockCompanyRepository();
    });

    test('initial state uses CompanyFilters.customerDefault', () {
      final bloc = CompaniesBloc(mockRepo);
      expect(bloc.state.filters, CompanyFilters.customerDefault);
      expect(bloc.state.filters.statuses, [UserStatus.active]);
      bloc.close();
    });

    blocTest<CompaniesBloc, CompaniesState>(
      'loads page 1 with customerDefault filters',
      build: () {
        when(
          () => mockRepo.getPaginated(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filters: any(named: 'filters'),
            search: any(named: 'search'),
          ),
        ).thenAnswer((_) async => (data: [_makeCompany('c1')], total: 1));
        return CompaniesBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const PaginationLoadRequested()),
      expect: () => [
        isA<CompaniesState>()
            .having((s) => s.pagination.isLoading, 'isLoading', true),
        isA<CompaniesState>()
            .having((s) => s.pagination.status.isSuccess, 'isSuccess', true)
            .having((s) => s.pagination.items.length, 'items length', 1)
            .having((s) => s.pagination.items.first.id, 'first id', 'c1'),
      ],
      verify: (_) {
        verify(
          () => mockRepo.getPaginated(
            page: 1,
            pageSize: AppConstants.paginationLimit,
            filters: CompanyFilters.customerDefault,
            search: null,
          ),
        ).called(1);
      },
    );

    blocTest<CompaniesBloc, CompaniesState>(
      'CompanyFiltersChanged updates filters and reloads page 1',
      build: () {
        when(
          () => mockRepo.getPaginated(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filters: any(named: 'filters'),
            search: any(named: 'search'),
          ),
        ).thenAnswer((_) async => (data: [_makeCompany('c2')], total: 1));
        return CompaniesBloc(mockRepo);
      },
      act: (bloc) => bloc.add(
        const CompanyFiltersChanged(
          CompanyFilters(statuses: [UserStatus.pendingApproval]),
        ),
      ),
      expect: () => [
        isA<CompaniesState>().having(
          (s) => s.filters.statuses,
          'filters.statuses',
          [UserStatus.pendingApproval],
        ),
        isA<CompaniesState>()
            .having((s) => s.pagination.isLoading, 'isLoading', true),
        isA<CompaniesState>().having(
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
            filters: const CompanyFilters(statuses: [UserStatus.pendingApproval]),
            search: null,
          ),
        ).called(1);
      },
    );

    blocTest<CompaniesBloc, CompaniesState>(
      'search trims query and passes to repository',
      build: () {
        when(
          () => mockRepo.getPaginated(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filters: any(named: 'filters'),
            search: any(named: 'search'),
          ),
        ).thenAnswer((_) async => (data: <CompanyModel>[], total: 0));
        return CompaniesBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const PaginationSearchChanged('  alpha  ')),
      verify: (_) {
        verify(
          () => mockRepo.getPaginated(
            page: 1,
            pageSize: AppConstants.paginationLimit,
            filters: CompanyFilters.customerDefault,
            search: 'alpha',
          ),
        ).called(1);
      },
    );

    blocTest<CompaniesBloc, CompaniesState>(
      'emits failure carrying ApiException when repository throws',
      build: () {
        when(
          () => mockRepo.getPaginated(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filters: any(named: 'filters'),
            search: any(named: 'search'),
          ),
        ).thenThrow(ApiException('Failed to fetch', type: ApiErrorType.server));
        return CompaniesBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const PaginationLoadRequested()),
      expect: () => [
        isA<CompaniesState>()
            .having((s) => s.pagination.isLoading, 'isLoading', true),
        isA<CompaniesState>().having(
          (s) => s.pagination.status,
          'status',
          isA<ApiFailure<void>>()
              .having((f) => f.message, 'message', 'Failed to fetch')
              .having((f) => f.error, 'error', isA<ApiException>()),
        ),
      ],
    );
  });
}
