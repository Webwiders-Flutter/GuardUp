import 'dart:async';

import '/core/constants/app_constants.dart';
import '/core/extensions/list.extension.dart';
import '/core/utils/helpers/pagination.helper.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/utils/callback/async_callback.handler.dart';
import '../../data/models/faq.model.dart';
import '../../data/models/faq_filters.model.dart';
import '../../data/repositories/faq.repository.dart';
import '../../di/faq.providers.dart';
import '/core/constants/api/json_keys.dart';
import '/shared/states/pagination.state.dart';

class FaqController extends AsyncNotifier<PaginationState<Faq>> {
  FaqRepository get _repository => ref.read(faqRepositoryProvider);

  FaqFilters _filters = const FaqFilters();
  FaqFilters get filters => _filters;

  String? _currentSearch;
  String? get currentSearch => _currentSearch;

  @override
  FutureOr<PaginationState<Faq>> build() async {
    return asyncHandler(() async {
      final items = await _repository.getPaginated(
        page: 1,
        pageSize: AppConstants.paginationLimit,
        isActive: _filters.isActive,
        role: _filters.role,
        search: _currentSearch,
      );
      return PaginationState<Faq>(
        items: items.data,
        page: 1,
        pageSize: AppConstants.paginationLimit,
        total: items.total,
      );
    });
  }

  Future<void> getPaginatedRecords({
    bool forceRefresh = false,
    FaqFilters? filters,
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
          isActive: _filters.isActive,
          role: _filters.role,
          search: _currentSearch,
        );

        final previousItems = (page > 1 && current != null)
            ? current.items
            : <Faq>[];
        final updatedItems = [...previousItems, ...items.data];

        return PaginationState<Faq>(
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

  Future<void> createRecord(FaqRequest data) async {
    final Map<String, dynamic> payload = data.toJson();
    final current = state.value;
    state = const AsyncLoading();
    final sortOrder =
        (current?.items.firstOrNull?.sortOrder ?? 0) -
        AppConstants.sortOrderGap;
    payload[JsonKeys.sortOrder] = sortOrder;

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final newFaq = await _repository.addOrUpdate(payload);
        final currentItems = current?.items ?? [];
        final updatedItems = [newFaq, ...currentItems];
        return (current ?? const PaginationState<Faq>()).copyWith(
          items: updatedItems,
          total: current != null ? current.total + 1 : 1,
        );
      }),
    );

    state = result;
  }

  Future<void> updateRecord(
    dynamic data,
    String id, {
    bool loading = true,
  }) async {
    final current = state.value;
    if (loading) {
      state = const AsyncLoading();
    }

    final Map<String, dynamic> payload = data is FaqRequest
        ? data.toJson()
        : data as Map<String, dynamic>;

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final updated = await _repository.addOrUpdate(payload, id: id);
        final currentItems = current?.items ?? [];
        final updatedItems = currentItems.map((item) {
          return item.id == id ? updated : item;
        }).toList();

        return (current ?? const PaginationState<Faq>()).copyWith(
          items: updatedItems,
        );
      }),
    );
    if (loading && !result.hasError) {
      state = result;
    }
  }

  Future<void> reorderRecords(String id, int oldIndex, int newIndex) async {
    final currentState = state.value;
    if (currentState == null) return;

    final previousItems = currentState.items;
    final result = previousItems.reorderWithSortOrder(
      oldIndex: oldIndex,
      newIndex: newIndex,
      getSortOrder: (item) => item.sortOrder,
      copyWithSortOrder: (item, newSortOrder) =>
          item.copyWith(sortOrder: newSortOrder),
    );

    if (result == null) return;

    state = AsyncData(currentState.copyWith(items: result.items));

    updateRecord(
      {JsonKeys.sortOrder: result.reorderedItem.sortOrder},
      id,
      loading: false,
    );
    return;
  }

  Future<void> toggleActiveStatus(String id, bool isActive) async {
    final target = _getLocalRecords([id]).firstOrNull;
    if (target == null) return;

    _updateLocalRecords([id], (item) => item.copyWith(isActive: isActive));
    return updateRecord({JsonKeys.isActive: isActive}, id, loading: false);
  }

  Future<void> deleteRecord(String id) async {
    final current = state.value;
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        await _repository.delete(id);
        final currentItems = current?.items ?? [];
        final updatedItems = currentItems
            .where((item) => item.id != id)
            .toList();
        return (current ?? const PaginationState<Faq>()).copyWith(
          items: updatedItems,
          total: current != null ? current.total - 1 : 0,
        );
      }),
    );

    state = result;
  }

  Future<void> deleteRecords(List<String> ids) async {
    if (ids.isEmpty) return;
    final current = state.value;
    state = const AsyncLoading();

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

        return (current ?? const PaginationState<Faq>()).copyWith(
          items: updatedItems,
          total: newTotal,
        );
      }),
    );

    state = result;
  }

  /// Returns loaded records matching the provided [ids] and optional [condition].
  List<Faq> _getLocalRecords(
    List<String> ids, {
    bool Function(Faq item)? condition,
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
  void _updateLocalRecords(List<String> ids, Faq Function(Faq item) update) {
    final current = state.value;
    if (current == null || ids.isEmpty) return;
    final idSet = ids.toSet();
    final updatedList = current.items.map((item) {
      return idSet.contains(item.id) ? update(item) : item;
    }).toList();
    state = AsyncData(current.copyWith(items: updatedList));
  }
}
