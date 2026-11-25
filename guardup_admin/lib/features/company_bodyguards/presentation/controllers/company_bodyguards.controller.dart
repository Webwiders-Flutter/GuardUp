import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/constants/app_constants.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '/core/utils/helpers/pagination.helper.dart';
import '/features/company_bodyguards/data/repositories/company_bodyguards.repository.dart';
import '/features/company_bodyguards/di/company_bodyguards.providers.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/data/models/bodyguard.model.dart';
import '/shared/states/pagination.state.dart';

/// Paginated admin listing of company-managed bodyguards with one [status].
///
/// Status changes and deletes go through [CompanyBodyguardReviewController],
/// which refreshes every listing (the bodyguard may move between tabs).
class CompanyBodyguardsController
    extends AsyncNotifier<PaginationState<BodyguardModel>> {
  CompanyBodyguardsController(this.status);

  final UserStatus status;

  CompanyBodyguardsRepository get _repository =>
      ref.read(companyBodyguardsRepositoryProvider);

  String? _currentSearch;

  /// When set, the listing is scoped to this company (`companies.id`).
  String? _companyId;
  String? get companyId => _companyId;

  @override
  FutureOr<PaginationState<BodyguardModel>> build() {
    return asyncHandler(
      () => _load(page: 1, pageSize: AppConstants.paginationLimit),
    );
  }

  Future<void> getPaginatedRecords({
    bool forceRefresh = false,
    String? search,
    String? companyId,
    int page = 1,
    int pageSize = AppConstants.paginationLimit,
  }) async {
    if (search != null) {
      _currentSearch = search;
    }
    if (companyId != null) {
      _companyId = companyId.isEmpty ? null : companyId;
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
      () => asyncHandler(
        () => _load(
          page: page,
          pageSize: pageSize,
          previous: page > 1 ? current?.items : null,
        ),
      ),
    );

    if (result.hasError && current != null) {
      state = AsyncData(current.copyWith(hasError: true));
    } else {
      state = result;
    }
  }

  Future<PaginationState<BodyguardModel>> _load({
    required int page,
    required int pageSize,
    List<BodyguardModel>? previous,
  }) async {
    final result = await _repository.getPaginated(
      page: page,
      pageSize: pageSize,
      status: status,
      search: _currentSearch,
      companyId: _companyId,
    );
    return PaginationState<BodyguardModel>(
      items: [...?previous, ...result.data],
      page: page,
      pageSize: pageSize,
      total: result.total,
    );
  }
}
