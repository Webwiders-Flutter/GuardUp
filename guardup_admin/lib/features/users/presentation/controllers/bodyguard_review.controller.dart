import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/utils/callback/async_callback.handler.dart';
import '/features/users/data/repositories/bodyguards.repository.dart';
import '/features/users/data/repositories/user_review.repository.dart';
import '/features/users/di/users.providers.dart';

/// Review actions for the company-managed bodyguards of one company (keyed by
/// `companies.id`). Same contract as [UserReviewController]: loading while a
/// request runs, error with an [ApiException] on failure, and the company's
/// bodyguard list is reloaded on success.
class BodyguardReviewController extends AsyncNotifier<void> {
  BodyguardReviewController(this.companyId);

  final String companyId;

  BodyguardsRepository get _bodyguards =>
      ref.read(bodyguardsRepositoryProvider);
  UserReviewRepository get _documents => ref.read(userReviewRepositoryProvider);

  @override
  FutureOr<void> build() {}

  Future<void> approveDocument(String documentId) =>
      _run(() => _documents.approveDocument(documentId));

  Future<void> rejectDocument(String documentId, String reason) =>
      _run(() => _documents.rejectDocument(documentId, reason));

  Future<void> approve(String bodyguardId) =>
      _run(() => _bodyguards.approve(bodyguardId));

  Future<void> reject(String bodyguardId, String reason) =>
      _run(() => _bodyguards.reject(bodyguardId, reason));

  Future<void> setBlocked(String bodyguardId, {required bool blocked}) =>
      _run(() => _bodyguards.setBlocked(bodyguardId, blocked: blocked));

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => asyncHandler(action));

    if (!state.hasError && ref.mounted) {
      ref.invalidate(companyBodyguardsProvider(companyId));
    }
  }
}
