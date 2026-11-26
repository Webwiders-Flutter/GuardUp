import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bloc/services_bloc.dart';
import '../bloc/services_catalog_cubit.dart';
import '../data/repositories/services.repository.dart';

void registerServicesDependencies(GetIt sl) {
  sl.registerLazySingleton<ServicesRepository>(
    () => ServicesRepository(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<ServicesCatalogCubit>(
    () => ServicesCatalogCubit(sl<ServicesRepository>()),
  );
  sl.registerFactory<ServicesBloc>(
    () => ServicesBloc(sl<ServicesRepository>()),
  );
}
