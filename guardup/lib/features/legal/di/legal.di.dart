import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '../bloc/contact_us/contact_us_bloc.dart';
import '../bloc/legal_content/legal_content_bloc.dart';
import '../data/repositories/contact_us.repository.dart';
import '../data/repositories/legal_content.repository.dart';

void registerLegalDependencies(GetIt sl) {
  sl.registerLazySingleton<LegalContentRepository>(
    () => LegalContentRepository(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<ContactUsRepository>(
    () => ContactUsRepository(sl<SupabaseClient>()),
  );

  sl.registerFactory<LegalContentBloc>(
    () => LegalContentBloc(
      repository: sl<LegalContentRepository>(),
      getCurrentRole: () => sl.isRegistered<AuthBloc>()
          ? sl<AuthBloc>().state.sessionRole
          : UserRole.customer,
    ),
  );
  sl.registerFactory<ContactUsBloc>(
    () => ContactUsBloc(
      repository: sl<ContactUsRepository>(),
      getCurrentUserId: () => sl<SupabaseClient>().auth.currentUser?.id,
      getCurrentRole: () => sl.isRegistered<AuthBloc>()
          ? sl<AuthBloc>().state.sessionRole
          : UserRole.customer,
    ),
  );
}
