import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/services/file_storage/file_storage.service.dart';
import '../auth.dart';

void registerAuthDependencies(GetIt sl) {
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      client: sl<SupabaseClient>(),
    ),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepository(
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
  sl.registerFactory<AuthFormBloc>(
    () => AuthFormBloc(
      authRepository: sl<AuthRepository>(),
      userRepository: sl<UserRepository>(),
      onAuthenticated: () =>
          sl<AuthBloc>().add(const AuthProfileRefreshRequested()),
      onPendingSignUp: (role, _) =>
          sl<AuthBloc>().add(AuthRoleSelected(role)),
    ),
  );
  sl.registerFactory<AccountBloc>(
    () => AccountBloc(
      authRepository: sl<AuthRepository>(),
      userRepository: sl<UserRepository>(),
      fileStorageService: sl<FileStorageService>(),
      getCurrentUserId: () => sl<AuthRepository>().currentUserId,
      onAccountUpdated: () =>
          sl<AuthBloc>().add(const AuthProfileRefreshRequested()),
      onAccountDeleted: () =>
          sl<AuthBloc>().add(const AuthSignOutRequested()),
    ),
  );
}
