import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_event.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '/features/auth/data/repositories/auth_repository.dart';
import '/features/auth/data/repositories/user_repository.dart';
import '/features/settings/bloc/admin_settings_cubit.dart';
import '../bloc/bank_accounts/bank_accounts_bloc.dart';
import '../bloc/membership_plans/membership_plans_bloc.dart';
import '../bloc/registration_fee/registration_fee_bloc.dart';
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
  sl.registerFactoryParam<RegistrationFeeBloc, UserRole, void>(
    (role, _) => RegistrationFeeBloc(
      adminSettingsCubit: sl<AdminSettingsCubit>(),
      userRepository: sl<UserRepository>(),
      role: role,
      getCurrentUserId: () => sl<AuthRepository>().currentUserId,
      onPaymentRecorded: () {
        if (sl.isRegistered<AuthBloc>()) {
          sl<AuthBloc>().add(const AuthProfileRefreshRequested());
        }
      },
    ),
  );
}
