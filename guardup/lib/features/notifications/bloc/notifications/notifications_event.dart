import 'package:equatable/equatable.dart';

import '../../data/enums/notification_type.enum.dart';

/// Events for [NotificationsBloc].
abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch initial notifications (or refresh current list).
class NotificationsFetchRequested extends NotificationsEvent {
  final bool refresh;
  final NotificationCategory? category;

  const NotificationsFetchRequested({this.refresh = false, this.category});

  @override
  List<Object?> get props => [refresh, category];
}

/// Load next page of notifications.
class NotificationsLoadMoreRequested extends NotificationsEvent {
  const NotificationsLoadMoreRequested();
}

/// Filter notifications by selected category tab.
class NotificationsCategoryChanged extends NotificationsEvent {
  final NotificationCategory category;

  const NotificationsCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

/// Irreversibly marks a single notification as read.
class NotificationMarkAsReadRequested extends NotificationsEvent {
  final String notificationId;

  const NotificationMarkAsReadRequested(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Marks all unread notifications for the user as read.
class NotificationsMarkAllAsReadRequested extends NotificationsEvent {
  const NotificationsMarkAllAsReadRequested();
}

/// Deletes a notification by id.
class NotificationDeleteRequested extends NotificationsEvent {
  final String notificationId;

  const NotificationDeleteRequested(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Bulk deletes multiple notifications by their IDs.
class NotificationsDeleteManyRequested extends NotificationsEvent {
  final List<String> notificationIds;

  const NotificationsDeleteManyRequested(this.notificationIds);

  @override
  List<Object?> get props => [notificationIds];
}
