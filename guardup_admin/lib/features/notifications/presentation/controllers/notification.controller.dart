import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/constants/app_constants.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '/core/utils/helpers/pagination.helper.dart';
import '/features/auth/di/auth.providers.dart';
import '/shared/states/pagination.state.dart';
import '../../data/models/notification.model.dart';
import '../../data/models/notification_filters.model.dart';
import '../../data/repositories/notification.repository.dart';
import '../../di/notification.providers.dart';

/// Controller managing notifications for the currently authenticated admin user.
/// Handles scoped pagination (current user only), filtering by notification criteria,
/// irreversible markAsRead, and deletion.
class NotificationController
    extends AsyncNotifier<PaginationState<NotificationModel>> {
  NotificationRepository get _repository =>
      ref.read(notificationRepositoryProvider);

  String? get _currentUserId => ref.read(authRepositoryProvider).currentUserId;

  NotificationFilters _filters = const NotificationFilters();
  NotificationFilters get filters => _filters;

  String? _currentSearch;
  String? get currentSearch => _currentSearch;

  @override
  FutureOr<PaginationState<NotificationModel>> build() async {
    final userId = ref.watch(authRepositoryProvider).currentUserId;
    if (userId == null || userId.isEmpty) {
      return const PaginationState<NotificationModel>();
    }

    _filters = NotificationFilters(userId: userId);

    return asyncHandler(() async {
      final items = await _repository.getPaginated(
        page: 1,
        pageSize: AppConstants.paginationLimit,
        filters: _filters,
      );

      return PaginationState<NotificationModel>(
        items: items.data,
        page: 1,
        pageSize: AppConstants.paginationLimit,
        total: items.total,
      );
    });
  }

  /// Fetches paginated notifications scoped to the current user with optional filters.
  Future<void> getPaginatedRecords({
    bool forceRefresh = false,
    NotificationFilters? filters,
    String? search,
    int page = 1,
    int pageSize = AppConstants.paginationLimit,
  }) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      state = const AsyncData(PaginationState<NotificationModel>());
      return;
    }

    if (filters != null) {
      _filters = filters.copyWith(userId: userId);
    } else if (_filters.userId != userId) {
      _filters = _filters.copyWith(userId: userId);
    }
    if (search != null) {
      _currentSearch = search;
    }

    final current = state.value;

    // Check pagination cache if not forcing refresh
    if (!forceRefresh && current != null) {
      final hasDataForPage = PaginationHelper.hasCachedPage(
        page: page,
        pageSize: pageSize,
        totalCount: current.total,
        totalItems: current.items.length,
      );

      if (hasDataForPage) {
        state = AsyncData(
          current.copyWith(page: page, pageSize: pageSize, isLoading: false),
        );
        return;
      }
    }

    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final items = await _repository.getPaginated(
          page: page,
          pageSize: pageSize,
          filters: _filters,
          search: _currentSearch,
        );

        final previousItems = (page > 1 && current != null)
            ? current.items
            : <NotificationModel>[];
        final updatedItems = [...previousItems, ...items.data];

        return PaginationState<NotificationModel>(
          items: updatedItems,
          page: page,
          pageSize: pageSize,
          total: items.total,
          isLoading: false,
        );
      }),
    );

    if (result.hasError) {
      if (current != null) {
        state = AsyncData(current.copyWith(hasError: true));
      } else {
        state = result;
      }
    } else {
      state = result;
    }
  }

  /// Irreversibly marks a notification as read. Once read, cannot be reverted.
  Future<void> markAsRead(String id) async {
    final target = _getLocalRecords([id]).firstOrNull;
    if (target != null && target.isRead) {
      return;
    }

    final current = state.value;
    final now = DateTime.now().toIso8601String();
    _updateLocalRecords([
      id,
    ], (item) => item.copyWith(isRead: true, readAt: now));

    if (_currentUserId == null || _currentUserId!.isEmpty) return;

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        await _repository.markAsRead(notificationId: id);
      }),
    );

    if (result.hasError && current != null) {
      state = AsyncData(current);
    } else {
      ref.read(unreadNotificationCountControllerProvider.notifier).decrement();
    }
  }

  /// Deletes a single notification record by [id].
  Future<void> deleteRecord(String id) async {
    final current = state.value;
    state = const AsyncLoading();

    final unreadCount = _getLocalRecords([
      id,
    ], condition: (item) => !item.isRead).length;
    if (unreadCount > 0) {
      ref
          .read(unreadNotificationCountControllerProvider.notifier)
          .decrement(decreaseBy: unreadCount);
    }

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        await _repository.delete(id);
        final currentItems = current?.items ?? [];
        final updatedItems = currentItems
            .where((item) => item.id != id)
            .toList();
        final newTotal = (current != null && current.total > 0)
            ? current.total - 1
            : 0;

        return (current ?? const PaginationState<NotificationModel>()).copyWith(
          items: updatedItems,
          total: newTotal,
        );
      }),
    );

    state = result;
  }

  /// Bulk deletes multiple notifications by [ids].
  Future<void> deleteRecords(List<String> ids) async {
    if (ids.isEmpty) return;
    final current = state.value;
    state = const AsyncLoading();

    final unreadCount = _getLocalRecords(
      ids,
      condition: (item) => !item.isRead,
    ).length;
    if (unreadCount > 0) {
      ref
          .read(unreadNotificationCountControllerProvider.notifier)
          .decrement(decreaseBy: unreadCount);
    }

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        await _repository.deleteMany(ids);
        final currentItems = current?.items ?? [];
        final idSet = ids.toSet();
        final updatedItems = currentItems
            .where((item) => !idSet.contains(item.id))
            .toList();
        final deletedCount = currentItems.length - updatedItems.length;
        final newTotal = (current != null && current.total >= deletedCount)
            ? current.total - deletedCount
            : 0;

        return (current ?? const PaginationState<NotificationModel>()).copyWith(
          items: updatedItems,
          total: newTotal,
        );
      }),
    );

    state = result;
  }

  /// Returns loaded records matching the provided [ids] and optional [condition].
  List<NotificationModel> _getLocalRecords(
    List<String> ids, {
    bool Function(NotificationModel item)? condition,
  }) {
    final current = state.value;
    if (current == null || ids.isEmpty) return [];
    final idSet = ids.toSet();
    return current.items.where((item) {
      if (!idSet.contains(item.id)) return false;
      return condition?.call(item) ?? true;
    }).toList();
  }

  /// Updates local state for matching [ids] using the given [update] transformation.
  void _updateLocalRecords(
    List<String> ids,
    NotificationModel Function(NotificationModel item) update,
  ) {
    final current = state.value;
    if (current == null || ids.isEmpty) return;
    final idSet = ids.toSet();
    final updatedList = current.items.map((item) {
      return idSet.contains(item.id) ? update(item) : item;
    }).toList();
    state = AsyncData(current.copyWith(items: updatedList));
  }
}
