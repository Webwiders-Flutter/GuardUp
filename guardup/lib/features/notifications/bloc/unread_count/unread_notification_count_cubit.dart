import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/error/api_exception.dart';
import '/core/logger/app_logger.dart';
import '/core/services/notification/push_notification_service.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '../../data/repositories/notification_repository.dart';

/// Cubit managing the unread notification count badge in real-time.
/// Retrieves unread count from Supabase and increments whenever
/// a new push notification arrives in the foreground.
class UnreadNotificationCountCubit extends Cubit<int> {
  final NotificationRepository _repository;
  StreamSubscription? _pushSubscription;
  String? _currentUserId;

  UnreadNotificationCountCubit({required NotificationRepository repository})
    // ignore: prefer_initializing_formals
    : _repository = repository,
      super(0) {
    _initPushListener();
  }

  void _initPushListener() {
    _pushSubscription = PushNotificationService.onForegroundMessage.listen((
      message,
    ) {
      AppLogger.d(
        'New push notification received in foreground. Incrementing unread count.',
        tag: 'UnreadNotificationCountCubit',
      );
      increment();
    });
  }

  /// Loads the initial unread notification count for [userId].
  Future<void> loadCount(String userId) async {
    if (userId.isEmpty) {
      clearAll();
      return;
    }
    _currentUserId = userId;
    try {
      final count = await asyncHandler(() => _repository.getUnreadCount(userId));
      emit(count);
    } on ApiException catch (e) {
      AppLogger.w(
        'Failed to load unread notification count: ${e.message}',
        tag: 'UnreadNotificationCountCubit',
      );
    }
  }

  /// Increments the unread count by [increaseBy] (e.g. upon incoming push notification).
  void increment({int increaseBy = 1}) {
    emit(state + increaseBy);
  }

  /// Decrements the unread count by [decreaseBy] (clamped at 0).
  void decrement({int decreaseBy = 1}) {
    emit(max(0, state - decreaseBy));
  }

  /// Clears the unread count to 0 (e.g. when user marks all as read or logs out).
  void clearAll() {
    emit(0);
  }

  /// Re-syncs the exact unread count from Supabase.
  Future<void> refreshCount([String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid == null || uid.isEmpty) {
      clearAll();
      return;
    }
    try {
      final count = await asyncHandler(() => _repository.getUnreadCount(uid));
      emit(count);
    } on ApiException catch (e) {
      AppLogger.w(
        'Failed to refresh unread count: ${e.message}',
        tag: 'UnreadNotificationCountCubit',
      );
    }
  }

  @override
  Future<void> close() {
    _pushSubscription?.cancel();
    return super.close();
  }
}
