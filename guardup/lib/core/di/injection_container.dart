import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import '/core/config/admin_settings/di/admin_settings.di.dart';
import '/core/services/document_submission/document_submission_service.dart';
import '/core/services/file_storage/file_storage.service.dart';
import '/core/services/file_storage/supabase_file_storage.service.dart';
import '/core/services/local_storage/local_storage.service.dart';
import '/core/services/local_storage/storage.dart';
import '/core/services/location/address_search_service.dart';
import '/features/auth/auth.dart';
import '/features/auth/di/auth.di.dart';
import '/features/body_guard/di/body_guard.di.dart';
import '/features/company/di/company.di.dart';
import '/features/notifications/di/notifications.di.dart';
import '/features/notifications/notifications.dart';
import '/features/services/di/services.di.dart';
import '/shared/functionalities/connectivity/connectivity.dart';
import '/shared/functionalities/language/language.dart';

/// Global service locator instance.
final sl = GetIt.instance;

/// Initializes application-wide dependencies and registers them with [GetIt].
Future<void> initDependencies() async {
  // ------------------------------------------------------------
  // Storage & Core Services
  // ------------------------------------------------------------
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<GoTrueClient>(() => sl<SupabaseClient>().auth);
  sl.registerLazySingleton<LocalStorage>(() => PrefsStorageService.instance);
  sl.registerLazySingleton<FileStorageService>(
    () => SupabaseFileStorageService(),
  );
  sl.registerLazySingleton<AddressSearchService>(
    () => AddressSearchService(),
  );
  sl.registerLazySingleton<DocumentSubmissionService>(
    () => SupabaseDocumentSubmissionService(
      fileStorageService: sl<FileStorageService>(),
      userRepository: sl<UserRepository>(),
    ),
  );

  // ------------------------------------------------------------
  // Connectivity & Language
  // ------------------------------------------------------------
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityServiceImpl(),
  );
  sl.registerFactory<ConnectivityCubit>(
    () => ConnectivityCubit(service: sl<ConnectivityService>()),
  );
  sl.registerFactory<LanguageCubit>(
    () => LanguageCubit(storage: sl<LocalStorage>()),
  );

  // ------------------------------------------------------------
  // Feature dependencies
  // ------------------------------------------------------------
  registerAdminSettingsDependencies(sl);
  registerAuthDependencies(sl);
  registerServicesDependencies(sl);
  registerBodyguardDependencies(sl);
  registerCompanyDependencies(sl);
  registerNotificationsDependencies(sl);

  // Synchronize notifications & devices on auth state changes
  sl<AuthBloc>().stream.listen((authState) {
    final userId = authState.user?.id;
    if (authState.isAuthenticated && userId != null && userId.isNotEmpty) {
      sl<UnreadNotificationCountCubit>().loadCount(userId);
      sl<UserDeviceCubit>().syncCurrentDevice(userId: userId);
    } else if (authState.isUnauthenticated) {
      sl<UnreadNotificationCountCubit>().clearAll();
      sl<UserDeviceCubit>().clearCurrentDevice();
    }
  });

  // Listen to FCM token refresh events automatically
  sl<UserDeviceCubit>().listenToTokenRefresh(
    () => sl<AuthBloc>().state.user?.id ?? '',
  );
}
