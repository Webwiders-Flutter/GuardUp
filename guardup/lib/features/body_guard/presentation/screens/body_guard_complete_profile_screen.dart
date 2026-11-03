import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/string.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_dropdown.dart';
import '/shared/widgets/inputs/app_media_picker_sheet.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/misc/app_input_label.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/selection/selection.dart';
import '../../data/enum/guard_service.enum.dart';

/// Screen for bodyguard profile setup / entering professional details.
///
/// Follows GuardUp Development Rules & Architectural Guidelines:
/// - State Management: [ValueNotifier] & [ValueListenableBuilder] over `setState()`.
/// - Localization: all user-facing strings accessed via [context.l10n].
/// - Theming & Tokens: strict adherence to [context.colors], [context.textTheme], and [AppSpacing].
/// - Form Layout: [LayoutBuilder] + [ConstrainedBox] + [IntrinsicHeight] + [Spacer] onboarding pattern.
class BodyGuardCompleteProfileScreen extends StatefulWidget {
  const BodyGuardCompleteProfileScreen({super.key});

  @override
  State<BodyGuardCompleteProfileScreen> createState() =>
      _BodyGuardCompleteProfileScreenState();
}

class _BodyGuardCompleteProfileScreenState
    extends State<BodyGuardCompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _hourlyRateController;
  late final TextEditingController _bioController;

  late final SelectionController<GuardService> _serviceDropdownController;

  /// Isolated state for selected services via [ValueNotifier] (Rule 1: no `setState`).

  /// Isolated avatar profile picture notifier matching edit profile UI.
  final ValueNotifier<XFile?> _profileImageNotifier = ValueNotifier<XFile?>(
    null,
  );

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: 'Vikram Singh');
    _hourlyRateController = TextEditingController(text: '60');
    _bioController = TextEditingController();
    _serviceDropdownController = SelectionController<GuardService>.multi(
      initial: [
        GuardService.vipCloseProtection,
        GuardService.armedEscort,
        GuardService.tacticalDriver,
      ],
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _hourlyRateController.dispose();
    _bioController.dispose();
    _serviceDropdownController.dispose();
    _profileImageNotifier.dispose();
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

  void _handleRemoveService(GuardService service) {
    _serviceDropdownController.toggle(service);
  }

  void _handleNext() {
    // if (!(_formKey.currentState?.validate() ?? false)) return;

    // Navigate to next onboarding step (documents upload)
    context.push(AppRoutes.bodyguardUploadDocuments);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar.transparent(
        title: context.l10n.profileSetupTitle,
        alignTitle: .center,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: context.horizontalEdgeInsets,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSpacing.xxl.h,

                        // 1. Profile Picture (copied directly from Edit Profile UI)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Circular Avatar with Gold Ring Border
                                  QuickContainer(
                                    w: 96,
                                    h: 96,
                                    shape: QuickContainerShape.circle,
                                    border: Border.all(
                                      color: context.colors.primary,
                                      width: 2.5,
                                    ),
                                    p: 2,
                                    child: ValueListenableBuilder<XFile?>(
                                      valueListenable: _profileImageNotifier,
                                      builder: (context, profileImage, _) {
                                        return ClipOval(
                                          child: profileImage != null
                                              ? AppImage.xFile(
                                                  xFile: profileImage,
                                                  width: 92,
                                                  height: 92,
                                                  fit: BoxFit.cover,
                                                  onTap: _handleChangePhoto,
                                                )
                                              : ValueListenableBuilder<
                                                  TextEditingValue
                                                >(
                                                  valueListenable:
                                                      _fullNameController,
                                                  builder: (context, textVal, _) {
                                                    return QuickContainer(
                                                      color: context
                                                          .colors
                                                          .surfaceContainer,
                                                      alignment:
                                                          Alignment.center,
                                                      onTap: _handleChangePhoto,
                                                      child: Text(
                                                        textVal.text
                                                            .getInitials(),
                                                        style: context
                                                            .textTheme
                                                            .headlineMedium
                                                            ?.bold()
                                                            .colour(
                                                              context
                                                                  .colors
                                                                  .primary,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                        );
                                      },
                                    ),
                                  ),

                                  // Camera Icon Badge
                                  Positioned(
                                    right: 0,
                                    bottom: 2,
                                    child: GestureDetector(
                                      onTap: _handleChangePhoto,
                                      child: QuickContainer(
                                        w: 28,
                                        h: 28,
                                        shape: QuickContainerShape.circle,
                                        color: context.colors.primary,
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.camera_alt,
                                          size: 15,
                                          color: context.colors.surface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.sm.h,
                              Text(
                                context.l10n.uploadPortraitGuidance,
                                style: context.textTheme.labelMedium?.colour(
                                  context.colors.onSurfaceVariant,
                                ),
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
                            hintText: 'Enter Full Name',
                            fillColor: context.colors.onPrimary,
                          ),
                          style: TextStyle(color: context.colors.onSurface),
                          textInputAction: TextInputAction.next,
                        ),
                        AppSpacing.xxl.h,

                        // 3. Hourly Rate Field
                        AppFieldLabel(text: context.l10n.hourlyRateLabel),
                        AppSpacing.sm.h,
                        AppTextField(
                          controller: _hourlyRateController,
                          decoration: InputDecoration(
                            hintText: "Enter Hourly Rate",
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
                            fillColor: context.colors.onPrimary,
                          ),
                          style: TextStyle(color: context.colors.onSurface),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.required(context, value),
                        ),
                        AppSpacing.xxl.h,

                        // 4. Services Offered Section (Isolated rebuild with ValueListenableBuilder)
                        ValueListenableBuilder(
                          valueListenable: _serviceDropdownController,
                          builder: (context, selectedServices, _) {
                            return Column(
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
                                  AppSpacing.sm.h,
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: selectedServices.map((service) {
                                      return AppRemovableChip(
                                        text: service.label(context.l10n),
                                        onRemove: () =>
                                            _handleRemoveService(service),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                AppSpacing.sm.h,
                                AppDropdown<GuardService>(
                                  controller: _serviceDropdownController,
                                  hintText: context.l10n.selectService,
                                  closeOnSelect: true,
                                  target: (fieldKey) {
                                    return AppTextField(
                                      key: fieldKey,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        hintText: context.l10n.selectService,
                                        suffixIcon: Icon(
                                          Icons.expand_more,
                                          color: context.colors.outline,
                                        ),
                                        fillColor: context.colors.onPrimary,
                                      ),
                                      style: TextStyle(
                                        color: context.colors.onSurface,
                                      ),
                                    );
                                  },
                                  items: GuardService.values
                                      .where(
                                        (s) => !selectedServices.contains(s),
                                      )
                                      .map(
                                        (e) => DropdownItem<GuardService>(
                                          id: e,
                                          data: e.label(context.l10n),
                                          icon: Icon(
                                            e.icon,
                                            size: 18,
                                            color: context.colors.primary,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
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
                        ),

                        const Spacer(),
                        AppSpacing.xxl.h,

                        // 6. Next Action Button
                        AppButton(
                          text: context.l10n.next,
                          trailing: Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: context.colors.onPrimary,
                          ),
                          size: ButtonSize.large,
                          onPressed: _handleNext,
                        ),
                        AppSpacing.xxl.h,
                      ],
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
