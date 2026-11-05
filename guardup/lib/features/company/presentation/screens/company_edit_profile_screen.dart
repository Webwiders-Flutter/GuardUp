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
import '/core/extensions/string.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_dropdown.dart';
import '/shared/widgets/inputs/app_media_picker_sheet.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '/shared/widgets/selection/selection.controller.dart';
import '../../data/enum/business_type.enum.dart';

/// Screen allowing a company to view and edit its profile details.
class CompanyEditProfileScreen extends StatefulWidget {
  const CompanyEditProfileScreen({super.key});

  @override
  State<CompanyEditProfileScreen> createState() =>
      _CompanyEditProfileScreenState();
}

class _CompanyEditProfileScreenState extends State<CompanyEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController(
    text: 'SecurePro Security Ltd.',
  );
  final _emailController = TextEditingController(text: 'contact@securepro.com');
  final _phoneController = TextEditingController(text: '9876543210');
  final _businessTypeController = SelectionController<BusinessType>.single(
    initial: BusinessType.pvtLtd,
    allowDeselect: false,
  );
  final ValueNotifier<XFile?> _logoImageNotifier = ValueNotifier<XFile?>(null);

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessTypeController.dispose();
    _logoImageNotifier.dispose();
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
      _logoImageNotifier.value = pickedFile;
    }
  }

  void _handleSave() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(title: context.l10n.editProfileTitle),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: context.horizontalEdgeInsets,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSpacing.xl.h,

                    // 1. Avatar Card with Monogram / Logo, Camera Badge & Company Name
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
                                  valueListenable: _logoImageNotifier,
                                  builder: (context, logoImage, _) {
                                    return ClipOval(
                                      child: logoImage != null
                                          ? AppImage.xFile(
                                              xFile: logoImage,
                                              width:
                                                  AppSizes.avatarColossal - 4,
                                              height:
                                                  AppSizes.avatarColossal - 4,
                                              fit: BoxFit.cover,
                                              onTap: _handleChangePhoto,
                                            )
                                          : ValueListenableBuilder<
                                              TextEditingValue
                                            >(
                                              valueListenable:
                                                  _companyNameController,
                                              builder: (context, textVal, _) {
                                                return QuickContainer(
                                                  color: context
                                                      .colors
                                                      .surfaceContainer,
                                                  alignment: Alignment.center,
                                                  onTap: _handleChangePhoto,
                                                  child: Text(
                                                    textVal.text.getInitials(),
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

                          // Company Name with Verified Checkmark Icon
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _companyNameController,
                                builder: (context, textVal, _) {
                                  final name = textVal.text.trim();
                                  return Text(
                                    name.isEmpty
                                        ? 'SecurePro Security Ltd.'
                                        : name,
                                    style: context.textTheme.titleMedium
                                        ?.bold(),
                                  );
                                },
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

                    // 2. Company Information Section Heading
                    Row(
                      children: [
                        Icon(
                          Icons.business_center_outlined,
                          color: context.colors.primary,
                          size: AppSizes.iconMd,
                        ),
                        AppSpacing.xs.w,
                        Text(
                          context.l10n.companyInformation,
                          style: context.textTheme.titleMedium?.bold(),
                        ),
                      ],
                    ),
                    AppSpacing.sm.h,

                    // 3. Company Information Form Fields Card
                    WrapperCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Company Name Field
                          AppTextField(
                            controller: _companyNameController,
                            decoration: InputDecoration(
                              hintText: context.l10n.companyName,
                            ),
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                Validators.required(context, value),
                          ),
                          AppSpacing.md.h,

                          // Email Address Field
                          AppTextField.email(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: context.l10n.emailAddress,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                Validators.email(context, value),
                          ),
                          AppSpacing.md.h,

                          // Phone Number Field
                          AppTextField.phone(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              hintText: context.l10n.phoneNumber,
                            ),
                            textInputAction: TextInputAction.done,
                            validator: (value) =>
                                Validators.phone(context, value),
                          ),
                          AppSpacing.md.h,

                          // Company Type Dropdown
                          AppDropdown<BusinessType>(
                            controller: _businessTypeController,
                            hintText: context.l10n.companyType,
                            items: BusinessType.values
                                .map(
                                  (e) => DropdownItem<BusinessType>(
                                    id: e,
                                    data: e.label(context.l10n),
                                    icon: Icon(
                                      e.icon,
                                      size: AppSizes.iconSmd,
                                      color: e.color(context),
                                    ),
                                  ),
                                )
                                .toList(),
                            validator: (_) =>
                                _businessTypeController.selectedItem == null
                                ? context.l10n.selectCompanyType
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    AppSpacing.xl.h,

                    // 4. Save Changes Primary Button
                    AppButton(
                      text: context.l10n.saveChanges,
                      size: ButtonSize.large,
                      onPressed: _handleSave,
                    ),
                    AppSpacing.md.h,

                    // 5. Cancel Secondary Button
                    AppButton(
                      text: context.l10n.cancel,
                      type: ButtonType.secondaryOff,
                      size: ButtonSize.large,
                      onPressed: () => context.pop(),
                    ),
                    AppSpacing.huge.h,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
