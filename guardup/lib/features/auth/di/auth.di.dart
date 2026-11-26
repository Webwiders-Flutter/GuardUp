import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/services/file_storage/file_storage.service.dart';
import '../auth.dart';

void registerAuthDependencies(GetIt sl) {
  sl.registerLazySingleton<AuthRepository>(
    () => SupabaseAuthRepository(
      client: sl<SupabaseClient>(),
    ),
  );
  sl.registerLazySingleton<UserRepository>(
    () => SupabaseUserRepository(
      sl<FileStorageService>(),
      client: sl<SupabaseClient>(),
    ),
  );
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      authRepository: sl<AuthRepository>(),
      userRepository: sl<UserRepository>(),
    ),
  );
}
