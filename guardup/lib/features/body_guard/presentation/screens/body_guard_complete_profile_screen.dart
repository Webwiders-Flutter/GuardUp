import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/api/storage_buckets.dart';
import 'package:guardup/core/constants/app_radius.dart';
import 'package:guardup/core/extensions/number.extension.dart';
import 'package:guardup/core/services/file_storage/file_storage.service.dart';
import 'package:guardup/core/services/file_storage/models/file_upload_request.model.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/api/database_tables.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/auth.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/services/document_submission/document_submission_service.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_dropdown.dart';
import '/shared/widgets/inputs/app_media_picker_sheet.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/misc/app_input_label.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/selection/selection.dart';
import '../../data/model/service_item.model.dart';
import '/features/body_guard/presentation/screens/body_guard_upload_documents_screen.dart';

/// Screen for bodyguard profile setup / entering professional details.
///
/// Follows GuardUp Development Rules & Architectural Guidelines:
/// - State Management: [ValueNotifier] & [ValueListenableBuilder] over `setState()`.
/// - Localization: all user-facing strings accessed via [context.l10n].
/// - Theming & Tokens: strict adherence to [context.colors], [context.textTheme], and [AppSpacing].
/// - Form Layout: [LayoutBuilder] + [ConstrainedBox] + [IntrinsicHeight] + [Spacer] onboarding pattern.
class BodyGuardCompleteProfileScreen extends StatefulWidget {
  static const route = '/bodyguard-profile';

  const BodyGuardCompleteProfileScreen({super.key});

  @override
  State<BodyGuardCompleteProfileScreen> createState() =>
      _BodyGuardCompleteProfileScreenState();
}

