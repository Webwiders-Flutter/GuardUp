import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/constants/api/storage_buckets.dart';
import '/core/error/api_exception.dart';
import '/core/logger/app_logger.dart';
import '/core/services/file_storage/file_storage.service.dart';
import '/core/services/file_storage/models/file_upload_request.model.dart';
import '/core/state/api_state.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '/features/auth/data/model/user_account_request.model.dart';
import '/features/auth/domain/repositories/user_repository.dart';
import '/features/services/data/repositories/services.repository.dart';
import '/shared/models/record_owner.model.dart';
import '../../data/model/body_guard.model.dart';
import '../../data/model/bodyguard_profile_request.model.dart';
import '../../data/repositories/availability.repository.dart';
import '../../data/repositories/bodyguard.repository.dart';
import 'guard_profile_event.dart';
import 'guard_profile_state.dart';

export 'guard_profile_event.dart';
export 'guard_profile_state.dart';

/// Handles loading and persisting profile details, avatar uploads, and
/// service assignments for both self-registered guards ([AccountOwner]) and
/// company-managed bodyguards ([ManagedBodyguardOwner]).
class GuardProfileBloc extends Bloc<GuardProfileEvent, GuardProfileState> {
  GuardProfileBloc({
    required this.bodyguardRepository,
    required this.userRepository,
    required this.servicesRepository,
    required this.availabilityRepository,
    required this.fileStorageService,
    required this.owner,
    required this.getCurrentUserId,
    this.onAccountUpdated,
    BodyGuardModel? preview,
  }) : super(GuardProfileState(profile: preview)) {
    on<GuardProfileStarted>(_onStarted, transformer: restartable());
    on<GuardProfileServicesRefreshed>(
      _onServicesRefreshed,
      transformer: restartable(),
    );
    on<GuardProfileAvatarPicked>(_onAvatarPicked);
    on<GuardProfileServicesChanged>(_onServicesChanged);
    on<GuardProfileSubmitted>(_onSubmitted, transformer: droppable());
    on<GuardProfileBioSaved>(_onBioSaved, transformer: droppable());
    on<GuardProfileKeyDetailsSaved>(
      _onKeyDetailsSaved,
      transformer: droppable(),
    );
    on<GuardProfileServicesSaved>(
      _onServicesSaved,
      transformer: droppable(),
    );
  }

  static const String _tag = 'GuardProfileBloc';

  final BodyguardRepository bodyguardRepository;
  final UserRepository userRepository;
  final ServicesRepository servicesRepository;
  final AvailabilityRepository availabilityRepository;
  final FileStorageService fileStorageService;
  final RecordOwner owner;
  final String? Function() getCurrentUserId;
  final void Function()? onAccountUpdated;

  RecordOwner get _effectiveOwner {
    final savedId = state.profile?.id;
    return switch (owner) {
      AccountOwner(:final id) => AccountOwner(
        id.isNotEmpty ? id : (getCurrentUserId() ?? ''),
      ),
      ManagedBodyguardOwner(:final id) => ManagedBodyguardOwner(
        (savedId != null && savedId.isNotEmpty) ? savedId : id,
      ),
    };
  }

