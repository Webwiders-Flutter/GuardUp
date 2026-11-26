import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/features/auth/data/repositories/auth_repository.dart';
import '../bloc/notifications/notifications_bloc.dart';
import '../bloc/unread_count/unread_notification_count_cubit.dart';
import '../bloc/user_device/user_device_cubit.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/user_device_repository.dart';

void registerNotificationsDependencies(GetIt sl) {
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<UserDeviceRepository>(
    () => UserDeviceRepository(sl<SupabaseClient>()),
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
      getUserId: () => sl<AuthRepository>().currentUserId ?? '',
      unreadCountCubit: sl<UnreadNotificationCountCubit>(),
    ),
  );
}
