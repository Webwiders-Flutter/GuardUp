import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/api/storage_buckets.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/string.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/services/file_storage/file_storage.service.dart';
import '/core/services/file_storage/models/file_upload_request.model.dart';
import '/core/utils/validators.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/domain/repositories/auth_repository.dart';
import '/features/auth/domain/repositories/user_repository.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
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
  static const route = '/company-edit-profile';

  const CompanyEditProfileScreen({super.key});

  @override
  State<CompanyEditProfileScreen> createState() =>
      _CompanyEditProfileScreenState();
}

class _CompanyEditProfileScreenState extends State<CompanyEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessTypeController = SelectionController<BusinessType>.single(
    initial: BusinessType.pvtLtd,
    allowDeselect: false,
  );
  final ValueNotifier<XFile?> _logoImageNotifier = ValueNotifier<XFile?>(null);

  String? _existingLogoUrl;
  String _phoneCode = '+91';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final state = sl<AuthBloc>().state;
    _companyNameController.text = state.companyName;
    _emailController.text = state.businessEmail;
    _phoneController.text = state.companyPhoneNumber;
    _phoneCode = state.companyPhoneCode;
    _existingLogoUrl = state.avatarUrl;

    if (state.companyType.isNotEmpty) {
      _businessTypeController.select(BusinessType.fromApiValue(state.companyType));
    }
  }

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

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = context.l10n;
    final currentUserId = sl.isRegistered<AuthRepository>()
        ? sl<AuthRepository>().currentUserId
        : null;
    if (currentUserId == null || !sl.isRegistered<UserRepository>()) {
      context.pop();
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? logoUrl = _existingLogoUrl;
      if (_logoImageNotifier.value != null &&
          sl.isRegistered<FileStorageService>()) {
        final xFile = _logoImageNotifier.value!;
        final ext = xFile.name.split('.').last;
        final storagePath =
            '$currentUserId/logo_${DateTime.now().millisecondsSinceEpoch}.$ext';
        logoUrl = await sl<FileStorageService>().uploadSingleFile(
          FileUploadRequest.fromXFile(
            bucket: StorageBuckets.documents,
            path: storagePath,
            xFile: xFile,
            upsert: true,
          ),
        );
      }

      final companyName = _companyNameController.text.trim();
      final typeLabel = _businessTypeController.selectedItem != null
          ? _businessTypeController.selectedItem!.label(l10n)
          : 'Private Limited (Pvt Ltd)';

      await sl<UserRepository>().updateProfileFields(
        userId: currentUserId,
        data: {
          'company_name': companyName,
          'name': companyName,
          'business_email': _emailController.text.trim(),
          'company_phone_number': _phoneController.text.trim(),
          'company_phone_code': _phoneCode,
          'company_type': typeLabel,
          'profile_image_url': ?logoUrl,
        },
      );

      if (mounted) {
        AppSnackbar.success('Company profile updated successfully.');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error('Failed to update profile: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(
        title: context.l10n.editCompanyProfile,
        fontSize: 14,
      ),
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
                      borderColor: context.colors.surface.withValues(
                        alpha: 0.7,
                      ),
                      backgroundColor: context.colors.surface.withValues(
                        alpha: 0.7,
                      ),
                      padding: AppSpacing.xxl.allPadding,
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
                                          : (_existingLogoUrl != null &&
                                                  _existingLogoUrl!.isNotEmpty
                                              ? AppImage.auto(
                                                  source: _existingLogoUrl!,
                                                  width:
                                                      AppSizes.avatarColossal -
                                                      4,
                                                  height:
                                                      AppSizes.avatarColossal -
                                                      4,
                                                  fit: BoxFit.cover,
                                                  onTap: _handleChangePhoto,
                                                )
                                              : ValueListenableBuilder<
                                                  TextEditingValue
                                                >(
                                                  valueListenable:
                                                      _companyNameController,
                                                  builder: (context, textVal, _) {
                                                    final initials = textVal
                                                            .text
                                                            .isNotEmpty
                                                        ? textVal.text
                                                            .getInitials()
                                                        : 'CO';
                                                    return QuickContainer(
                                                      color: context
                                                          .colors
                                                          .surfaceContainer,
                                                      alignment:
                                                          Alignment.center,
                                                      onTap:
                                                          _handleChangePhoto,
                                                      child: Text(
                                                        initials,
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
                                                )),
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
                      borderColor: context.colors.surface,

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
                            phoneCountryCode: _phoneCode,
                            onCountryCodeChanged: (code) {
                              setState(() {
                                _phoneCode = code;
                              });
                            },
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
                      isLoading: _isLoading,
                      onPressed: _handleSave,
                    ),
                    AppSpacing.md.h,

                    // 5. Cancel Secondary Button
                    AppButton(
                      text: context.l10n.cancel,
                      type: ButtonType.secondaryOff,

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
