import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/gen/assets.gen.dart';
import '../../data/enum/gender_type.enum.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_media_picker_sheet.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '/shared/widgets/selection/app_selectable_chip.dart';
import '/shared/widgets/selection/selection.controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'Michael Carter');
  final _emailController = TextEditingController(
    text: 'michael.carter@example.com',
  );
  final _phoneController = TextEditingController(text: '1234567890');
  final _genderController = SelectionController<GenderType>.single(
    initial: GenderType.male,
  );
  final ValueNotifier<XFile?> _profileImageNotifier = ValueNotifier<XFile?>(
    null,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _profileImageNotifier.dispose();
    super.dispose();
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
      _profileImageNotifier.value = pickedFile;
    }
  }

  void _handleSave() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(title: context.l10n.editProfileTitle),
      body: SingleChildScrollView(
        padding: context.horizontalEdgeInsets,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.xl.h,
              // 1. Avatar Card with Camera Badge & Name
              WrapperCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Circular Avatar with Gold Ring Border
                        QuickContainer(
                          w: AppSizes.avatarColossal,
                          h: AppSizes.avatarColossal,
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
                                        width: AppSizes.avatarColossal - 4,
                                        height: AppSizes.avatarColossal - 4,
                                        fit: BoxFit.cover,
                                        onTap: _handleChangePhoto,
                                      )
                                    : AppImage.asset(
                                        assetPath:
                                            Assets.images.profilePicture.path,
                                        width: AppSizes.avatarColossal - 4,
                                        height: AppSizes.avatarColossal - 4,
                                        fit: BoxFit.cover,
                                        onTap: _handleChangePhoto,
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
                              w: AppSizes.iconMdl,
                              h: AppSizes.iconMdl,
                              shape: QuickContainerShape.circle,
                              color: context.colors.primary,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.camera_alt,
                                size: AppSizes.iconSm,
                                color: context.colors.surface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.sm.h,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Michael Carter',
                          style: context.textTheme.titleMedium?.bold(),
                        ),
                        AppSpacing.xs.w,
                        Icon(
                          Icons.check_circle_rounded,
                          size: AppSizes.iconSm,
                          color: context.colors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSpacing.xl.h,

              // 2. Personal Information Section Heading
              Row(
                children: [
                  Icon(
                    Icons.badge_outlined,
                    color: context.colors.primary,
                    size: AppSizes.iconMd,
                  ),
                  AppSpacing.xs.w,
                  Text(
                    context.l10n.personalInformation,
                    style: context.textTheme.titleMedium?.bold(),
                  ),
                ],
              ),
              AppSpacing.sm.h,

              // 3. Personal Information Form Fields Card
              WrapperCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Full Name Field
                    AppTextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: context.l10n.fullName,
                      ),
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (value) => Validators.name(context, value),
                    ),
                    AppSpacing.md.h,

                    // Email Address Field
                    AppTextField.email(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: context.l10n.emailAddress,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) => Validators.email(context, value),
                    ),
                    AppSpacing.md.h,

                    // Phone Number Field
                    AppTextField.phone(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: context.l10n.phoneNumber,
                      ),
                      textInputAction: TextInputAction.done,
                      validator: (value) => Validators.phone(context, value),
                    ),
                    AppSpacing.lg.h,

                    // Gender Label
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.l10n.genderLabel,
                        style: context.textTheme.labelSmall
                            ?.bold()
                            .colour(context.colors.onSurfaceVariant)
                            .textSpacing(0.8),
                      ),
                    ),
                    AppSpacing.xs.h,

                    // Gender Selection Chips
                    Row(
                      children: GenderType.values.map((gender) {
                        return Expanded(
                          child: Padding(
                            padding: gender == GenderType.values.first
                                ? EdgeInsets.zero
                                : AppSpacing.sm.lPadding,
                            child: AppSelectableChip<GenderType>(
                              controller: _genderController,
                              value: gender,
                              label: gender.label(context.l10n),
                              icon: gender.icon,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              AppSpacing.xl.h,

              // 4. Save Changes Primary Button
              AppButton(text: context.l10n.saveChanges, onPressed: _handleSave),
              AppSpacing.md.h,

              // 5. Cancel Secondary Button
              AppButton(
                text: context.l10n.cancel,
                type: ButtonType.secondaryOff,

                onPressed: () => context.pop(),
              ),
              AppSpacing.xxl.h,
            ],
          ),
        ),
      ),
    );
  }
}
