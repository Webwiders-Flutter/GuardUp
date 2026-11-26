import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

import '/core/state/api_state.dart';
import '/features/services/data/models/service.model.dart';
import '../../data/model/body_guard.model.dart';

/// Identifies which inline edit sheet last completed or failed.
enum GuardProfileEditKind { bio, keyDetails, services }

/// Immutable state for [GuardProfileBloc].
final class GuardProfileState extends Equatable {
  const GuardProfileState({
    this.loadStatus = const ApiState.initial(),
    this.profile,
    this.initialAccountName,
    this.initialAccountAvatar,
    this.activeServices = const [],
    this.selectedServiceIds = const [],
    this.pickedAvatar,
    this.submitStatus = const ApiState.initial(),
    this.resubmittedForReview = false,
    this.editStatus = const ApiState.initial(),
  });

  final ApiState<void> loadStatus;
  final BodyGuardModel? profile;
  final String? initialAccountName;
  final String? initialAccountAvatar;
  final List<ServiceModel> activeServices;
  final List<String> selectedServiceIds;
  final XFile? pickedAvatar;

  /// On success, holds the saved record id (user id or managed bodyguard id).
  final ApiState<String> submitStatus;
  final bool resubmittedForReview;

  /// Status for inline edit-sheet saves (bio, key details, services).
  final ApiState<GuardProfileEditKind> editStatus;

  /// Currently selected services resolved against [activeServices].
  List<ServiceModel> get selectedServices {
    if (selectedServiceIds.isEmpty) return const [];
    final selectedSet = selectedServiceIds.toSet();
    return activeServices.where((s) => selectedSet.contains(s.id)).toList();
  }

  /// Existing remote avatar URL, preferring the bodyguard row over account.
  String? get existingAvatarUrl {
    final guardAvatar = profile?.profileImageUrl;
    if (guardAvatar != null && guardAvatar.isNotEmpty) return guardAvatar;
    final accountAvatar = initialAccountAvatar;
    if (accountAvatar != null && accountAvatar.isNotEmpty) return accountAvatar;
    return null;
  }

  /// Initial display name for prefilling the complete-profile form.
  String get resolvedInitialName {
    final guardName = profile?.name;
    if (guardName != null &&
        guardName.isNotEmpty &&
        guardName != 'User' &&
        guardName != 'New User') {
      return guardName;
    }
    final accountName = initialAccountName;
    if (accountName != null &&
        accountName.isNotEmpty &&
        accountName != 'User' &&
        accountName != 'New User') {
      return accountName;
    }
    return '';
  }

  GuardProfileState copyWith({
    ApiState<void>? loadStatus,
    BodyGuardModel? profile,
    String? initialAccountName,
    String? initialAccountAvatar,
    List<ServiceModel>? activeServices,
    List<String>? selectedServiceIds,
    XFile? pickedAvatar,
    bool clearPickedAvatar = false,
    ApiState<String>? submitStatus,
    bool? resubmittedForReview,
    ApiState<GuardProfileEditKind>? editStatus,
  }) {
    return GuardProfileState(
      loadStatus: loadStatus ?? this.loadStatus,
      profile: profile ?? this.profile,
      initialAccountName: initialAccountName ?? this.initialAccountName,
      initialAccountAvatar: initialAccountAvatar ?? this.initialAccountAvatar,
      activeServices: activeServices ?? this.activeServices,
      selectedServiceIds: selectedServiceIds ?? this.selectedServiceIds,
      pickedAvatar: clearPickedAvatar
          ? null
          : (pickedAvatar ?? this.pickedAvatar),
      submitStatus: submitStatus ?? this.submitStatus,
      resubmittedForReview:
          resubmittedForReview ?? this.resubmittedForReview,
      editStatus: editStatus ?? this.editStatus,
    );
  }

  @override
  List<Object?> get props => [
    loadStatus,
    profile,
    initialAccountName,
    initialAccountAvatar,
    activeServices,
    selectedServiceIds,
    pickedAvatar,
    submitStatus,
    resubmittedForReview,
    editStatus,
  ];
}

