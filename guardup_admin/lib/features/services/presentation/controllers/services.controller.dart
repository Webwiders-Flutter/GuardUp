import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/constants/api/json_keys.dart';
import '/core/constants/app_constants.dart';
import '/core/extensions/list.extension.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '/core/utils/helpers/pagination.helper.dart';
import '/features/services/data/models/service.model.dart';
import '/features/services/data/repositories/services.repository.dart';
import '/features/services/di/services.providers.dart';
import '/shared/states/pagination.state.dart';

class ServicesController extends AsyncNotifier<PaginationState<ServiceModel>> {
  ServicesRepository get _repository => ref.read(servicesRepositoryProvider);

  ServiceFilters _filters = const ServiceFilters();
  ServiceFilters get filters => _filters;

  String? _currentSearch;
  String? get currentSearch => _currentSearch;

  @override
  FutureOr<PaginationState<ServiceModel>> build() async {
    return asyncHandler(() async {
      final items = await _repository.getPaginated(
        page: 1,
        pageSize: AppConstants.paginationLimit,
        isActive: _filters.isActive,
        search: _currentSearch,
      );
      return PaginationState<ServiceModel>(
        items: items.data,
        page: 1,
        pageSize: AppConstants.paginationLimit,
        total: items.total,
      );
    });
  }

  Future<void> getPaginatedRecords({
    bool forceRefresh = false,
    ServiceFilters? filters,
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
            : <ServiceModel>[];
        final updatedItems = [...previousItems, ...items.data];

        return PaginationState<ServiceModel>(
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

  Future<void> createRecord(ServiceRequest data) async {
    final Map<String, dynamic> payload = data.toJson();
    final current = state.value;
    state = const AsyncLoading();

    final sortOrder =
        (current?.items.firstOrNull?.displayOrder ?? 0) -
        AppConstants.sortOrderGap;
    payload[JsonKeys.displayOrder] = sortOrder;

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final newService = await _repository.addOrUpdate(payload);
        final currentItems = current?.items ?? [];
        final updatedItems = [newService, ...currentItems];

        return (current ?? const PaginationState<ServiceModel>()).copyWith(
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

    final Map<String, dynamic> payload = data is ServiceRequest
        ? data.toJson()
        : Map<String, dynamic>.from(data as Map<String, dynamic>);

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final updated = await _repository.addOrUpdate(payload, id: id);
        final currentItems = current?.items ?? [];
        final updatedItems = currentItems.map((item) {
          return item.id == id ? updated : item;
        }).toList()..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        return (current ?? const PaginationState<ServiceModel>()).copyWith(
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

    final previousItems = currentState.items;
    final result = previousItems.reorderWithSortOrder(
      oldIndex: oldIndex,
      newIndex: newIndex,
      getSortOrder: (item) => item.displayOrder,
      copyWithSortOrder: (item, newSortOrder) =>
          item.copyWith(displayOrder: newSortOrder),
      sortOrderGap: AppConstants.sortOrderGap,
    );

    if (result == null) return;

    state = AsyncData(currentState.copyWith(items: result.items));

    updateRecord(
      {JsonKeys.displayOrder: result.reorderedItem.displayOrder},
      id,
      loading: false,
    );
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

        return (current ?? const PaginationState<ServiceModel>()).copyWith(
          items: updatedItems,
          total: current != null && current.total > 0 ? current.total - 1 : 0,
        );
      }),
    );

    state = result;
  }

  Future<void> deleteRecords(List<ServiceModel> items) async {
    if (items.isEmpty) return;
    final current = state.value;
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final ids = items.map((e) => e.id).toList();
        await _repository.deleteMany(ids);

        final idSet = ids.toSet();
        final currentItems = current?.items ?? [];
        final updatedItems = currentItems
            .where((item) => !idSet.contains(item.id))
            .toList();

        return (current ?? const PaginationState<ServiceModel>()).copyWith(
          items: updatedItems,
          total: current != null && current.total >= items.length
              ? current.total - items.length
              : 0,
        );
      }),
    );

    state = result;
  }

  List<ServiceModel> _getLocalRecords(
    List<String> ids, {
    bool Function(ServiceModel item)? condition,
  }) {
    final current = state.value;
    if (current == null || ids.isEmpty) return [];
    final idSet = ids.toSet();
    return current.items.where((item) {
      if (!idSet.contains(item.id)) return false;
      return condition?.call(item) ?? true;
    }).toList();
  }

  void _updateLocalRecords(
    List<String> ids,
    ServiceModel Function(ServiceModel item) update,
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
