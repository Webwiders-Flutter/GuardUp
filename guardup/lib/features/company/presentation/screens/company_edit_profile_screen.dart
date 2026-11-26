import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/api_error.extension.dart';
import '/core/extensions/company.extension.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/string.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_dropdown.dart';
import '/shared/widgets/inputs/app_media_picker_sheet.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '/shared/widgets/selection/selection.controller.dart';
import '../../bloc/company_profile/company_profile_bloc.dart';
import '../../data/enum/business_type.enum.dart';
import '../../data/model/company_profile_request.model.dart';

/// Screen allowing a company to view and edit its profile details.
class CompanyEditProfileScreen extends StatelessWidget {
  static const route = '/company-edit-profile';

  const CompanyEditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<CompanyProfileBloc>()..add(const CompanyProfileStarted()),
      child: const _CompanyEditProfileView(),
    );
  }
}

class _CompanyEditProfileView extends StatefulWidget {
  const _CompanyEditProfileView();

  @override
  State<_CompanyEditProfileView> createState() =>
      _CompanyEditProfileViewState();
}

class _CompanyEditProfileViewState extends State<_CompanyEditProfileView> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _businessTypeController = SelectionController<BusinessType>.single(
    initial: BusinessType.pvtLtd,
    allowDeselect: false,
  );

  String? _existingLogoUrl;
  String _phoneCode = '+91';

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    final user = state.user;
    final company = user?.company;

    _companyNameController.text = company?.displayName ?? user?.name ?? '';
    _emailController.text =
        company?.businessEmail ?? user?.email ?? state.email ?? '';
    _phoneController.text = company?.companyPhoneNumber?.isNotEmpty == true
        ? company!.companyPhoneNumber!
        : (user?.phoneNumber ?? state.phoneNumber ?? '');
    _phoneCode = company?.companyPhoneCode.isNotEmpty == true
        ? company!.companyPhoneCode
        : (user?.phoneCode ?? state.phoneCode ?? '+91');
    _experienceController.text = (company?.experienceYears ?? 0) > 0
        ? company!.experienceYears.toString()
        : '';
    _bioController.text = company?.bio ?? '';
    _existingLogoUrl = user?.profileImageUrl;

    if (company?.companyType != null) {
      _businessTypeController.select(company!.companyType!);
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _businessTypeController.dispose();
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
      context.read<CompanyProfileBloc>().add(
        CompanyProfileLogoPicked(pickedFile),
      );
    }
  }

  void _handleSave(CompanyProfileState state) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (state.submitStatus.isLoading) return;

    final companyName = _companyNameController.text.trim();
    final expYears = int.tryParse(_experienceController.text.trim()) ?? 0;

    context.read<CompanyProfileBloc>().add(
      CompanyProfileSubmitted(
        CompanyProfileRequest(
          companyName: companyName,
          businessEmail: _emailController.text.trim(),
          companyType:
              _businessTypeController.selectedItem ?? BusinessType.pvtLtd,
          companyPhoneCode: _phoneCode,
          companyPhoneNumber: _phoneController.text.trim(),
          experienceYears: expYears,
          bio: _bioController.text.trim(),
        ),
        refreshAccount: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompanyProfileBloc, CompanyProfileState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus.isSuccess) {
          AppSnackbar.success('Company profile updated successfully.');
          context.pop(true);
        } else if (state.submitStatus.isFailure) {
          AppSnackbar.error(
            context.apiErrorText(
              state.submitStatus.errorOrNull,
              fallback: 'Failed to update profile',
            ),
          );
        }
      },
      builder: (context, state) {
        final logoImage = state.pickedLogo;
        final isLoading = state.submitStatus.isLoading;

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
                  child: Form(
                    key: _formKey,
                    child: IntrinsicHeight(
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
                                      child: ClipOval(
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
                                                      _existingLogoUrl!
                                                          .isNotEmpty
                                                  ? AppImage.auto(
                                                      source: _existingLogoUrl!,
                                                      width:
                                                          AppSizes
                                                              .avatarColossal -
                                                          4,
                                                      height:
                                                          AppSizes
                                                              .avatarColossal -
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
                                                        final initials =
                                                            textVal
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

                                // Email Address Field (Read-only)
                                AppTextField.email(
                                  controller: _emailController,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    hintText: context.l10n.emailAddress,
                                    suffixIcon: Icon(
                                      Icons.lock_outline_rounded,
                                      size: AppSizes.iconSm,
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                  textInputAction: TextInputAction.next,
                                ),
                                AppSpacing.md.h,

                                // Phone Number Field (Read-only)
                                AppTextField.phone(
                                  controller: _phoneController,
                                  enabled: false,
                                  phoneCountryCode: _phoneCode,
                                  decoration: InputDecoration(
                                    hintText: context.l10n.phoneNumber,
                                    suffixIcon: Icon(
                                      Icons.lock_outline_rounded,
                                      size: AppSizes.iconSm,
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                  textInputAction: TextInputAction.next,
                                ),
                                AppSpacing.md.h,

                                // Experience (Years) Field
                                AppTextField(
                                  controller: _experienceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Experience (Years)',
                                    prefixIcon: Icon(
                                      Icons.work_history_outlined,
                                    ),
                                  ),
                                  textInputAction: TextInputAction.next,
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
                                      _businessTypeController.selectedItem ==
                                          null
                                      ? context.l10n.selectCompanyType
                                      : null,
                                ),
                                AppSpacing.md.h,

                                // Company Bio Field (multiline)
                                AppTextField.multiline(
                                  controller: _bioController,
                                  minLines: 3,
                                  maxLines: 5,
                                  decoration: const InputDecoration(
                                    hintText: 'Company Bio / Overview',
                                    alignLabelWithHint: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          AppSpacing.xl.h,

                          // 4. Save Changes Primary Button
                          AppButton(
                            text: context.l10n.saveChanges,
                            isLoading: isLoading,
                            onPressed: () => _handleSave(state),
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
                ),
              );
            },
          ),
        );
      },
    );
  }
}
