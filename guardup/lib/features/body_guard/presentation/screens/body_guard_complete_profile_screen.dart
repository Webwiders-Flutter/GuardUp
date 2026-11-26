import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/api_error.extension.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/features/auth/auth.dart';
import '/features/body_guard/presentation/screens/body_guard_upload_documents_screen.dart';
import '/features/services/services.dart';
import '/shared/models/record_owner.model.dart';
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
import '../../bloc/guard_profile/guard_profile_bloc.dart';
import '../../data/model/body_guard.model.dart';
import '../../data/model/bodyguard_profile_request.model.dart';

/// Screen for bodyguard profile setup / entering professional details.
///
/// Uses [GuardProfileBloc] for loading active services and existing profile
/// details, tracking avatar/service selections, and submitting changes.
class BodyGuardCompleteProfileScreen extends StatelessWidget {
  static const route = '/bodyguard-profile';

  final BodyGuardModel? bodyguard;

  const BodyGuardCompleteProfileScreen({super.key, this.bodyguard});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isGuard = authState.isGuard;
    final RecordOwner owner = isGuard
        ? AccountOwner(authState.user?.id ?? '')
        : ManagedBodyguardOwner(bodyguard?.id ?? '');

    return BlocProvider(
      create: (_) => sl<GuardProfileBloc>(
        param1: owner,
        param2: bodyguard,
      )..add(const GuardProfileStarted()),
      child: _BodyGuardCompleteProfileView(
        bodyguard: bodyguard,
        isGuard: isGuard,
      ),
    );
  }
}

class _BodyGuardCompleteProfileView extends StatefulWidget {
  final BodyGuardModel? bodyguard;
  final bool isGuard;

  const _BodyGuardCompleteProfileView({
    required this.bodyguard,
    required this.isGuard,
  });

  @override
  State<_BodyGuardCompleteProfileView> createState() =>
      _BodyGuardCompleteProfileViewState();
}

