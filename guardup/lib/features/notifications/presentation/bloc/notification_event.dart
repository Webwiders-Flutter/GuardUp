import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object> get props => [];
}

class FetchNotificationsEvent extends NotificationEvent {
  final bool isRefresh;
  const FetchNotificationsEvent({this.isRefresh = false});

  @override
  List<Object> get props => [isRefresh];
}

class MarkNotificationAsReadEvent extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsReadEvent({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}

class DeleteNotificationEvent extends NotificationEvent {
  final String notificationId;

  const DeleteNotificationEvent({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}

class ClearAllNotificationsEvent extends NotificationEvent {}
