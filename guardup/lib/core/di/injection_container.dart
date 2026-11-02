import 'package:get_it/get_it.dart';

import '/core/services/local_storage/local_storage.service.dart';
import '/core/services/local_storage/storage.dart';
import '/features/auth/auth.dart';
import '/shared/functionalities/connectivity/connectivity.dart';
import '/shared/functionalities/language/language.dart';

/// Global service locator instance.
final sl = GetIt.instance;

/// Initializes application-wide dependencies and registers them with [GetIt].
Future<void> initDependencies() async {
  // ------------------------------------------------------------
  // Storage & Core Services
  // ------------------------------------------------------------
  sl.registerLazySingleton<LocalStorage>(
    () => PrefsStorageService.instance,
  );

  // ------------------------------------------------------------
  // Auth
  // ------------------------------------------------------------
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      authRepository:
          sl.isRegistered<AuthRepository>() ? sl<AuthRepository>() : null,
      userRepository:
          sl.isRegistered<UserRepository>() ? sl<UserRepository>() : null,
    ),
  );

  // ------------------------------------------------------------
  // Connectivity
  // ------------------------------------------------------------
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityServiceImpl(),
  );

  sl.registerFactory<ConnectivityCubit>(
    () => ConnectivityCubit(service: sl<ConnectivityService>()),
  );

  // ------------------------------------------------------------
  // Language
  // ------------------------------------------------------------
  sl.registerFactory<LanguageCubit>(
    () => LanguageCubit(storage: sl<LocalStorage>()),
  );
}
