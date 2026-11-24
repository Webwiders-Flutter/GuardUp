import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/utils/callback/async_callback.handler.dart';
import '/features/company_bodyguards/data/repositories/company_bodyguards.repository.dart';
import '/features/company_bodyguards/di/company_bodyguards.providers.dart';
import '/features/users/data/repositories/user_review.repository.dart';
import '/features/users/di/users.providers.dart';

/// Review actions for one company-managed bodyguard (keyed by bodyguard id):
/// approve / reject it and its documents, or delete it. Company bodyguards
/// are never blocked.
///
/// Same contract as [UserReviewController]: loading while a request runs,
/// error with an [ApiException] on failure. On success the bodyguard's
/// details, every status listing and the company bodyguard lists are
/// refreshed, since the bodyguard may have moved between status tabs.
class CompanyBodyguardReviewController extends AsyncNotifier<void> {
  CompanyBodyguardReviewController(this.bodyguardId);

  final String bodyguardId;

  CompanyBodyguardsRepository get _bodyguards =>
      ref.read(companyBodyguardsRepositoryProvider);
  UserReviewRepository get _documents => ref.read(userReviewRepositoryProvider);

  @override
  FutureOr<void> build() {}

  Future<void> approveDocument(String documentId) =>
      _run(() => _documents.approveDocument(documentId));

  /// Also moves the bodyguard to REJECTED (database trigger).
  Future<void> rejectDocument(String documentId, String reason) =>
      _run(() => _documents.rejectDocument(documentId, reason));

  /// Fails unless every document is approved (database trigger).
  Future<void> approve() => _run(() => _bodyguards.approve(bodyguardId));

  Future<void> reject(String reason) =>
      _run(() => _bodyguards.reject(bodyguardId, reason));

  Future<void> delete() =>
      _run(() => _bodyguards.delete(bodyguardId), deleted: true);

  Future<void> _run(
    Future<void> Function() action, {
    bool deleted = false,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => asyncHandler(action));

    if (!state.hasError && ref.mounted) {
      if (!deleted) ref.invalidate(companyBodyguardDetailsProvider(bodyguardId));
      ref.invalidate(companyBodyguardsControllerProvider);
      ref.invalidate(companyBodyguardsProvider);
    }
  }
}
