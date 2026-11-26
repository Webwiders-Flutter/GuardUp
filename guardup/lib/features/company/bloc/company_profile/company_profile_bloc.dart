import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/constants/api/storage_buckets.dart';
import '/core/error/api_exception.dart';
import '/core/services/file_storage/file_storage.service.dart';
import '/core/services/file_storage/models/file_upload_request.model.dart';
import '/core/state/api_state.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '/features/auth/data/model/user_account_request.model.dart';
import '/features/auth/domain/repositories/user_repository.dart';
import '../../data/repositories/company.repository.dart';
import 'company_profile_event.dart';
import 'company_profile_state.dart';

export 'company_profile_event.dart';
export 'company_profile_state.dart';

/// Manages loading and saving company account profile details (`public.companies`
/// + `public.users` name/logo) for onboarding, edit, and read-only views.
class CompanyProfileBloc
    extends Bloc<CompanyProfileEvent, CompanyProfileState> {
  CompanyProfileBloc({
    required this.companyRepository,
    required this.userRepository,
    required this.fileStorageService,
    required this.getCurrentUserId,
    this.onAccountUpdated,
  }) : super(const CompanyProfileState()) {
    on<CompanyProfileStarted>(_onStarted, transformer: restartable());
    on<CompanyProfileLogoPicked>(_onLogoPicked);
    on<CompanyProfileSubmitted>(_onSubmitted, transformer: droppable());
  }

  final CompanyRepository companyRepository;
  final UserRepository userRepository;
  final FileStorageService fileStorageService;
  final String? Function() getCurrentUserId;
  final void Function()? onAccountUpdated;

  Future<void> _onStarted(
    CompanyProfileStarted event,
    Emitter<CompanyProfileState> emit,
  ) async {
    final userId = getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      emit(state.copyWith(loadStatus: const ApiState.success(null)));
      return;
    }

    emit(state.copyWith(loadStatus: const ApiState.loading()));
    try {
      final company = await asyncHandler(
        () => companyRepository.getByUserId(userId),
      );
      emit(
        state.copyWith(
          company: company,
          loadStatus: const ApiState.success(null),
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          loadStatus: ApiState.failure(e.message, error: e),
        ),
      );
    }
  }

  void _onLogoPicked(
    CompanyProfileLogoPicked event,
    Emitter<CompanyProfileState> emit,
  ) {
    emit(state.copyWith(pickedLogo: event.file));
  }

  Future<void> _onSubmitted(
    CompanyProfileSubmitted event,
    Emitter<CompanyProfileState> emit,
  ) async {
    final userId = getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      emit(
        state.copyWith(
          submitStatus: const ApiState.failure(
            'Your session has expired. Please sign in again.',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        submitStatus: const ApiState.loading(),
        resubmittedForReview: false,
      ),
    );

    try {
      String? logoUrl;
      final pickedLogo = state.pickedLogo;
      if (pickedLogo != null) {
        final rawName = pickedLogo.name;
        final ext = rawName.contains('.') ? rawName.split('.').last : 'jpg';
        final storagePath =
            '$userId/logo_${DateTime.now().millisecondsSinceEpoch}.$ext';
        logoUrl = await asyncHandler(
          () => fileStorageService.uploadSingleFile(
            FileUploadRequest.fromXFile(
              bucket: StorageBuckets.documents,
              path: storagePath,
              xFile: pickedLogo,
              upsert: true,
            ),
          ),
        );
      }

      // Ordering rule: write the role profile row first, then sync users account.
      await asyncHandler(
        () => companyRepository.upsertForAccount(userId, event.request),
      );
      await asyncHandler(
        () => userRepository.updateAccount(
          userId,
          UserAccountRequest(
            name: event.request.companyName,
            profileImageUrl: logoUrl,
          ),
        ),
      );

      if (event.resubmitForReview) {
        await asyncHandler(() => userRepository.submitForReview(userId));
      }

      if (event.resubmitForReview || event.refreshAccount) {
        onAccountUpdated?.call();
      }

      emit(
        state.copyWith(
          clearPickedLogo: true,
          resubmittedForReview: event.resubmitForReview,
          submitStatus: const ApiState.success(null),
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          submitStatus: ApiState.failure(e.message, error: e),
        ),
      );
    }
  }
}

