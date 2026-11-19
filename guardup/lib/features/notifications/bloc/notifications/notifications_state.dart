import 'package:equatable/equatable.dart';

import '/shared/widgets/pagination/pagination.state.dart';
import '../../data/enums/notification_type.enum.dart';
import '../../data/models/notification.model.dart';

/// State representation for notifications list, active filter, and status.
class NotificationsState extends Equatable {
  final PaginationState<NotificationModel> paginationState;
  final NotificationCategory activeCategory;
  final String? actionError;
  final String? actionSuccess;

  const NotificationsState({
    this.paginationState = const PaginationState<NotificationModel>(),
    this.activeCategory = NotificationCategory.all,
    this.actionError,
    this.actionSuccess,
  });

  NotificationsState copyWith({
    PaginationState<NotificationModel>? paginationState,
    NotificationCategory? activeCategory,
    String? actionError,
    String? actionSuccess,
  }) {
    return NotificationsState(
      paginationState: paginationState ?? this.paginationState,
      activeCategory: activeCategory ?? this.activeCategory,
      actionError: actionError,
      actionSuccess: actionSuccess,
    );
  }

  @override
  List<Object?> get props => [
    paginationState,
    activeCategory,
    actionError,
    actionSuccess,
  ];
}
