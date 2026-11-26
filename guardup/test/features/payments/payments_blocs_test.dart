import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardup/core/error/api_exception.dart';
import 'package:guardup/core/state/api_state.dart';
import 'package:guardup/features/payments/bloc/bank_accounts/bank_accounts_bloc.dart';
import 'package:guardup/features/payments/bloc/membership_plans/membership_plans_bloc.dart';
import 'package:guardup/features/payments/data/model/bank_account_request.model.dart';
import 'package:guardup/features/payments/data/model/membership_plan.model.dart';
import 'package:guardup/features/payments/data/model/user_bank_account.model.dart';
import 'package:guardup/features/payments/data/repositories/bank_account.repository.dart';
import 'package:guardup/features/payments/data/repositories/membership_plan.repository.dart';
import 'package:mocktail/mocktail.dart';

class MockBankAccountRepository extends Mock implements BankAccountRepository {}

class MockMembershipPlanRepository extends Mock
    implements MembershipPlanRepository {}

class FakeBankAccountRequest extends Fake implements BankAccountRequest {}

UserBankAccountModel _makeAccount(String id, {bool isPrimary = false}) {
  return UserBankAccountModel(
    id: id,
    userId: 'user-1',
    accountNumber: '12345678$id',
    accountHolder: 'John Doe',
    bankName: 'Bank $id',
    branch: 'Main',
    ifscCode: 'HDFC0001234',
    isPrimary: isPrimary,
  );
}

