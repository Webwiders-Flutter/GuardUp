import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/features/auth/data/enum/user_status.enum.dart';
import '../bloc/bodyguard_details/bodyguard_details_bloc.dart';
import '../bloc/bodyguards/bodyguards_bloc.dart';
import '../bloc/company_bodyguards/company_bodyguards_bloc.dart';
import '../data/model/body_guard.model.dart';
import '../data/model/bodyguard_filters.model.dart';
import '../data/repositories/availability.repository.dart';
import '../data/repositories/bodyguard.repository.dart';

void registerBodyguardDependencies(GetIt sl) {
  sl.registerLazySingleton<BodyguardRepository>(
    () => BodyguardRepository(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<AvailabilityRepository>(
    () => AvailabilityRepository(sl<SupabaseClient>()),
  );
  sl.registerFactoryParam<CompanyBodyguardsBloc, String, void>(
    (companyUserId, _) => CompanyBodyguardsBloc(
      sl<BodyguardRepository>(),
      companyUserId: companyUserId,
    ),
  );
  sl.registerFactoryParam<BodyguardsBloc, BodyguardFilters?, void>(
    (initialFilters, _) => BodyguardsBloc(
      sl<BodyguardRepository>(),
      initialFilters:
          initialFilters ??
          const BodyguardFilters(statuses: [UserStatus.active]),
    ),
  );
  sl.registerFactoryParam<BodyguardDetailsBloc, String, BodyGuardModel?>(
    (bodyguardId, preview) => BodyguardDetailsBloc(
      sl<BodyguardRepository>(),
      bodyguardId: bodyguardId,
      preview: preview,
    ),
  );
}
