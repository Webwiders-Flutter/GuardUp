import 'dart:async';

import 'package:guardup_admin/core/constants/api/json_keys.dart';

import '/core/constants/app_constants.dart';
import '/core/utils/helpers/pagination.helper.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/utils/callback/async_callback.handler.dart';
import '/shared/states/pagination.state.dart';
import '../../data/models/contact_us.model.dart';
import '../../data/models/contact_us_filters.model.dart';
import '../../data/repositories/contact_us.repository.dart';
import '../../di/contact_us.providers.dart';

class ContactUsController extends AsyncNotifier<PaginationState<ContactUs>> {
  ContactUsRepository get _repository => ref.read(contactUsRepositoryProvider);

  ContactUsFilters _filters = const ContactUsFilters();
  ContactUsFilters get filters => _filters;

  dynamic get currentFilter => _filters.isResolved ?? _filters.role;

  String? _currentSearch;
  String? get currentSearch => _currentSearch;

  @override
  FutureOr<PaginationState<ContactUs>> build() async {
    return asyncHandler(() async {
      final items = await _repository.getPaginated(
        page: 1,
        pageSize: AppConstants.paginationLimit,
        isResolved: _filters.isResolved,
        role: _filters.role,
        search: _currentSearch,
      );
      return PaginationState<ContactUs>(
        items: items.data,
        page: 1,
        pageSize: AppConstants.paginationLimit,
        total: items.total,
      );
    });
  }

  Future<void> getPaginatedRecords({
    bool forceRefresh = false,
    ContactUsFilters? filters,
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
          isResolved: _filters.isResolved,
          role: _filters.role,
          search: _currentSearch,
        );

        final previousItems = (page > 1 && current != null)
            ? current.items
            : <ContactUs>[];
        final updatedItems = [...previousItems, ...items.data];

        return PaginationState<ContactUs>(
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

  Future<void> toggleResolvedStatus(String id, bool isResolved) async {
    final target = _getLocalRecords([id]).firstOrNull;
    if (target == null) return;

    final current = state.value;
    _updateLocalRecords([id], (item) => item.copyWith(isResolved: isResolved));

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final updated = await _repository.toggleResolved(id, isResolved);
        _updateLocalRecords([id], (_) => updated);
        return state.value ?? current ?? const PaginationState<ContactUs>();
      }),
    );

    if (result.hasError && current != null) {
      state = AsyncData(current);
    }
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
        return (current ?? const PaginationState<ContactUs>()).copyWith(
          items: updatedItems,
          total: current != null ? current.total - 1 : 0,
        );
      }),
    );

    state = result;
  }

  Future<void> updateResolvedStatusMany(
    List<String> ids,
    bool isResolved,
  ) async {
    if (ids.isEmpty) return;
    final current = state.value;
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final updatedList = await _repository.updateMany({
          JsonKeys.isResolved: isResolved,
        }, ids);
        final currentItems = current?.items ?? [];
        final updatedMap = {for (final item in updatedList) item.id: item};
        final updatedItems = currentItems.map((item) {
          return updatedMap[item.id] ?? item;
        }).toList();

        return (current ?? const PaginationState<ContactUs>()).copyWith(
          items: updatedItems,
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

        return (current ?? const PaginationState<ContactUs>()).copyWith(
          items: updatedItems,
          total: newTotal,
        );
      }),
    );

    state = result;
  }

  /// Returns loaded records matching the provided [ids] and optional [condition].
  List<ContactUs> _getLocalRecords(
    List<String> ids, {
    bool Function(ContactUs item)? condition,
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
    ContactUs Function(ContactUs item) update,
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
