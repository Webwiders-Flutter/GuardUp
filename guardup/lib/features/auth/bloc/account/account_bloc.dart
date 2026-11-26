import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/constants/api/storage_buckets.dart';
import '/core/error/api_exception.dart';
import '/core/services/file_storage/file_storage.service.dart';
import '/core/services/file_storage/models/file_upload_request.model.dart';
import '/core/state/api_state.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '../../data/model/user_account_request.model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'account_event.dart';
import 'account_state.dart';

export 'account_event.dart';
export 'account_state.dart';

/// Screen-scoped Bloc handling account profile updates, status checks,
/// password changes, and account deletion.
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc({
    required this.authRepository,
    required this.userRepository,
    required this.fileStorageService,
    required this.getCurrentUserId,
    this.onAccountUpdated,
    this.onAccountDeleted,
  }) : super(const AccountState()) {
    on<AccountProfileSaved>(_onProfileSaved, transformer: droppable());
    on<AccountProfileRefreshed>(
      _onProfileRefreshed,
      transformer: restartable(),
    );
    on<AccountPasswordChanged>(_onPasswordChanged, transformer: droppable());
    on<AccountDeleteRequested>(_onDeleteRequested, transformer: droppable());
  }

  final AuthRepository authRepository;
  final UserRepository userRepository;
  final FileStorageService fileStorageService;
  final String? Function() getCurrentUserId;
  final void Function()? onAccountUpdated;
  final void Function()? onAccountDeleted;

  Future<void> _onProfileSaved(
    AccountProfileSaved event,
    Emitter<AccountState> emit,
  ) async {
    final userId = getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      emit(
        state.copyWith(
          status: const ApiState.failure(
            'Your session has expired. Please sign in again.',
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(status: const ApiState.loading()));

    try {
      String? avatarUrl = event.request.profileImageUrl;
      final avatarFile = event.avatar;
      if (avatarFile != null) {
        final rawName = avatarFile.name;
        final ext = rawName.contains('.') ? rawName.split('.').last : 'jpg';
        final storagePath =
            '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
        avatarUrl = await asyncHandler(
          () => fileStorageService.uploadSingleFile(
            FileUploadRequest.fromXFile(
              bucket: StorageBuckets.avatars,
              path: storagePath,
              xFile: avatarFile,
              upsert: true,
            ),
          ),
        );
      }

      final request = UserAccountRequest(
        name: event.request.name,
        email: event.request.email,
        phoneCode: event.request.phoneCode,
        phoneNumber: event.request.phoneNumber,
        profileImageUrl: avatarUrl,
        gender: event.request.gender,
        isPushNotificationEnabled: event.request.isPushNotificationEnabled,
      );

      final updated = await asyncHandler(
        () => userRepository.updateAccount(userId, request),
      );
      onAccountUpdated?.call();

      emit(
        state.copyWith(
          updatedUser: updated,
          status: const ApiState.success(AccountAction.profileSaved),
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: ApiState.failure(e.message, error: e)));
    }
  }

  Future<void> _onProfileRefreshed(
    AccountProfileRefreshed event,
    Emitter<AccountState> emit,
  ) async {
    final userId = getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      emit(
        state.copyWith(
          status: const ApiState.failure(
            'Your session has expired. Please sign in again.',
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(status: const ApiState.loading()));
    try {
      final profile = await asyncHandler(() => userRepository.getProfile(userId));
      onAccountUpdated?.call();
      emit(
        state.copyWith(
          updatedUser: profile,
          status: const ApiState.success(AccountAction.profileRefreshed),
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: ApiState.failure(e.message, error: e)));
    }
  }

  Future<void> _onPasswordChanged(
    AccountPasswordChanged event,
    Emitter<AccountState> emit,
  ) async {
    if (event.oldPassword == event.newPassword) {
      emit(
        state.copyWith(
          status: ApiState.failure(
            'New password must be different from current password.',
            error: ApiException(
              'New password must be different from current password.',
              type: ApiErrorType.validation,
            ),
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(status: const ApiState.loading()));

    try {
      await asyncHandler(
        () => authRepository.changePassword(
          newPassword: event.newPassword,
          oldPassword: event.oldPassword,
        ),
      );
      emit(
        state.copyWith(
          status: const ApiState.success(AccountAction.passwordChanged),
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: ApiState.failure(e.message, error: e)));
    }
  }

  Future<void> _onDeleteRequested(
    AccountDeleteRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(status: const ApiState.loading()));

    try {
      await asyncHandler(authRepository.deleteAccount);
      onAccountDeleted?.call();
      emit(
        state.copyWith(
          status: const ApiState.success(AccountAction.accountDeleted),
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: ApiState.failure(
            'Failed to delete account. Please try again.',
            error: e,
          ),
        ),
      );
    }
  }
}
