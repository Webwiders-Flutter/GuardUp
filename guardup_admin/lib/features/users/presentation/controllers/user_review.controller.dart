import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/utils/callback/async_callback.handler.dart';
import '/features/users/data/repositories/user_review.repository.dart';
import '/features/users/di/users.providers.dart';

/// Review actions for one user's application (keyed by user id).
///
/// State is the status of the last action: loading while a request is in
/// flight (the screen disables every review button meanwhile), error with an
/// [ApiException] on failure. On success the user's details and every users
/// list are refreshed, since the user may have moved between status tabs.
class UserReviewController extends AsyncNotifier<void> {
  UserReviewController(this.userId);

  final String userId;

  UserReviewRepository get _repository =>
      ref.read(userReviewRepositoryProvider);

  @override
  FutureOr<void> build() {}

  Future<void> approveDocument(String documentId) =>
      _run(() => _repository.approveDocument(documentId));

  Future<void> rejectDocument(String documentId, String reason) =>
      _run(() => _repository.rejectDocument(documentId, reason));

  Future<void> approveUser() => _run(() => _repository.approveUser(userId));

  Future<void> rejectUser(String reason) =>
      _run(() => _repository.rejectUser(userId, reason));

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => asyncHandler(action));

    if (!state.hasError && ref.mounted) {
      ref.invalidate(userDetailsProvider(userId));
      ref.invalidate(usersControllerProvider);
    }
  }
}
