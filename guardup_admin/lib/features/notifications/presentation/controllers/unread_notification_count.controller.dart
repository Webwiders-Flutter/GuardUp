import 'dart:async';
import 'dart:math';

import 'package:guardup_admin/features/auth/di/auth.providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/logger/app_logger.dart';
import '/core/services/notification/push_notification_service.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '../../data/repositories/notification.repository.dart';
import '../../di/notification.providers.dart';

/// Controller managing the unread notification count badge in real-time.
/// Initially retrieves unread count from Supabase and increments whenever
/// a new push notification arrives.
class UnreadNotificationCountController extends AsyncNotifier<int> {
  NotificationRepository get _repository =>
      ref.read(notificationRepositoryProvider);

  StreamSubscription? _pushSubscription;

  @override
  FutureOr<int> build() async {
    ref.onDispose(() {
      _pushSubscription?.cancel();
    });

    final userId = ref.watch(authRepositoryProvider).currentUserId;
    if (userId == null || userId.isEmpty) {
      return 0;
    }

    // Increment count whenever a new notification arrives in the foreground
    _pushSubscription?.cancel();
    _pushSubscription = PushNotificationService.onForegroundMessage.listen((
      message,
    ) {
      AppLogger.d(
        'New push notification received in foreground. Incrementing unread count.',
        tag: 'UnreadNotificationCountController',
      );
      increment();
    });

    return asyncHandler(() async {
      final initialCount = await _repository.getUnreadCount(userId);
      return initialCount;
    });
  }

  /// Increments the unread count by 1 (e.g. upon incoming push notification).
  void increment({int? increaseBy}) {
    final current = state.value ?? 0;
    state = AsyncData(current + (increaseBy ?? 1));
  }

  /// Decrements the unread count by 1 (e.g. when an unread notification is clicked/read).
  void decrement({int? decreaseBy}) {
    final current = state.value ?? 0;
    state = AsyncData(max(0, current - (decreaseBy ?? 1)));
  }

  /// Clears the unread count to 0 (e.g. when user marks all as read).
  void clearAll() {
    state = const AsyncData(0);
  }

  /// Re-syncs the exact unread count from Supabase.
  Future<void> refreshCount() async {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null || userId.isEmpty) {
      state = const AsyncData(0);
      return;
    }

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        return await _repository.getUnreadCount(userId);
      }),
    );

    if (result.hasValue) {
      state = result;
    }
  }
}
