import 'package:equatable/equatable.dart';

import '/core/state/api_state.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '../../data/enums/notification_type.enum.dart';
import '../../data/models/notification.model.dart';

/// State representation for notifications list, active filter, and status.
class NotificationsState extends Equatable {
  final PaginationState<NotificationModel> paginationState;
  final NotificationCategory activeCategory;
  final ApiState<void> actionStatus;

  const NotificationsState({
    this.paginationState = const PaginationState<NotificationModel>(),
    this.activeCategory = NotificationCategory.all,
    this.actionStatus = const ApiState.initial(),
  });

  NotificationsState copyWith({
    PaginationState<NotificationModel>? paginationState,
    NotificationCategory? activeCategory,
    ApiState<void>? actionStatus,
  }) {
    return NotificationsState(
      paginationState: paginationState ?? this.paginationState,
      activeCategory: activeCategory ?? this.activeCategory,
      actionStatus: actionStatus ?? this.actionStatus,
    );
  }

  @override
  List<Object?> get props => [
    paginationState,
    activeCategory,
    actionStatus,
  ];
}
