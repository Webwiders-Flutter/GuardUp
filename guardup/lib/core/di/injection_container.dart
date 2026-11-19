import 'package:get_it/get_it.dart';

import '/core/services/admin_settings/admin_settings.service.dart';
import '/core/services/document_submission/document_submission_service.dart';
import '/core/services/file_storage/file_storage.service.dart';
import '/core/services/file_storage/supabase_file_storage.service.dart';
import '/core/services/local_storage/local_storage.service.dart';
import '/core/services/local_storage/storage.dart';
import '/core/services/location/address_search_service.dart';
import '/features/auth/auth.dart';
import '/features/notifications/notifications.dart';
import '/shared/functionalities/connectivity/connectivity.dart';
import '/shared/functionalities/language/language.dart';

/// Global service locator instance.
final sl = GetIt.instance;

/// Initializes application-wide dependencies and registers them with [GetIt].
Future<void> initDependencies() async {
  // ------------------------------------------------------------
  // Storage & Core Services
  // ------------------------------------------------------------
  sl.registerLazySingleton<LocalStorage>(() => PrefsStorageService.instance);
  sl.registerLazySingleton<AdminSettingsService>(
    () => AdminSettingsService.instance,
  );
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
  // Auth & User Repositories
  // ------------------------------------------------------------
  sl.registerLazySingleton<AuthRepository>(() => SupabaseAuthRepository());
  sl.registerLazySingleton<UserRepository>(
    () => SupabaseUserRepository(sl<FileStorageService>()),
  );

  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      authRepository: sl<AuthRepository>(),
      userRepository: sl<UserRepository>(),
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

  // ------------------------------------------------------------
  // Notifications & User Devices
  // ------------------------------------------------------------
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(),
  );
  sl.registerLazySingleton<UserDeviceRepository>(
    () => UserDeviceRepository(),
  );

  sl.registerLazySingleton<UnreadNotificationCountCubit>(
    () => UnreadNotificationCountCubit(
      repository: sl<NotificationRepository>(),
    ),
  );

  sl.registerLazySingleton<UserDeviceCubit>(
    () => UserDeviceCubit(
      repository: sl<UserDeviceRepository>(),
    ),
  );

  sl.registerFactory<NotificationsBloc>(
    () => NotificationsBloc(
      repository: sl<NotificationRepository>(),
      getUserId: () => sl<AuthBloc>().state.user?.id ?? '',
      unreadCountCubit: sl<UnreadNotificationCountCubit>(),
    ),
  );

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
