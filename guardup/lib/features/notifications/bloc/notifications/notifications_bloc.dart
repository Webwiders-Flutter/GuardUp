// ignore_for_file: prefer_initializing_formals

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/constants/app_constants.dart';
import '/core/state/api_state.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '../../data/enums/notification_type.enum.dart';
import '../../data/models/notification.model.dart';
import '../../data/models/notification_filters.model.dart';
import '../../data/repositories/notification_repository.dart';
import '../unread_count/unread_notification_count_cubit.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

/// Bloc managing scoped user notifications, category filtering,
/// infinite pagination, markAsRead, and deletion.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationRepository _repository;
  final UnreadNotificationCountCubit? _unreadCountCubit;
  final String Function() _getUserId;

  NotificationsBloc({
    required NotificationRepository repository,
    required String Function() getUserId,
    UnreadNotificationCountCubit? unreadCountCubit,
  }) : _repository = repository,
       _getUserId = getUserId,
       _unreadCountCubit = unreadCountCubit,
       super(const NotificationsState()) {
    on<NotificationsFetchRequested>(_onFetchRequested);
    on<NotificationsLoadMoreRequested>(_onLoadMoreRequested);
    on<NotificationsCategoryChanged>(_onCategoryChanged);
    on<NotificationMarkAsReadRequested>(_onMarkAsReadRequested);
    on<NotificationsMarkAllAsReadRequested>(_onMarkAllAsReadRequested);
    on<NotificationDeleteRequested>(_onDeleteRequested);
    on<NotificationsDeleteManyRequested>(_onDeleteManyRequested);
  }

  Future<void> _onFetchRequested(
    NotificationsFetchRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final category = event.category ?? state.activeCategory;
    final userId = _getUserId();

    // In dev / test when user session is not in Supabase, filter fakeData so tabs work
    if (userId.isEmpty) {
      final fakeItems = NotificationModel.fakeData.where((n) {
        if (category == NotificationCategory.all) return true;
        return n.type.category == category;
      }).toList();

      emit(
        state.copyWith(
          activeCategory: category,
          paginationState: PaginationState<NotificationModel>(
            items: fakeItems,
            total: fakeItems.length,
            page: 1,
            pageSize: AppConstants.paginationLimit,
            status: const ApiState.success(null),
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        activeCategory: category,
        paginationState: const PaginationState<NotificationModel>(
          status: ApiState.loading(),
        ),
      ),
    );

    try {
      final result = await _repository.getPaginated(
        page: 1,
        pageSize: AppConstants.paginationLimit,
        filters: NotificationFilters(userId: userId, category: category),
      );

      emit(
        state.copyWith(
          paginationState: PaginationState<NotificationModel>(
            items: result.data,
            total: result.total,
            page: 1,
            pageSize: AppConstants.paginationLimit,
            status: const ApiState.success(null),
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          paginationState: PaginationState<NotificationModel>(
            status: ApiState.failure(e.toString()),
          ),
        ),
      );
    }
  }

  Future<void> _onLoadMoreRequested(
    NotificationsLoadMoreRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = state.paginationState;
    if (current.isLoadingMore || current.isLastPage) return;

    final userId = _getUserId();
    if (userId.isEmpty) return;

    final nextPage = current.page + 1;
    emit(
      state.copyWith(
        paginationState: current.copyWith(
          loadMoreStatus: const ApiState.loading(),
        ),
      ),
    );

    try {
      final result = await _repository.getPaginated(
        page: nextPage,
        pageSize: current.pageSize,
        filters: NotificationFilters(
          userId: userId,
          category: state.activeCategory,
        ),
      );

      final updatedItems = [...current.items, ...result.data];
      emit(
        state.copyWith(
          paginationState: current.copyWith(
            items: updatedItems,
            total: result.total,
            page: nextPage,
            loadMoreStatus: const ApiState.success(null),
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          paginationState: current.copyWith(
            loadMoreStatus: ApiState.failure(e.toString()),
          ),
        ),
      );
    }
  }

  void _onCategoryChanged(
    NotificationsCategoryChanged event,
    Emitter<NotificationsState> emit,
  ) {
    if (event.category == state.activeCategory &&
        state.paginationState.items.isNotEmpty) {
      return;
    }

    emit(
      state.copyWith(
        activeCategory: event.category,
        paginationState: const PaginationState<NotificationModel>(
          status: ApiState.loading(),
        ),
      ),
    );

    add(NotificationsFetchRequested(refresh: true, category: event.category));
  }

  Future<void> _onMarkAsReadRequested(
    NotificationMarkAsReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final target = state.paginationState.items.firstWhereOrNull(
      (item) => item.id == event.notificationId,
    );
    if (target == null || target.isRead) return;

    final previousItems = state.paginationState.items;
    final nowIso = DateTime.now().toIso8601String();
    final updatedItems = previousItems.map((item) {
      if (item.id == event.notificationId) {
        return item.copyWith(isRead: true, readAt: nowIso);
      }
      return item;
    }).toList();

    emit(
      state.copyWith(
        paginationState: state.paginationState.copyWith(items: updatedItems),
      ),
    );
    _unreadCountCubit?.decrement();

    try {
      await _repository.markAsRead(notificationId: event.notificationId);
    } catch (e) {
      emit(
        state.copyWith(
          paginationState: state.paginationState.copyWith(items: previousItems),
        ),
      );
      _unreadCountCubit?.increment();
    }
  }

  Future<void> _onMarkAllAsReadRequested(
    NotificationsMarkAllAsReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final userId = _getUserId();
    if (userId.isEmpty) return;

    final previousItems = state.paginationState.items;
    final nowIso = DateTime.now().toIso8601String();
    final updatedItems = previousItems
        .map((item) => item.copyWith(isRead: true, readAt: nowIso))
        .toList();

    emit(
      state.copyWith(
        paginationState: state.paginationState.copyWith(items: updatedItems),
      ),
    );
    _unreadCountCubit?.clearAll();

    try {
      await _repository.markAllAsRead(userId);
    } catch (e) {
      emit(
        state.copyWith(
          paginationState: state.paginationState.copyWith(items: previousItems),
          actionError: 'Failed to mark all as read',
        ),
      );
      _unreadCountCubit?.refreshCount(userId);
    }
  }

  Future<void> _onDeleteRequested(
    NotificationDeleteRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final previousItems = state.paginationState.items;
    final target = previousItems.firstWhereOrNull(
      (item) => item.id == event.notificationId,
    );
    if (target == null) return;

    final updatedItems = previousItems
        .where((item) => item.id != event.notificationId)
        .toList();
    final newTotal = max(0, state.paginationState.total - 1);

    emit(
      state.copyWith(
        paginationState: state.paginationState.copyWith(
          items: updatedItems,
          total: newTotal,
        ),
      ),
    );

    if (!target.isRead) {
      _unreadCountCubit?.decrement();
    }

    try {
      await _repository.delete(event.notificationId);
    } catch (e) {
      emit(
        state.copyWith(
          paginationState: state.paginationState.copyWith(
            items: previousItems,
            total: state.paginationState.total,
          ),
          actionError: 'Failed to delete notification',
        ),
      );
      if (!target.isRead) {
        _unreadCountCubit?.increment();
      }
    }
  }

  Future<void> _onDeleteManyRequested(
    NotificationsDeleteManyRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (event.notificationIds.isEmpty) return;

    final targetIds = event.notificationIds.toSet();
    final previousItems = state.paginationState.items;

    // Track unread count among deleted items to decrement cubit accurately
    final unreadDeletedCount = previousItems
        .where((item) => targetIds.contains(item.id) && !item.isRead)
        .length;

    final updatedItems = previousItems
        .where((item) => !targetIds.contains(item.id))
        .toList();
    final newTotal = max(0, state.paginationState.total - targetIds.length);

    // 1. Optimistic UI update
    emit(
      state.copyWith(
        paginationState: state.paginationState.copyWith(
          items: updatedItems,
          total: newTotal,
        ),
      ),
    );

    if (unreadDeletedCount > 0) {
      for (var i = 0; i < unreadDeletedCount; i++) {
        _unreadCountCubit?.decrement();
      }
    }

    // 2. Persist to Supabase
    try {
      await _repository.deleteMany(event.notificationIds);
    } catch (e) {
      emit(
        state.copyWith(
          paginationState: state.paginationState.copyWith(
            items: previousItems,
            total: state.paginationState.total,
          ),
          actionError: 'Failed to delete notifications',
        ),
      );
      if (unreadDeletedCount > 0) {
        for (var i = 0; i < unreadDeletedCount; i++) {
          _unreadCountCubit?.increment();
        }
      }
    }
  }
}
