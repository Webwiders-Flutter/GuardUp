import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/bank_account.repository.dart';
import '../data/repositories/membership_plan.repository.dart';

void registerPaymentsDependencies(GetIt sl) {
  sl.registerLazySingleton<BankAccountRepository>(
    () => BankAccountRepository(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<MembershipPlanRepository>(
    () => MembershipPlanRepository(sl<SupabaseClient>()),
  );
}
