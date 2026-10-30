import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardup/core/utils/app_logs.dart';
import 'package:guardup/features/notifications/data/models/notification_model.dart';
import 'package:guardup/features/notifications/data/repositories/notification_repository.dart';
import 'package:guardup/features/notifications/presentation/bloc/notification_event.dart';
import 'package:guardup/features/notifications/presentation/bloc/notification_state.dart';
import 'package:guardup/core/services/push_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;
  final PushNotificationService? pushNotificationService;
  static const int _limit = 15;

  NotificationBloc({required this.repository, this.pushNotificationService})
    : super(const NotificationState()) {
    on<FetchNotificationsEvent>(_onFetchNotifications);
    on<MarkNotificationAsReadEvent>(_onMarkNotificationAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<ClearAllNotificationsEvent>(_onClearAllNotifications);
  }

  int _calculateUnreadCount(List<NotificationModel> notifications) {
    return notifications.where((n) => !n.isRead).length;
  }

  Future<void> _onFetchNotifications(
    FetchNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    // Prevent duplicate fetches if already loading, unless it's a refresh
    if (state.status == NotificationStatus.loading && !event.isRefresh) {
      return;
    }

    if (event.isRefresh) {
      emit(
        state.copyWith(
          status: NotificationStatus.loading,
          hasReachedMax: false,
          page: 0,
          // Optional: clear notifications on refresh if you want to avoid stale data issues
          // notifications: [],
        ),
      );
    } else if (state.hasReachedMax) {
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        emit(
          state.copyWith(
            status: NotificationStatus.failure,
            errorMessage: 'User not logged in',
          ),
        );
        return;
      }

      final page = state.page;
      final newNotifications = await repository.fetchNotifications(
        user.id,
        page: page,
        limit: _limit,
      );

      final hasReachedMax = newNotifications.length < _limit;
      final List<NotificationModel> mergedNotifications = event.isRefresh
          ? newNotifications
          : [...state.notifications, ...newNotifications];

      // Use a Set to ensure IDs are unique
      final seenIds = <String>{};
      final uniqueNotifications = mergedNotifications
          .where((n) => seenIds.add(n.id))
          .toList();

      final unread = _calculateUnreadCount(uniqueNotifications);
      if (unread == 0) {
        pushNotificationService?.clearBadgeAndNotifications();
      }

      emit(
        state.copyWith(
          status: NotificationStatus.success,
          notifications: uniqueNotifications,
          hasReachedMax: hasReachedMax,
          page: page + 1,
          unreadCount: unread,
        ),
      );
    } catch (e, s) {
      AppLogs.error('Error fetching notifications', error: e, stackTrace: s);
      emit(
        state.copyWith(
          status: NotificationStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // Optimistic update locally
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == event.notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      final unread = _calculateUnreadCount(updatedNotifications);
      if (unread == 0) {
        pushNotificationService?.clearBadgeAndNotifications();
      }

      emit(
        state.copyWith(
          notifications: updatedNotifications,
          unreadCount: unread,
        ),
      );

      // Network call
      await repository.markAsRead(event.notificationId);
    } catch (e, s) {
      AppLogs.error(
        'Error marking notification as read',
        error: e,
        stackTrace: s,
      );
      // Revert in case of failure? Skipping for brevity, just emit error state
      emit(
        state.copyWith(
          status: NotificationStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final updatedNotifications = state.notifications
          .where((n) => n.id != event.notificationId)
          .toList();

      emit(
        state.copyWith(
          notifications: updatedNotifications,
          unreadCount: _calculateUnreadCount(updatedNotifications),
        ),
      );

      await repository.deleteNotification(event.notificationId);
    } catch (e, s) {
      AppLogs.error('Error deleting notification', error: e, stackTrace: s);
      emit(
        state.copyWith(
          status: NotificationStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onClearAllNotifications(
    ClearAllNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(state.copyWith(notifications: [], unreadCount: 0));
      pushNotificationService?.clearBadgeAndNotifications();

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await repository.clearAll(user.id);
      }
    } catch (e, s) {
      AppLogs.error('Error clearing notifications', error: e, stackTrace: s);
      emit(
        state.copyWith(
          status: NotificationStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
