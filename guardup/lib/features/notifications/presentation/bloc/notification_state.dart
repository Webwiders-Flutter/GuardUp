import 'package:equatable/equatable.dart';
import 'package:guardup/features/notifications/data/models/notification_model.dart';

enum NotificationStatus { initial, loading, success, failure }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<NotificationModel> notifications;
  final String errorMessage;
  final bool hasReachedMax;
  final int unreadCount;
  final int page;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.errorMessage = '',
    this.hasReachedMax = false,
    this.unreadCount = 0,
    this.page = 0,
  });

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationModel>? notifications,
    String? errorMessage,
    bool? hasReachedMax,
    int? unreadCount,
    int? page,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage ?? this.errorMessage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      unreadCount: unreadCount ?? this.unreadCount,
      page: page ?? this.page,
    );
  }

  @override
  List<Object> get props => [
    status,
    notifications,
    errorMessage,
    hasReachedMax,
    unreadCount,
    page,
  ];
}
