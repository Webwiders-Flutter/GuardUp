import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/app/gate/gate.dart';
import '../bloc/admin_settings_cubit.dart';
import '../data/repositories/admin_settings.repository.dart';

void registerAdminSettingsDependencies(GetIt sl) {
  sl.registerLazySingleton<AdminSettingsRepository>(
    () => AdminSettingsRepository(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<AdminSettingsCubit>(
    () => AdminSettingsCubit(sl<AdminSettingsRepository>()),
  );
  sl.registerLazySingleton<AppGateCubit>(
    () => AppGateCubit(sl<AdminSettingsCubit>()),
  );
}