MembershipPlanModel _makePlan(
  String id, {
  bool isPopular = false,
}) {
  return MembershipPlanModel(
    id: id,
    name: 'Plan $id',
    pricePerMonth: 999.0,
    discount: 10.0,
    isPopular: isPopular,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBankAccountRequest());
  });

  group('BankAccountsBloc', () {
    late MockBankAccountRepository mockRepo;

    setUp(() {
      mockRepo = MockBankAccountRepository();
    });

    blocTest<BankAccountsBloc, BankAccountsState>(
      'Started emits empty success when userId is null',
      build: () => BankAccountsBloc(mockRepo, getUserId: () => null),
      act: (bloc) => bloc.add(const BankAccountsStarted()),
      expect: () => [
        const BankAccountsState(
          accounts: [],
          loadStatus: ApiState.success(null),
        ),
      ],
      verify: (_) => verifyNever(() => mockRepo.getAll(any())),
    );

    blocTest<BankAccountsBloc, BankAccountsState>(
      'Started loads accounts from repository',
      build: () {
        when(() => mockRepo.getAll('user-1'))
            .thenAnswer((_) async => [_makeAccount('a1', isPrimary: true)]);
        return BankAccountsBloc(mockRepo, getUserId: () => 'user-1');
      },
      act: (bloc) => bloc.add(const BankAccountsStarted()),
      expect: () => [
        const BankAccountsState(loadStatus: ApiState.loading()),
        BankAccountsState(
          accounts: [_makeAccount('a1', isPrimary: true)],
          loadStatus: const ApiState.success(null),
        ),
      ],
    );

    blocTest<BankAccountsBloc, BankAccountsState>(
      'Added marks first account as primary automatically',
      build: () {
        when(() => mockRepo.add('user-1', any()))
            .thenAnswer((_) async => _makeAccount('a1', isPrimary: true));
        return BankAccountsBloc(mockRepo, getUserId: () => 'user-1');
      },
      act: (bloc) => bloc.add(
        const BankAccountAdded(
          BankAccountRequest(
            accountNumber: '12345678a1',
            accountHolder: 'John Doe',
            bankName: 'Bank a1',
            branch: 'Main',
            ifscCode: 'HDFC0001234',
          ),
        ),
      ),
      expect: () => [
        const BankAccountsState(
          lastAction: BankAccountAction.add,
          actionStatus: ApiState.loading(),
        ),
        BankAccountsState(
          accounts: [_makeAccount('a1', isPrimary: true)],
          lastAction: BankAccountAction.add,
          actionStatus: const ApiState.success(null),
        ),
      ],
      verify: (_) {
        final req = verify(() => mockRepo.add('user-1', captureAny()))
            .captured
            .single as BankAccountRequest;
        expect(req.isPrimary, true);
      },
    );

    blocTest<BankAccountsBloc, BankAccountsState>(
      'Updated replaces matching account in list',
      build: () {
        final updated = _makeAccount('a1').copyWith(bankName: 'Updated Bank');
        when(() => mockRepo.update('a1', any()))
            .thenAnswer((_) async => updated);
        return BankAccountsBloc(mockRepo, getUserId: () => 'user-1');
      },
      seed: () => BankAccountsState(
        accounts: [_makeAccount('a1'), _makeAccount('a2')],
        loadStatus: const ApiState.success(null),
      ),
      act: (bloc) => bloc.add(
        const BankAccountUpdated(
          'a1',
          BankAccountRequest(
            accountNumber: '12345678a1',
            accountHolder: 'John Doe',
            bankName: 'Updated Bank',
            branch: 'Main',
            ifscCode: 'HDFC0001234',
          ),
        ),
      ),
      expect: () => [
        isA<BankAccountsState>()
            .having((s) => s.lastAction, 'lastAction', BankAccountAction.update)
            .having((s) => s.actionStatus.isLoading, 'isLoading', true),
        isA<BankAccountsState>()
            .having((s) => s.accounts.first.bankName, 'bankName', 'Updated Bank')
            .having((s) => s.actionStatus.isSuccess, 'isSuccess', true),
      ],
    );

    blocTest<BankAccountsBloc, BankAccountsState>(
      'Deleted optimistically removes account and rolls back on failure',
      build: () {
        when(() => mockRepo.delete('a1'))
            .thenThrow(ApiException('Delete failed'));
        return BankAccountsBloc(mockRepo, getUserId: () => 'user-1');
      },
      seed: () => BankAccountsState(
        accounts: [_makeAccount('a1'), _makeAccount('a2')],
        loadStatus: const ApiState.success(null),
      ),
      act: (bloc) => bloc.add(const BankAccountDeleted('a1')),
      expect: () => [
        isA<BankAccountsState>()
            .having((s) => s.accounts.length, 'accounts length', 1)
            .having((s) => s.actionStatus.isLoading, 'isLoading', true),
        isA<BankAccountsState>()
            .having((s) => s.accounts.length, 'accounts length', 2)
            .having((s) => s.actionStatus.isFailure, 'isFailure', true),
      ],
    );

    blocTest<BankAccountsBloc, BankAccountsState>(
      'PrimarySet updates primary flag and sorts primary first',
      build: () {
        when(() => mockRepo.setPrimary('user-1', 'a2'))
            .thenAnswer((_) async {});
        return BankAccountsBloc(mockRepo, getUserId: () => 'user-1');
      },
      seed: () => BankAccountsState(
        accounts: [
          _makeAccount('a1', isPrimary: true),
          _makeAccount('a2', isPrimary: false),
        ],
        loadStatus: const ApiState.success(null),
      ),
      act: (bloc) => bloc.add(const BankAccountPrimarySet('a2')),
      expect: () => [
        isA<BankAccountsState>()
            .having((s) => s.accounts.first.id, 'first id', 'a2')
            .having((s) => s.accounts.first.isPrimary, 'first primary', true)
            .having((s) => s.actionStatus.isLoading, 'isLoading', true),
        isA<BankAccountsState>()
            .having((s) => s.accounts.first.id, 'first id', 'a2')
            .having((s) => s.actionStatus.isSuccess, 'isSuccess', true),
      ],
    );
  });

  group('MembershipPlansBloc', () {
    late MockMembershipPlanRepository mockRepo;

    setUp(() {
      mockRepo = MockMembershipPlanRepository();
    });

    blocTest<MembershipPlansBloc, MembershipPlansState>(
      'Started loads active plans and auto-selects activePlanId if present',
      build: () {
        when(() => mockRepo.getActive()).thenAnswer(
          (_) async => [
            _makePlan('p1'),
            _makePlan('p2', isPopular: true),
          ],
        );
        return MembershipPlansBloc(mockRepo);
      },
      act: (bloc) =>
          bloc.add(const MembershipPlansStarted(activePlanId: 'p1')),
      expect: () => [
        const MembershipPlansState(
          activePlanId: 'p1',
          loadStatus: ApiState.loading(),
        ),
        MembershipPlansState(
          plans: [_makePlan('p1'), _makePlan('p2', isPopular: true)],
          selectedPlan: _makePlan('p1'),
          activePlanId: 'p1',
          loadStatus: const ApiState.success(null),
        ),
      ],
    );

    blocTest<MembershipPlansBloc, MembershipPlansState>(
      'Started falls back to popular plan when activePlanId is null',
      build: () {
        when(() => mockRepo.getActive()).thenAnswer(
          (_) async => [
            _makePlan('p1'),
            _makePlan('p2', isPopular: true),
          ],
        );
        return MembershipPlansBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const MembershipPlansStarted()),
      expect: () => [
        const MembershipPlansState(loadStatus: ApiState.loading()),
        MembershipPlansState(
          plans: [_makePlan('p1'), _makePlan('p2', isPopular: true)],
          selectedPlan: _makePlan('p2', isPopular: true),
          loadStatus: const ApiState.success(null),
        ),
      ],
    );

    blocTest<MembershipPlansBloc, MembershipPlansState>(
      'PlanSelected updates selectedPlan',
      build: () => MembershipPlansBloc(mockRepo),
      seed: () => MembershipPlansState(
        plans: [_makePlan('p1'), _makePlan('p2')],
        selectedPlan: _makePlan('p1'),
        loadStatus: const ApiState.success(null),
      ),
      act: (bloc) => bloc.add(MembershipPlanSelected(_makePlan('p2'))),
      expect: () => [
        MembershipPlansState(
          plans: [_makePlan('p1'), _makePlan('p2')],
          selectedPlan: _makePlan('p2'),
          loadStatus: const ApiState.success(null),
        ),
      ],
    );
  });
}