class _BodyGuardCompleteProfileViewState
    extends State<_BodyGuardCompleteProfileView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _hourlyRateController;
  late final TextEditingController _bioController;
  late final SelectionController<String> _serviceDropdownController;

  @override
  void initState() {
    super.initState();
    String initialName = '';
    String initialRate = '';
    String initialBio = '';

    if (widget.isGuard) {
      final authUser = context.read<AuthBloc>().state.user;
      if (authUser?.name != null &&
          authUser!.name.isNotEmpty &&
          authUser.name != 'User' &&
          authUser.name != 'New User') {
        initialName = authUser.name;
      }
      final guard = authUser?.bodyguard;
      if (guard != null) {
        if (guard.hourlyRate > 0) {
          initialRate = guard.hourlyRate.toInt().toString();
        }
        initialBio = guard.bio;
      }
    } else if (widget.bodyguard != null) {
      initialName = widget.bodyguard!.name;
      if (widget.bodyguard!.hourlyRate > 0) {
        initialRate = widget.bodyguard!.hourlyRate.toInt().toString();
      }
      initialBio = widget.bodyguard!.bio;
    }

    _fullNameController = TextEditingController(text: initialName);
    _hourlyRateController = TextEditingController(text: initialRate);
    _bioController = TextEditingController(text: initialBio);

    _serviceDropdownController = SelectionController<String>.multi(
      initial: const [],
      onChanged: (selected) {
        if (!mounted) return;
        context.read<GuardProfileBloc>().add(
          GuardProfileServicesChanged(List<String>.from(selected)),
        );
      },
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _hourlyRateController.dispose();
    _bioController.dispose();
    _serviceDropdownController.dispose();
    super.dispose();
  }

  String? _managedRejectionReason(BodyGuardModel? profile) {
    final reason = profile?.rejectionReason?.trim();
    return profile?.status == UserStatus.rejected &&
            reason != null &&
            reason.isNotEmpty
        ? reason
        : null;
  }

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
      context.read<GuardProfileBloc>().add(GuardProfileAvatarPicked(pickedFile));
    }
  }

  void _handleRemoveService(String serviceId, List<String> currentSelection) {
    final nextSelection = List<String>.from(currentSelection)..remove(serviceId);
    _serviceDropdownController.deselect(serviceId);
    context.read<GuardProfileBloc>().add(
      GuardProfileServicesChanged(nextSelection),
    );
  }

  void _handleNext(GuardProfileState state) {
    if (state.submitStatus.isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (state.pickedAvatar == null &&
        (state.existingAvatarUrl == null || state.existingAvatarUrl!.isEmpty)) {
      AppSnackbar.error(context.l10n.pleaseUploadProfilePhoto);
      return;
    }

    if (state.selectedServiceIds.isEmpty) {
      AppSnackbar.error(context.l10n.pleaseSelectAtLeastOneService);
      return;
    }

    final authState = context.read<AuthBloc>().state;
    final resubmitForReview =
        widget.isGuard &&
        authState.isRejected &&
        !authState.hasRejectedDocuments;

    context.read<GuardProfileBloc>().add(
      GuardProfileSubmitted(
        BodyguardProfileRequest(
          name: _fullNameController.text.trim(),
          hourlyRate: double.tryParse(_hourlyRateController.text.trim()) ?? 0.0,
          bio: _bioController.text.trim(),
        ),
        resubmitForReview: resubmitForReview,
      ),
    );
  }

  Future<void> _onProfileSubmittedSuccess(GuardProfileState state) async {
    if (!mounted) return;
    if (widget.isGuard) {
      if (state.resubmittedForReview) {
        AppSnackbar.success(
          'Profile updated successfully! Your application has been resubmitted for review.',
        );
        context.go(AdminApprovalScreen.route);
      } else {
        // The upload screen identifies a self-registered guard by the
        // session, so no bodyguard needs to be passed along.
        context.go(BodyGuardUploadDocumentsScreen.route);
      }
      return;
    }

    // Documents screen pops `true` once submitted; then close this screen
    // too so the company lands back on its bodyguard list.
    final submitted = await context.push<bool>(
      BodyGuardUploadDocumentsScreen.route,
      extra: state.profile,
    );
    if (submitted == true && mounted) {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GuardProfileBloc, GuardProfileState>(
      listenWhen: (prev, curr) =>
          prev.loadStatus != curr.loadStatus ||
          prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.loadStatus.isSuccess) {
          final loadedName = state.resolvedInitialName;
          if (_fullNameController.text.isEmpty && loadedName.isNotEmpty) {
            _fullNameController.text = loadedName;
          }
          final rate = state.profile?.hourlyRate ?? 0;
          if (_hourlyRateController.text.isEmpty && rate > 0) {
            _hourlyRateController.text = rate.toInt().toString();
          }
          final bio = state.profile?.bio ?? '';
          if (_bioController.text.isEmpty && bio.isNotEmpty) {
            _bioController.text = bio;
          }
          _serviceDropdownController.setSelection(state.selectedServiceIds);
        }

        if (state.submitStatus.isSuccess) {
          _onProfileSubmittedSuccess(state);
        } else if (state.submitStatus.isFailure) {
          AppSnackbar.error(
            context.apiErrorText(
              state.submitStatus.errorOrNull,
              fallback: widget.isGuard
                  ? 'Failed to save profile details. Please try again.'
                  : 'Failed to save bodyguard details. Please try again.',
            ),
          );
        }
      },
      builder: (context, state) {
        final authState = context.watch<AuthBloc>().state;
        final isLoading = state.submitStatus.isLoading;
        final activeServices = state.activeServices
            .where((s) => s.isActive)
            .toList();
        final selectedServices = state.selectedServiceIds;
        final pickedAvatar = state.pickedAvatar;
        final networkUrl = state.existingAvatarUrl;

        final managedReason = _managedRejectionReason(
          state.profile ?? widget.bodyguard,
        );
        final profileReason = widget.isGuard
            ? (authState.isRejected ? authState.profileRejectionReason : null)
            : managedReason;
        final isResubmit =
            widget.isGuard &&
            authState.isRejected &&
            !authState.hasRejectedDocuments;

        return Scaffold(
          appBar: AppAppBar.transparent(
            title: widget.isGuard
                ? context.l10n.profileSetupTitle
                : (widget.bodyguard != null
                      ? 'Edit Bodyguard'
                      : context.l10n.addBodyguard),
            fontSize: 14,
            alignTitle: authState.isAuthenticated ? .right : .center,
            actions: widget.isGuard
                ? [
                    IconButton(
                      tooltip: context.l10n.logOut,
                      icon: Icon(
                        Icons.logout_rounded,
                        color: context.colors.error,
                        size: AppSizes.iconSmd,
                      ),
                      onPressed: () async {
                        final result = await AppPopup.showLogoutConfirmation(
                          context,
                        );
                        if (result?.action == PopupAction.confirm &&
                            context.mounted) {
                          context.read<AuthBloc>().add(
                            const AuthSignOutRequested(),
                          );
                          context.go(LoginScreen.route);
                        }
                      },
                    ),
                    AppSpacing.xs.w,
                  ]
                : null,
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return RefreshIndicator(
                  color: context.colors.primary,
                  backgroundColor: context.colors.surface,
                  onRefresh: () async {
                    context.read<GuardProfileBloc>().add(
                      const GuardProfileServicesRefreshed(),
                    );
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: context.horizontalEdgeInsets,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSpacing.lg.h,

                              // Profile Rejection Reason Banner
                              if (profileReason != null &&
                                  profileReason.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: AppSpacing.lg,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: AppSpacing.md.allPadding,
                                    decoration: BoxDecoration(
                                      color: context.colors.error.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                      border: Border.all(
                                        color: context.colors.error.withValues(
                                          alpha: 0.4,
                                        ),
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
                                                    .textTheme
                                                    .labelMedium
                                                    ?.bold()
                                                    .colour(
                                                      context.colors.error,
                                                    ),
                                              ),
                                              AppSpacing.xxs.h,
                                              Text(
                                                profileReason,
                                                style: context
                                                    .textTheme
                                                    .bodySmall
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
                                                  color:
                                                      context.colors.onPrimary,
                                                ),
                                                child: pickedAvatar != null
                                                    ? ClipOval(
                                                        child: AppImage.xFile(
                                                          xFile: pickedAvatar,
                                                          width: 108,
                                                          height: 108,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      )
                                                    : (networkUrl != null &&
                                                          networkUrl
                                                              .isNotEmpty)
                                                    ? ClipOval(
                                                        child: AppImage.network(
                                                          imageUrl: networkUrl,
                                                          width: 108,
                                                          height: 108,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      )
                                                    : Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .person_outline_rounded,
                                                            size: 38,
                                                            color: context
                                                                .colors
                                                                .outline,
                                                          ),
                                                          6.h,
                                                          Text(
                                                            context
                                                                .l10n
                                                                .addPhoto,
                                                            style: context
                                                                .textTheme
                                                                .labelSmall
                                                                ?.regular()
                                                                .copyWith(
                                                                  fontSize:
                                                                      10.0,
                                                                  letterSpacing:
                                                                      0.2,
                                                                )
                                                                .colour(
                                                                  context
                                                                      .colors
                                                                      .primary,
                                                                ),
                                                          ),
                                                        ],
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
                                                color: context
                                                    .colors
                                                    .primaryContainer,
                                                border: Border.all(
                                                  color: context.colors.surface,
                                                  width: 3.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
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
                                style: TextStyle(
                                  color: context.colors.onSurface,
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (value) =>
                                    Validators.required(context, value),
                              ),
                              AppSpacing.xxl.h,

                              // 3. Hourly Rate Field
                              AppFieldLabel(
                                text: context.l10n.hourlyRateLabel,
                              ),
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
                                style: TextStyle(
                                  color: context.colors.onSurface,
                                ),
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  final requiredError = Validators.required(
                                    context,
                                    value,
                                    fieldName: context.l10n.hourlyRateLabel,
                                  );
                                  if (requiredError != null) {
                                    return requiredError;
                                  }

                                  final rate = double.tryParse(value!.trim());
                                  if (rate == null || rate <= 0) {
                                    return context
                                        .l10n
                                        .hourlyRateGreaterThanZero;
                                  }
                                  return null;
                                },
                              ),
                              AppSpacing.xxl.h,

                              // 4. Services Offered Section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      AppFieldLabel(
                                        text: context.l10n.servicesOfferedLabel,
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
                                      children: selectedServices.map((
                                        serviceId,
                                      ) {
                                        final serviceModel = activeServices
                                            .firstWhere(
                                              (s) => s.id == serviceId,
                                              orElse: () => ServiceModel(
                                                id: serviceId,
                                                name: 'Service',
                                              ),
                                            );
                                        return AppRemovableChip(
                                          text: serviceModel.name,
                                          onRemove: () => _handleRemoveService(
                                            serviceId,
                                            selectedServices,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  AppSpacing.lg.h,
                                  AppDropdown<String>(
                                    controller: _serviceDropdownController,
                                    hintText: context.l10n.selectService,
                                    items: activeServices
                                        .map(
                                          (e) => DropdownItem<String>(
                                            id: e.id,
                                            data: e.name,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                              AppSpacing.xxl.h,

                              // 5. Bio & Background Field
                              AppFieldLabel(
                                text: context.l10n.bioBackgroundLabel,
                              ),
                              AppSpacing.sm.h,
                              AppTextField(
                                controller: _bioController,
                                decoration: InputDecoration(
                                  hintText: context.l10n.bioBackgroundHint,
                                  fillColor: context.colors.onPrimary,
                                ),
                                style: TextStyle(
                                  color: context.colors.onSurface,
                                ),
                                maxLines: 4,
                                minLines: 4,
                                textInputAction: TextInputAction.done,
                                validator: (value) {
                                  final requiredError = Validators.required(
                                    context,
                                    value,
                                    fieldName: context.l10n.bioBackgroundLabel,
                                  );
                                  if (requiredError != null) {
                                    return requiredError;
                                  }

                                  if (value!.trim().length < 15) {
                                    return context.l10n.bioMinCharacters;
                                  }
                                  return null;
                                },
                              ),

                              const Spacer(),
                              AppSpacing.xxl.h,

                              // 6. Next Action Button
                              AppButton(
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
                                onPressed: () => _handleNext(state),
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
      },
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