  Future<void> _onStarted(
    GuardProfileStarted event,
    Emitter<GuardProfileState> emit,
  ) async {
    emit(state.copyWith(loadStatus: const ApiState.loading()));

    try {
      final services = await asyncHandler(servicesRepository.getActive);
      final activeIds = services.map((s) => s.id).toSet();

      switch (owner) {
        case AccountOwner():
          final userId = owner.id.isNotEmpty
              ? owner.id
              : (getCurrentUserId() ?? '');
          if (userId.isEmpty) {
            emit(
              state.copyWith(
                activeServices: services,
                loadStatus: const ApiState.success(null),
              ),
            );
            return;
          }

          final user = await asyncHandler(() => userRepository.getProfile(userId));
          var validServices = state.selectedServiceIds;
          try {
            final assignedIds = await asyncHandler(
              () => servicesRepository.getAssignedIds(AccountOwner(userId)),
            );
            validServices = assignedIds.where(activeIds.contains).toList();
          } catch (e, stack) {
            AppLogger.d(
              'Error loading user services: $e',
              tag: _tag,
              error: e,
              stackTrace: stack,
            );
          }

          emit(
            state.copyWith(
              activeServices: services,
              profile: user?.bodyguard ?? state.profile,
              initialAccountName: user?.name ?? state.initialAccountName,
              initialAccountAvatar:
                  user?.profileImageUrl ?? state.initialAccountAvatar,
              selectedServiceIds: validServices,
              loadStatus: const ApiState.success(null),
            ),
          );

        case ManagedBodyguardOwner():
          final targetId = _effectiveOwner.id;
          if (targetId.isEmpty) {
            emit(
              state.copyWith(
                activeServices: services,
                loadStatus: const ApiState.success(null),
              ),
            );
            return;
          }

          final results = await Future.wait<Object?>([
            asyncHandler(() => bodyguardRepository.getDetails(targetId)),
            asyncHandler(
              () => servicesRepository.getAssignedIds(
                ManagedBodyguardOwner(targetId),
              ),
            ),
          ]);
          final saved = results[0] as BodyGuardModel?;
          final assignedIds = results[1] as List<String>;
          final validServices = assignedIds.where(activeIds.contains).toList();

          emit(
            state.copyWith(
              activeServices: services,
              profile: saved ?? state.profile,
              selectedServiceIds: validServices,
              loadStatus: const ApiState.success(null),
            ),
          );
      }
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          loadStatus: ApiState.failure(e.message, error: e),
        ),
      );
    }
  }

  Future<void> _onServicesRefreshed(
    GuardProfileServicesRefreshed event,
    Emitter<GuardProfileState> emit,
  ) async {
    try {
      final services = await asyncHandler(servicesRepository.getActive);
      emit(state.copyWith(activeServices: services));
    } catch (e, stack) {
      AppLogger.d(
        'Error refreshing services: $e',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
    }
  }

  void _onAvatarPicked(
    GuardProfileAvatarPicked event,
    Emitter<GuardProfileState> emit,
  ) {
    emit(state.copyWith(pickedAvatar: event.file));
  }

  void _onServicesChanged(
    GuardProfileServicesChanged event,
    Emitter<GuardProfileState> emit,
  ) {
    emit(state.copyWith(selectedServiceIds: List<String>.from(event.serviceIds)));
  }

  Future<void> _onSubmitted(
    GuardProfileSubmitted event,
    Emitter<GuardProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        submitStatus: const ApiState.loading(),
        resubmittedForReview: false,
      ),
    );

    final sessionUserId = getCurrentUserId();
    if (sessionUserId == null || sessionUserId.isEmpty) {
      emit(
        state.copyWith(
          submitStatus: const ApiState.failure(
            'Your session has expired. Please sign in again.',
          ),
        ),
      );
      return;
    }

    try {
      String? avatarUrl =
          event.request.profileImageUrl ?? state.existingAvatarUrl;

      switch (owner) {
        case AccountOwner(:final id):
          final userId = id.isNotEmpty ? id : sessionUserId;
          final pickedAvatar = state.pickedAvatar;
          if (pickedAvatar != null) {
            try {
              avatarUrl = await asyncHandler(
                () => fileStorageService.uploadSingleFile(
                  FileUploadRequest.fromXFile(
                    bucket: StorageBuckets.avatars,
                    path:
                        '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
                    xFile: pickedAvatar,
                    upsert: true,
                  ),
                ),
              );
            } catch (e, stack) {
              AppLogger.d(
                'Avatar upload failed: $e',
                tag: _tag,
                error: e,
                stackTrace: stack,
              );
            }
          }

          // Ordering rule: write the role profile row first, then sync account identity.
          await asyncHandler(
            () => bodyguardRepository.upsertForAccount(userId, event.request),
          );
          await asyncHandler(
            () => userRepository.updateAccount(
              userId,
              UserAccountRequest(
                name: event.request.name,
                profileImageUrl: avatarUrl,
              ),
            ),
          );
          await asyncHandler(
            () => servicesRepository.assign(
              AccountOwner(userId),
              state.selectedServiceIds,
            ),
          );

          if (event.resubmitForReview) {
            await asyncHandler(() => userRepository.submitForReview(userId));
            onAccountUpdated?.call();
          }

          emit(
            state.copyWith(
              initialAccountName: event.request.name.trim(),
              initialAccountAvatar: avatarUrl,
              clearPickedAvatar: true,
              resubmittedForReview: event.resubmitForReview,
              submitStatus: ApiState.success(userId),
            ),
          );

        case ManagedBodyguardOwner():
          final pickedAvatar = state.pickedAvatar;
          if (pickedAvatar != null) {
            try {
              // First folder must be the signed-in user (storage policies).
              avatarUrl = await asyncHandler(
                () => fileStorageService.uploadSingleFile(
                  FileUploadRequest.fromXFile(
                    bucket: StorageBuckets.avatars,
                    path:
                        '$sessionUserId/bodyguards/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
                    xFile: pickedAvatar,
                    upsert: true,
                  ),
                ),
              );
            } catch (e, stack) {
              AppLogger.d(
                'Bodyguard avatar upload failed: $e',
                tag: _tag,
                error: e,
                stackTrace: stack,
              );
            }
          }

          final existingId = _effectiveOwner.id.isNotEmpty
              ? _effectiveOwner.id
              : null;
          final companyId = await asyncHandler(
            () => bodyguardRepository.getMyCompanyId(sessionUserId),
          );
          final managedRequest = BodyguardProfileRequest(
            name: event.request.name,
            hourlyRate: event.request.hourlyRate,
            bio: event.request.bio,
            experienceYears: event.request.experienceYears,
            languages: event.request.languages,
            certifications: event.request.certifications,
            qualifications: event.request.qualifications,
            address: event.request.address,
            latitude: event.request.latitude,
            longitude: event.request.longitude,
            profileImageUrl: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? avatarUrl
                : null,
          );

          final saved = await asyncHandler(
            () => bodyguardRepository.saveManaged(
              id: existingId,
              companyId: companyId,
              request: managedRequest,
            ),
          );
          await asyncHandler(
            () => servicesRepository.assign(
              ManagedBodyguardOwner(saved.id),
              state.selectedServiceIds,
            ),
          );

          if (existingId == null) {
            try {
              await availabilityRepository.seedDefaults(
                ManagedBodyguardOwner(saved.id),
              );
            } catch (e, stack) {
              AppLogger.e(
                'seedDefaults failed',
                tag: _tag,
                error: e,
                stackTrace: stack,
              );
            }
          }

          emit(
            state.copyWith(
              profile: saved,
              clearPickedAvatar: true,
              submitStatus: ApiState.success(saved.id),
            ),
          );
      }
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          submitStatus: ApiState.failure(e.message, error: e),
        ),
      );
    }
  }

  Future<void> _onBioSaved(
    GuardProfileBioSaved event,
    Emitter<GuardProfileState> emit,
  ) async {
    final target = _effectiveOwner;
    if (target.id.isEmpty) {
      emit(
        state.copyWith(
          editStatus: const ApiState.failure(
            'Your session has expired. Please sign in again.',
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(editStatus: const ApiState.loading()));
    try {
      await asyncHandler(() => bodyguardRepository.updateBio(target, event.bio));
      if (target is AccountOwner) {
        onAccountUpdated?.call();
      }
      emit(
        state.copyWith(
          profile: state.profile?.copyWith(bio: event.bio.trim()),
          editStatus: const ApiState.success(GuardProfileEditKind.bio),
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(editStatus: ApiState.failure(e.message, error: e)));
    }
  }

  Future<void> _onKeyDetailsSaved(
    GuardProfileKeyDetailsSaved event,
    Emitter<GuardProfileState> emit,
  ) async {
    final target = _effectiveOwner;
    if (target.id.isEmpty) {
      emit(
        state.copyWith(
          editStatus: const ApiState.failure(
            'Your session has expired. Please sign in again.',
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(editStatus: const ApiState.loading()));
    try {
      await asyncHandler(
        () => bodyguardRepository.updateKeyDetails(
          target,
          experienceYears: event.experienceYears,
          hourlyRate: event.hourlyRate,
          address: event.address,
          latitude: event.latitude,
          longitude: event.longitude,
          languages: event.languages,
          certifications: event.certifications,
          qualifications: event.qualifications,
        ),
      );
      if (target is AccountOwner) {
        onAccountUpdated?.call();
      }
      emit(
        state.copyWith(
          profile: state.profile?.copyWith(
            experienceYears: event.experienceYears,
            hourlyRate: event.hourlyRate.toDouble(),
            address: event.address.trim(),
            latitude: event.latitude ?? state.profile?.latitude,
            longitude: event.longitude ?? state.profile?.longitude,
            languages: event.languages.trim(),
            certifications: event.certifications.trim(),
            qualifications: event.qualifications.trim(),
          ),
          editStatus: const ApiState.success(GuardProfileEditKind.keyDetails),
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(editStatus: ApiState.failure(e.message, error: e)));
    }
  }

  Future<void> _onServicesSaved(
    GuardProfileServicesSaved event,
    Emitter<GuardProfileState> emit,
  ) async {
    final target = _effectiveOwner;
    if (target.id.isEmpty) {
      emit(
        state.copyWith(
          editStatus: const ApiState.failure(
            'Your session has expired. Please sign in again.',
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(editStatus: const ApiState.loading()));
    try {
      await asyncHandler(
        () => servicesRepository.assign(target, event.serviceIds),
      );
      if (target is AccountOwner) {
        onAccountUpdated?.call();
      }
      emit(
        state.copyWith(
          selectedServiceIds: List<String>.from(event.serviceIds),
          editStatus: const ApiState.success(GuardProfileEditKind.services),
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(editStatus: ApiState.failure(e.message, error: e)));
    }
  }
}
