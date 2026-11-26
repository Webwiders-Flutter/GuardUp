import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/features/auth/domain/repositories/auth_repository.dart';
import '../bloc/bank_accounts/bank_accounts_bloc.dart';
import '../bloc/membership_plans/membership_plans_bloc.dart';
import '../data/repositories/bank_account.repository.dart';
import '../data/repositories/membership_plan.repository.dart';

void registerPaymentsDependencies(GetIt sl) {
  sl.registerLazySingleton<BankAccountRepository>(
    () => BankAccountRepository(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<MembershipPlanRepository>(
    () => MembershipPlanRepository(sl<SupabaseClient>()),
  );
  sl.registerFactory<BankAccountsBloc>(
    () => BankAccountsBloc(
      sl<BankAccountRepository>(),
      getUserId: () => sl<AuthRepository>().currentUserId,
    ),
  );
  sl.registerFactory<MembershipPlansBloc>(
    () => MembershipPlansBloc(sl<MembershipPlanRepository>()),
  );
}