class _BodyGuardCompleteProfileScreenState
    extends State<BodyGuardCompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  final _hourlyRateController = TextEditingController();
  final _bioController = TextEditingController();

  final _serviceDropdownController = SelectionController<String>.single();
  final ValueNotifier<List<String>> _selectedServicesNotifier =
      ValueNotifier<List<String>>([]);

  /// Available active services dynamically fetched from DatabaseTables.services.
  final ValueNotifier<List<ServiceItemModel>> _availableServicesNotifier =
      ValueNotifier<List<ServiceItemModel>>([]);
  final ValueNotifier<bool> _isServicesLoadingNotifier =
      ValueNotifier<bool>(true);

  /// Isolated avatar profile picture notifier matching edit profile UI.
  final ValueNotifier<XFile?> _profileImageNotifier = ValueNotifier<XFile?>(
    null,
  );
  final ValueNotifier<String?> _networkImageUrlNotifier = ValueNotifier<String?>(
    null,
  );
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    final authUser =
        sl.isRegistered<AuthBloc>() ? sl<AuthBloc>().state.user : null;
    final metaName =
        Supabase.instance.client.auth.currentUser?.userMetadata?['name']
            as String?;

    final initialName =
        (authUser?.name != null &&
                authUser!.name.isNotEmpty &&
                authUser.name != 'User' &&
                authUser.name != 'New User')
            ? authUser.name
            : (metaName ?? '');

    _fullNameController = TextEditingController(text: initialName);
    _initData();
  }

  Future<void> _initData() async {
    await _loadServices();
    await _loadExistingProfile();
  }

  Future<void> _loadServices() async {
    try {
      final rows = await Supabase.instance.client
          .from(DatabaseTables.services)
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      if (mounted) {
        _availableServicesNotifier.value =
            rows.map((r) => ServiceItemModel.fromJson(r)).toList();
      }
    } catch (e, stack) {
      debugPrint('Error loading services: $e\n$stack');
    } finally {
      if (mounted) {
        _isServicesLoadingNotifier.value = false;
      }
    }
  }

  Future<void> _loadExistingProfile() async {
    final currentUserId = sl.isRegistered<AuthRepository>()
        ? sl<AuthRepository>().currentUserId
        : null;
    if (currentUserId == null || !sl.isRegistered<UserRepository>()) return;

    try {
      final data = await sl<UserRepository>().getUserData(currentUserId);
      if (data != null && mounted) {
        final dbName = data['name'] as String?;
        if (dbName != null &&
            dbName.isNotEmpty &&
            dbName != 'User' &&
            dbName != 'New User' &&
            _fullNameController.text.isEmpty) {
          _fullNameController.text = dbName;
        }

        final dbRate = data['hourly_rate'];
        if (dbRate != null && _hourlyRateController.text.isEmpty) {
          final rateNum = double.tryParse(dbRate.toString()) ?? 0.0;
          if (rateNum > 0) {
            _hourlyRateController.text = rateNum.toInt().toString();
          }
        }

        final dbBio = data['bio'] as String?;
        if (dbBio != null && dbBio.isNotEmpty && _bioController.text.isEmpty) {
          _bioController.text = dbBio;
        }

        try {
          final userServicesRows = await Supabase.instance.client
              .from(DatabaseTables.userServices)
              .select('service_id')
              .eq('user_id', currentUserId);
          final activeIds =
              _availableServicesNotifier.value.map((s) => s.id).toSet();
          final validServices = (userServicesRows as List<dynamic>)
              .map((r) => r['service_id']?.toString() ?? '')
              .where((id) => id.isNotEmpty && activeIds.contains(id))
              .toList();
          _selectedServicesNotifier.value = validServices;
        } catch (e, stack) {
          debugPrint('Error loading user services: $e\n$stack');
        }

        final dbAvatar = data['profile_image_url'] as String?;
        if (dbAvatar != null &&
            dbAvatar.isNotEmpty &&
            _profileImageNotifier.value == null) {
          _networkImageUrlNotifier.value = dbAvatar;
        }
      }
    } catch (e, stack) {
      debugPrint('Error loading existing profile: $e\n$stack');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _hourlyRateController.dispose();
    _bioController.dispose();
    _selectedServicesNotifier.dispose();
    _serviceDropdownController.dispose();
    _availableServicesNotifier.dispose();
    _isServicesLoadingNotifier.dispose();
    _profileImageNotifier.dispose();
    _networkImageUrlNotifier.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  /// Profile picture picker matching edit profile logic exactly.
  Future<void> _handleChangePhoto() async {
    final pickedFile = await AppMediaPickerSheet.show(
      context: context,
      allowCrop: true,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.original,
      ],
      lockAspectRatio: false,
    );

    if (pickedFile != null && mounted) {
      _profileImageNotifier.value = pickedFile;
    }
  }

  void _handleRemoveService(String serviceCode) {
    _selectedServicesNotifier.value =
        List<String>.from(_selectedServicesNotifier.value)..remove(serviceCode);
  }

  Future<void> _handleNext() async {
    if (_isLoadingNotifier.value) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_profileImageNotifier.value == null &&
        (_networkImageUrlNotifier.value == null ||
            _networkImageUrlNotifier.value!.isEmpty)) {
      AppSnackbar.error(context.l10n.pleaseUploadProfilePhoto);
      return;
    }

    if (_selectedServicesNotifier.value.isEmpty) {
      AppSnackbar.error(context.l10n.pleaseSelectAtLeastOneService);
      return;
    }

    final currentUserId = sl.isRegistered<AuthRepository>()
        ? sl<AuthRepository>().currentUserId
        : null;

    if (currentUserId == null) {
      AppSnackbar.error('User session expired. Please sign in again.');
      return;
    }

    _isLoadingNotifier.value = true;

    try {
      if (sl.isRegistered<UserRepository>()) {
        String? avatarUrl = _networkImageUrlNotifier.value;
        final pickedAvatar = _profileImageNotifier.value;
        if (pickedAvatar != null && sl.isRegistered<FileStorageService>()) {
          try {
            avatarUrl = await sl<FileStorageService>().uploadSingleFile(
              FileUploadRequest.fromXFile(
                bucket: StorageBuckets.avatars,
                path:
                    '$currentUserId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
                xFile: pickedAvatar,
                upsert: true,
              ),
            );
          } catch (e, stack) {
            debugPrint('Avatar upload failed: $e\n$stack');
          }
        }

        final updatePayload = <String, dynamic>{
          'name': _fullNameController.text.trim(),
          'hourly_rate':
              double.tryParse(_hourlyRateController.text.trim()) ?? 0.0,
          'bio': _bioController.text.trim(),
        };
        if (avatarUrl != null) {
          updatePayload['profile_image_url'] = avatarUrl;
        }

        await sl<UserRepository>().updateProfileFields(
          userId: currentUserId,
          data: updatePayload,
        );

        // Atomic sync of services in user_services junction table
        try {
          await Supabase.instance.client.rpc(
            'set_user_services',
            params: {
              'p_user_id': currentUserId,
              'p_service_ids': _selectedServicesNotifier.value,
            },
          );
        } catch (_) {
          // Fallback to sequential delete + insert if RPC is not yet created
          await Supabase.instance.client
              .from(DatabaseTables.userServices)
              .delete()
              .eq('user_id', currentUserId);

          if (_selectedServicesNotifier.value.isNotEmpty) {
            final insertPayload = _selectedServicesNotifier.value
                .map((serviceId) => {
                      'user_id': currentUserId,
                      'service_id': serviceId,
                    })
                .toList();

            await Supabase.instance.client
                .from(DatabaseTables.userServices)
                .insert(insertPayload);
          }
        }
      }

      if (mounted) {
        final authState =
            sl.isRegistered<AuthBloc>() ? sl<AuthBloc>().state : null;
        final isRejected = authState?.isRejected == true;
        final hasRejectedDocs = authState?.hasRejectedDocuments == true;

        if (isRejected && !hasRejectedDocs) {
          // Only profile was rejected, documents are already fine.
          // Resubmit application directly to PENDING_APPROVAL!
          final currentUserId = sl.isRegistered<AuthRepository>()
              ? sl<AuthRepository>().currentUserId
              : null;
          if (currentUserId != null) {
            await sl<DocumentSubmissionService>()
                .submitApplicationForReview(currentUserId);
            if (sl.isRegistered<AuthBloc>()) {
              sl<AuthBloc>().add(const AuthCheckStatusRequested());
              sl<AuthBloc>().add(const AuthReloadRoleDataRequested());
            }
          }
          if (mounted) {
            AppSnackbar.success(
              'Profile updated successfully! Your application has been resubmitted for review.',
            );
            context.go(AdminApprovalScreen.route);
          }
        } else {
          context.go(BodyGuardUploadDocumentsScreen.route);
        }
      }
    } catch (e, stack) {
      debugPrint('Failed to save bodyguard profile: $e\n$stack');
      if (mounted) {
        AppSnackbar.error('Failed to save profile details. Please try again.');
      }
    } finally {
      if (mounted) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(
        title: context.l10n.profileSetupTitle,
        fontSize: 14,
        alignTitle: sl<AuthBloc>().state.isAuthenticated ? .right : .center,
        actions: [
          IconButton(
            tooltip: context.l10n.logOut,
            icon: Icon(
              Icons.logout_rounded,
              color: context.colors.error,
              size: AppSizes.iconSmd,
            ),
            onPressed: () async {
              final result = await AppPopup.showLogoutConfirmation(context);
              if (result?.action == PopupAction.confirm && context.mounted) {
                sl<AuthBloc>().add(const AuthSignOutRequested());
                context.go(LoginScreen.route);
              }
            },
          ),
          AppSpacing.xs.w,
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              color: context.colors.primary,
              backgroundColor: context.colors.surface,
              onRefresh: _loadServices,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: context.horizontalEdgeInsets,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSpacing.lg.h,

                        // Profile Rejection Reason Banner
                        Builder(
                          builder: (context) {
                            final authState = sl.isRegistered<AuthBloc>()
                                ? sl<AuthBloc>().state
                                : null;
                            final profileReason =
                                authState?.profileRejectionReason;
                            if (authState?.isRejected != true ||
                                profileReason == null ||
                                profileReason.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: EdgeInsets.only(bottom: AppSpacing.lg),
                              child: Container(
                                width: double.infinity,
                                padding: AppSpacing.md.allPadding,
                                decoration: BoxDecoration(
                                  color: context.colors.error
                                      .withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: context.colors.error
                                        .withValues(alpha: 0.4),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: context.colors.error,
                                      size: 20,
                                    ),
                                    AppSpacing.sm.w,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Profile Revision Requested',
                                            style: context
                                                .textTheme.labelMedium
                                                ?.bold()
                                                .colour(context.colors.error),
                                          ),
                                          AppSpacing.xxs.h,
                                          Text(
                                            profileReason,
                                            style: context
                                                .textTheme.bodySmall
                                                ?.colour(
                                                  context.colors.onSurface,
                                                )
                                                .copyWith(height: 1.35),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // 1. Profile Picture (Dashed Circular Border Picker)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: _handleChangePhoto,
                                    behavior: HitTestBehavior.opaque,
                                    child: CustomPaint(
                                      painter: _DashedCirclePainter(
                                        color: context.colors.primary,
                                        strokeWidth: 1,
                                        dashLength: 7.5,
                                        gapLength: 6.0,
                                      ),
                                      child: Container(
                                        width: 110,
                                        height: 110,
                                        alignment: Alignment.center,
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: context.colors.onPrimary,
                                          ),
                                          child: ValueListenableBuilder<XFile?>(
                                            valueListenable:
                                                _profileImageNotifier,
                                            builder: (context, profileImage, _) {
                                              if (profileImage != null) {
                                                return ClipOval(
                                                  child: AppImage.xFile(
                                                    xFile: profileImage,
                                                    width: 108,
                                                    height: 108,
                                                    fit: BoxFit.cover,
                                                  ),
                                                );
                                              }

                                              return ValueListenableBuilder<String?>(
                                                valueListenable:
                                                    _networkImageUrlNotifier,
                                                builder: (context, networkUrl, _) {
                                                  if (networkUrl != null &&
                                                      networkUrl.isNotEmpty) {
                                                    return ClipOval(
                                                      child: AppImage.network(
                                                        imageUrl: networkUrl,
                                                        width: 108,
                                                        height: 108,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    );
                                                  }

                                                  return Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .person_outline_rounded,
                                                        size: 38,
                                                        color: context
                                                            .colors.outline,
                                                      ),
                                                      6.h,
                                                      Text(
                                                        context.l10n.addPhoto,
                                                        style: context
                                                            .textTheme
                                                            .labelSmall
                                                            ?.regular()
                                                            .copyWith(
                                                              fontSize: 10.0,
                                                              letterSpacing: 0.2,
                                                            )
                                                            .colour(
                                                              context
                                                                  .colors
                                                                  .primary,
                                                            ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Plus Icon Badge at Bottom Right
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: GestureDetector(
                                      onTap: _handleChangePhoto,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              context.colors.primaryContainer,
                                          border: Border.all(
                                            color: context.colors.surface,
                                            width: 3.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.35,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.add_rounded,
                                          size: 22,
                                          color: context.colors.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.smd.h,
                              Text(
                                context.l10n.uploadPortraitGuidance,
                                style: context.textTheme.labelMedium
                                    ?.regular()
                                    .colour(context.colors.outline),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.xxl.h,

                        // 2. Full Name Field
                        AppFieldLabel(text: context.l10n.fullNameLabel),
                        AppSpacing.sm.h,
                        AppTextField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            hintText: context.l10n.enterFullName,
                            fillColor: context.colors.onPrimary,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.md.toBorderRadius,
                              borderSide: BorderSide(
                                color: context.colors.outlineVariant,
                              ),
                            ),
                          ),
                          style: TextStyle(color: context.colors.onSurface),
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.required(context, value),
                        ),
                        AppSpacing.xxl.h,

                        // 3. Hourly Rate Field
                        AppFieldLabel(text: context.l10n.hourlyRateLabel),
                        AppSpacing.sm.h,
                        AppTextField(
                          controller: _hourlyRateController,
                          decoration: InputDecoration(
                            hintText: context.l10n.enterHourlyRate,
                            prefix: Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.xs,
                                right: AppSpacing.sm,
                              ),
                              child: Text(
                                r'$',
                                style: context.textTheme.titleMedium
                                    ?.bold()
                                    .colour(context.colors.primary),
                              ),
                            ),
                            suffix: Text(
                              context.l10n.perHour,
                              style: context.textTheme.bodyMedium?.colour(
                                context.colors.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.md.toBorderRadius,
                              borderSide: BorderSide(
                                color: context.colors.outlineVariant,
                              ),
                            ),
                            fillColor: context.colors.onPrimary,
                          ),
                          style: TextStyle(color: context.colors.onSurface),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final requiredError = Validators.required(
                              context,
                              value,
                              fieldName: context.l10n.hourlyRateLabel,
                            );
                            if (requiredError != null) return requiredError;

                            final rate = double.tryParse(value!.trim());
                            if (rate == null || rate <= 0) {
                              return context.l10n.hourlyRateGreaterThanZero;
                            }
                            return null;
                          },
                        ),
                        AppSpacing.xxl.h,

                        // 4. Services Offered Section (Dynamically loaded from DatabaseTables.services)
                        ValueListenableBuilder<List<ServiceItemModel>>(
                          valueListenable: _availableServicesNotifier,
                          builder: (context, availableServices, _) {
                            final activeServices = availableServices
                                .where((s) => s.isActive)
                                .toList();

                            return ValueListenableBuilder<List<String>>(
                              valueListenable: _selectedServicesNotifier,
                              builder: (context, selectedServices, _) {
                                final remainingServices = activeServices
                                    .where(
                                      (s) => !selectedServices.contains(s.id),
                                    )
                                    .toList();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        AppFieldLabel(
                                          text:
                                              context.l10n.servicesOfferedLabel,
                                        ),
                                        Text(
                                          context.l10n.selectedServicesCount(
                                            selectedServices.length,
                                          ),
                                          style: context.textTheme.labelSmall
                                              ?.bold()
                                              .colour(context.colors.primary),
                                        ),
                                      ],
                                    ),
                                    if (selectedServices.isNotEmpty) ...[
                                      AppSpacing.lg.h,
                                      Wrap(
                                        spacing: AppSpacing.sm,
                                        runSpacing: AppSpacing.sm,
                                        children: selectedServices.map((serviceId) {
                                          final serviceModel =
                                              activeServices.firstWhere(
                                            (s) => s.id == serviceId,
                                            orElse: () => ServiceItemModel(
                                              id: serviceId,
                                              code: '',
                                              name: 'Service',
                                            ),
                                          );
                                          return AppRemovableChip(
                                            text: serviceModel.name,
                                            onRemove: () =>
                                                _handleRemoveService(serviceId),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                    AppSpacing.lg.h,
                                    AppDropdown<String>(
                                      key: ValueKey(
                                        'services_dropdown_${selectedServices.join('_')}',
                                      ),
                                      controller: _serviceDropdownController,
                                      hintText: context.l10n.selectService,
                                      closeOnSelect: true,
                                      target: (fieldKey) {
                                        return AppTextField(
                                          key: fieldKey,
                                          readOnly: true,
                                          decoration: InputDecoration(
                                            hintText:
                                                context.l10n.selectService,
                                            suffixIcon: Icon(
                                              Icons.expand_more,
                                              color: context.colors.outline,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  AppRadius.md.toBorderRadius,
                                              borderSide: BorderSide(
                                                color: context
                                                    .colors.outlineVariant,
                                              ),
                                            ),
                                            fillColor: context.colors.onPrimary,
                                          ),
                                          style: TextStyle(
                                            color: context.colors.onSurface,
                                          ),
                                        );
                                      },
                                      items: remainingServices
                                          .map(
                                            (e) => DropdownItem<String>(
                                              id: e.id,
                                              data: e.name,
                                            ),
                                          )
                                          .toList(),
                                      onSelected: (serviceId) {
                                        if (!_selectedServicesNotifier.value
                                            .contains(serviceId)) {
                                          _selectedServicesNotifier.value = [
                                            ..._selectedServicesNotifier.value,
                                            serviceId,
                                          ];
                                        }
                                        _serviceDropdownController.clear();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        AppSpacing.xxl.h,

                        // 5. Bio & Background Field
                        AppFieldLabel(text: context.l10n.bioBackgroundLabel),
                        AppSpacing.sm.h,
                        AppTextField(
                          controller: _bioController,
                          decoration: InputDecoration(
                            hintText: context.l10n.bioBackgroundHint,
                            fillColor: context.colors.onPrimary,
                          ),
                          style: TextStyle(color: context.colors.onSurface),
                          maxLines: 4,
                          minLines: 4,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            final requiredError = Validators.required(
                              context,
                              value,
                              fieldName: context.l10n.bioBackgroundLabel,
                            );
                            if (requiredError != null) return requiredError;

                            if (value!.trim().length < 15) {
                              return context.l10n.bioMinCharacters;
                            }
                            return null;
                          },
                        ),

                        const Spacer(),
                        AppSpacing.xxl.h,

                        // 6. Next Action Button
                        ValueListenableBuilder<bool>(
                          valueListenable: _isLoadingNotifier,
                          builder: (context, isLoading, _) {
                            final authState = sl.isRegistered<AuthBloc>()
                                ? sl<AuthBloc>().state
                                : null;
                            final isResubmit = authState?.isRejected == true &&
                                authState?.hasRejectedDocuments == false;

                            return AppButton(
                              text: isResubmit
                                  ? 'Resubmit Profile for Review'
                                  : context.l10n.next,
                              isLoading: isLoading,
                              trailing: Icon(
                                isResubmit
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.arrow_forward_rounded,
                                size: AppSizes.iconMd,
                                color: context.colors.onPrimary,
                              ),
                              onPressed: _handleNext,
                            );
                          },
                        ),
                        AppSpacing.xxl.h,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          },
        ),
      ),
    );
  }
}

/// Custom painter that draws a thick, bold circular dashed border.
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  const _DashedCirclePainter({
    required this.color,
    this.strokeWidth = 4.5,
    this.dashLength = 10.5,
    this.gapLength = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * math.pi * radius;

    final dashCount = (circumference / (dashLength + gapLength)).floor();
    if (dashCount == 0) return;

    final totalDashLength = dashCount * dashLength;
    final totalGapLength = circumference - totalDashLength;
    final actualGap = totalGapLength / dashCount;

    final dashAngle = dashLength / radius;
    final gapAngle = actualGap / radius;

    // Center one dash segment directly at 12 o'clock
    double currentAngle = -math.pi / 2 - (dashAngle / 2);
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        dashAngle,
        false,
        paint,
      );
      currentAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}
