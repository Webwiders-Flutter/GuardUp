import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:guardup/core/common/report/data/report_repository_impl.dart';
import 'package:guardup/core/common/report/domain/report_repository.dart';
import 'package:guardup/core/common/report/domain/report_usecase.dart';
import 'package:guardup/core/common/report/presentation/bloc/report_bloc.dart';
import 'package:guardup/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:guardup/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:guardup/features/dashboard/presentation/screens/bloc/dashboard_cubit.dart';
import 'package:guardup/features/help_centre/data/repositories/support_repository_impl.dart';
import 'package:guardup/features/help_centre/domain/repositories/support_repository.dart';
import 'package:guardup/features/help_centre/presentation/bloc/support_cubit.dart';
import 'package:guardup/features/locations/data/repositories/location_repository_impl.dart';
import 'package:guardup/features/locations/domain/repositories/location_repository.dart';
import 'package:guardup/features/locations/domain/usecases/get_cities_usecase.dart';
import 'package:guardup/features/locations/domain/usecases/get_location_countries_by_ids_usecase.dart';
import 'package:guardup/features/locations/domain/usecases/get_location_countries_usecase.dart';
import 'package:guardup/features/locations/domain/usecases/get_states_usecase.dart';
import 'package:guardup/features/locations/presentation/bloc/city_bloc/city_bloc.dart'
    as loc;
import 'package:guardup/features/locations/presentation/bloc/country_bloc/country_bloc.dart'
    as loc;
import 'package:guardup/features/locations/presentation/bloc/state_bloc/state_bloc.dart'
    as loc;
import 'package:guardup/features/notifications/data/repositories/notification_repository.dart';
import 'package:guardup/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:guardup/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:guardup/features/profile/domain/repositories/profile_repository.dart';
import 'package:guardup/features/profile/domain/usecases/block_user_usecase.dart';
import 'package:guardup/features/profile/domain/usecases/get_blocked_users_usecase.dart';
import 'package:guardup/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:guardup/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:guardup/features/profile/presentation/bloc/blocked_users/blocked_users_cubit.dart';
import 'package:guardup/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/push_notification_service.dart';
import '../../data/providers/local/storage_service.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/signup_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../localization/data/repositories/localization_repository_impl.dart';
import '../localization/domain/repositories/localization_repository.dart';
import '../localization/locale_bloc.dart';
import '../network/api_client.dart';
import '../network/connectivity_bloc.dart';
import '../theme/theme_bloc.dart';
import 'file_upload_service.dart';
import 'media_picker_service.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // --- Core ---
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => MediaPickerService());
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton(() => FileUploadService(Supabase.instance.client));
  sl.registerLazySingleton(() => PushNotificationService(sl()));

  sl.registerLazySingleton(
    () => StorageService(prefs: sl(), secureStorage: sl()),
  );

  sl.registerLazySingleton(() => ApiClient(dio: sl(), storageService: sl()));

  // --- Features: Auth ---
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), Supabase.instance.client),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));

  // --- Features: Dashboard ---
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(),
  );

  sl.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(Supabase.instance.client),
  );

  // --- Blocs ---
  sl.registerLazySingleton(
    () => ConnectivityBloc()..add(ConnectivityStarted()),
  );
  sl.registerLazySingleton(() => ThemeBloc(storageService: sl()));

  sl.registerLazySingleton<LocalizationRepository>(
    () => LocalizationRepositoryImpl(
      storageService: sl(),
      supabaseClient: Supabase.instance.client,
    ),
  );
  sl.registerLazySingleton(() => LocaleBloc(localizationRepository: sl()));

  sl.registerLazySingleton(
    () =>
        AuthBloc(authRepository: sl(), loginUseCase: sl(), signUpUseCase: sl()),
  );
  sl.registerLazySingleton(() => DashboardCubit());

  // sl.registerFactory(() => ChatBloc(repository: sl()));

  // --- Features: Profile ---
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(Supabase.instance.client, sl()),
  );
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => GetBlockedUsersUseCase(sl()));

  sl.registerFactory(
    () => ProfileBloc(getProfileUseCase: sl(), updateProfileUseCase: sl()),
  );
  sl.registerFactory(
    () => BlockedUsersCubit(
      getBlockedUsersUseCase: sl(),
      unblockUserUseCase: sl(),
    ),
  );

  // --- Features: Locations ---
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(Supabase.instance.client),
  );
  sl.registerLazySingleton(() => GetLocationCountriesUseCase(sl()));
  sl.registerLazySingleton(() => GetLocationCountriesByIdsUseCase(sl()));
  sl.registerLazySingleton(() => GetStatesUseCase(sl()));
  sl.registerLazySingleton(() => GetCitiesUseCase(sl()));

  sl.registerFactory(() => loc.CountryBloc(getCountriesUseCase: sl()));
  sl.registerFactory(() => loc.StateBloc(getStatesUseCase: sl()));
  sl.registerFactory(() => loc.CityBloc(getCitiesUseCase: sl()));

  sl.registerFactory(() => ReportBloc(reportUseCase: sl()));
  // Use cases
  sl.registerLazySingleton(() => ReportUseCase(sl()));
  sl.registerLazySingleton(() => BlockUserUseCase(sl()));
  // --- Features: Notifications ---
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(supabase: Supabase.instance.client),
  );
  sl.registerFactory(
    () => NotificationBloc(repository: sl(), pushNotificationService: sl()),
  );

  // --- Features: Help Centre / Support ---
  sl.registerLazySingleton<SupportRepository>(
    () => SupportRepositoryImpl(Supabase.instance.client, sl()),
  );
  sl.registerFactory(() => SupportCubit(sl()));
}
