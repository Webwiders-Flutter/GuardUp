import 'dart:async';

import 'package:guardup_admin/core/constants/api/json_keys.dart';

import '/core/constants/app_constants.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '/core/utils/helpers/pagination.helper.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/data/models/user_model.dart';
import '/features/users/data/repositories/users.repository.dart';
import '/features/users/di/users.providers.dart';
import '/shared/states/pagination.state.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsersController extends AsyncNotifier<PaginationState<UserModel>> {
  UsersController(this.params);

  final ({UserRoleType role, UserStatus status}) params;

  UsersRepository get _repository => ref.read(usersRepositoryProvider);

  String? _currentSearch;
  String? get currentSearch => _currentSearch;

  @override
  FutureOr<PaginationState<UserModel>> build() async {
    return asyncHandler(() async {
      final items = await _repository.getPaginated(
        page: 1,
        status: params.status,
        pageSize: AppConstants.paginationLimit,
        role: params.role,
        search: _currentSearch,
      );
      return PaginationState<UserModel>(
        items: items.data,
        page: 1,
        pageSize: AppConstants.paginationLimit,
        total: items.total,
      );
    });
  }

  Future<void> getPaginatedRecords({
    bool forceRefresh = false,
    String? search,
    int page = 1,
    int pageSize = AppConstants.paginationLimit,
  }) async {
    if (search != null) {
      _currentSearch = search;
    }

    final current = state.value;

    // If Data is already available for the requested page, skip the API call.
    if (!forceRefresh && current != null) {
      final hasDataForPage = PaginationHelper.hasCachedPage(
        page: page,
        pageSize: pageSize,
        totalCount: current.total,
        totalItems: current.items.length,
      );

      if (hasDataForPage) {
        state = AsyncData(current.copyWith(page: page, pageSize: pageSize));
        return;
      }
    }

    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final items = await _repository.getPaginated(
          page: page,
          pageSize: pageSize,
          role: params.role,
          status: params.status,
          search: _currentSearch,
        );

        final previousItems = (page > 1 && current != null)
            ? current.items
            : <UserModel>[];
        final updatedItems = [...previousItems, ...items.data];

        return PaginationState<UserModel>(
          items: updatedItems,
          page: page,
          pageSize: pageSize,
          total: items.total,
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

  Future<void> updateRecord(
    Map<String, dynamic> data,
    String id, {
    bool loading = true,
  }) async {
    final current = state.value;
    if (loading) {
      state = const AsyncLoading();
    }

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final payload = Map<String, dynamic>.from(data);
        final updated = await _repository.addOrUpdate(payload, id: id);
        final currentItems = current?.items ?? [];
        final updatedItems = currentItems.map((item) {
          return item.id == id ? updated : item;
        }).toList();

        return (current ?? const PaginationState<UserModel>()).copyWith(
          items: updatedItems,
        );
      }),
    );
    if (loading || result.hasError) {
      state = result;
    }
  }

  Future<void> markVerified(String id) async {
    final current = state.value;

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final updated = await _repository.markVerified(id);
        final currentItems = current?.items ?? [];
        final updatedItems = currentItems.map((item) {
          return item.id == id ? updated : item;
        }).toList();

        return (current ?? const PaginationState<UserModel>()).copyWith(
          items: updatedItems,
        );
      }),
    );

    if (result.hasError) {
      state = result;
    } else if (result.hasValue) {
      state = result;
    }
  }

  /// Rejecting removes the applicant completely, so the row leaves the list.
  Future<void> rejectUser(String id) async {
    final current = state.value;

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        await _repository.rejectUser(id);
        return _withoutRecord(current, id);
      }),
    );

    state = result;
  }

  Future<void> toggleBlock(String id, bool block) async {
    final targetStatus = block ? UserStatus.blocked : UserStatus.active;
    _updateLocalRecords([
      id,
    ], (item) => item.copyWith(status: targetStatus));
    return updateRecord(
      {JsonKeys.registrationStatus: targetStatus.apiValue},
      id,
      loading: false,
    );
  }

  Future<void> deleteRecord(String id) async {
    final current = state.value;
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        await _repository.delete(id);
        return _withoutRecord(current, id);
      }),
    );

    state = result;
  }

  PaginationState<UserModel> _withoutRecord(
    PaginationState<UserModel>? current,
    String id,
  ) {
    final currentItems = current?.items ?? [];
    return (current ?? const PaginationState<UserModel>()).copyWith(
      items: currentItems.where((item) => item.id != id).toList(),
      total: current != null && current.total > 0 ? current.total - 1 : 0,
    );
  }

  /// Returns loaded records matching the provided [ids] and optional [condition].
  // ignore: unused_element
  List<UserModel> _getLocalRecords(
    List<String> ids, {
    bool Function(UserModel item)? condition,
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
    UserModel Function(UserModel item) update,
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
