import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/constants/api/json_keys.dart';
import '/core/constants/app_constants.dart';
import '/core/extensions/list.extension.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '/core/utils/helpers/pagination.helper.dart';
import '/shared/states/pagination.state.dart';
import '../../data/models/membership_plan.model.dart';
import '../../data/repositories/membership_plan.repository.dart';
import '../../di/membership_plan.providers.dart';

class MembershipPlanController
    extends AsyncNotifier<PaginationState<MembershipPlan>> {
  MembershipPlanRepository get _repository =>
      ref.read(membershipPlanRepositoryProvider);

  MembershipPlanFilters _filters = const MembershipPlanFilters();
  MembershipPlanFilters get filters => _filters;

  String? _currentSearch;
  String? get currentSearch => _currentSearch;

  @override
  FutureOr<PaginationState<MembershipPlan>> build() async {
    return asyncHandler(() async {
      final items = await _repository.getPaginated(
        page: 1,
        pageSize: AppConstants.paginationLimit,
        isActive: _filters.isActive,
        search: _currentSearch,
      );
      return PaginationState<MembershipPlan>(
        items: items.data,
        page: 1,
        pageSize: AppConstants.paginationLimit,
        total: items.total,
      );
    });
  }

  Future<void> getPaginatedRecords({
    bool forceRefresh = false,
    MembershipPlanFilters? filters,
    String? search,
    int page = 1,
    int pageSize = AppConstants.paginationLimit,
  }) async {
    if (filters != null) {
      _filters = filters;
    }
    if (search != null) {
      _currentSearch = search;
    }

    final current = state.value;

    // If data is already available for the requested page, skip the API call.
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
          isActive: _filters.isActive,
          search: _currentSearch,
        );

        final previousItems = (page > 1 && current != null)
            ? current.items
            : <MembershipPlan>[];

        return PaginationState<MembershipPlan>(
          items: [...previousItems, ...items.data],
          page: page,
          pageSize: pageSize,
          total: items.total,
        );
      }),
    );

    if (result.hasError && current != null) {
      state = AsyncData(current.copyWith(hasError: true));
    } else {
      state = result;
    }
  }

  /// Creates a plan and places it first: one [AppConstants.sortOrderGap]
  /// before the current first plan (may be 0 or negative).
  Future<void> createRecord(MembershipPlanRequest data) async {
    final current = state.value;
    state = const AsyncLoading();

    final payload = data.toJson();
    payload[JsonKeys.displayOrder] =
        (current?.items.firstOrNull?.displayOrder ?? 0) -
        AppConstants.sortOrderGap;

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final created = await _repository.addOrUpdate(payload);
        final updatedItems = [created, ...?current?.items];

        return (current ?? const PaginationState<MembershipPlan>()).copyWith(
          items: updatedItems,
          total: (current?.total ?? 0) + 1,
        );
      }),
    );

    state = result;
  }

  /// Updates a plan from a [MembershipPlanRequest] or a partial JSON map.
  ///
  /// With [loading] `false` the list is updated optimistically elsewhere and
  /// only errors are surfaced.
  Future<void> updateRecord(
    Object data,
    String id, {
    bool loading = true,
  }) async {
    final current = state.value;
    if (loading) {
      state = const AsyncLoading();
    }

    final Map<String, dynamic> payload = data is MembershipPlanRequest
        ? data.toJson()
        : Map<String, dynamic>.from(data as Map<String, dynamic>);

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final updated = await _repository.addOrUpdate(payload, id: id);
        final updatedItems =
            (current?.items ?? [])
                .map((item) => item.id == id ? updated : item)
                .toList()
              ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        return (current ?? const PaginationState<MembershipPlan>()).copyWith(
          items: updatedItems,
        );
      }),
    );

    if (loading || result.hasError) {
      state = result;
    }
  }

  Future<void> reorderRecords(String id, int oldIndex, int newIndex) async {
    final currentState = state.value;
    if (currentState == null) return;

    final result = currentState.items.reorderWithSortOrder(
      oldIndex: oldIndex,
      newIndex: newIndex,
      getSortOrder: (item) => item.displayOrder,
      copyWithSortOrder: (item, newSortOrder) =>
          item.copyWith(displayOrder: newSortOrder),
      sortOrderGap: AppConstants.sortOrderGap,
    );

    if (result == null) return;

    state = AsyncData(currentState.copyWith(items: result.items));

    await updateRecord(
      {JsonKeys.displayOrder: result.reorderedItem.displayOrder},
      id,
      loading: false,
    );
  }

  Future<void> toggleActiveStatus(String id, bool isActive) async {
    _updateLocalRecords([id], (item) => item.copyWith(isActive: isActive));
    return updateRecord({JsonKeys.isActive: isActive}, id, loading: false);
  }

  Future<void> deleteRecord(String id) => deleteRecords([id]);

  Future<void> deleteRecords(List<String> ids) async {
    if (ids.isEmpty) return;
    final current = state.value;
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        await _repository.deleteMany(ids);

        final idSet = ids.toSet();
        final updatedItems = (current?.items ?? [])
            .where((item) => !idSet.contains(item.id))
            .toList();
        final removed = (current?.items.length ?? 0) - updatedItems.length;

        return (current ?? const PaginationState<MembershipPlan>()).copyWith(
          items: updatedItems,
          total: current != null && current.total >= removed
              ? current.total - removed
              : 0,
        );
      }),
    );

    state = result;
  }

  void _updateLocalRecords(
    List<String> ids,
    MembershipPlan Function(MembershipPlan item) update,
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
