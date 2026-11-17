import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/providers/supabase/supabase.provider.dart';
import '/shared/states/pagination.state.dart';

import '../data/models/notification.model.dart';
import '../data/repositories/notification.repository.dart';
import '../presentation/controllers/notification.controller.dart';
import '../presentation/controllers/unread_notification_count.controller.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(supabaseClientProvider));
});

final notificationControllerProvider =
    AsyncNotifierProvider<
      NotificationController,
      PaginationState<NotificationModel>
    >(NotificationController.new);

final unreadNotificationCountControllerProvider =
    AsyncNotifierProvider<UnreadNotificationCountController, int>(
      UnreadNotificationCountController.new,
    );
