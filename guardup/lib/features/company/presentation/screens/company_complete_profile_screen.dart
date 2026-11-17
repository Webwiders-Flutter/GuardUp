import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_sizes.dart';

import '../../../../core/di/injection_container.dart';
import '../../../auth/auth.dart';
import '/app/routes/app_routes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_dropdown.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/selection/selection.controller.dart';
import '../../data/enum/business_type.enum.dart';

/// Screen for company registration / entering company details.
class CompanyCompleteProfileScreen extends StatefulWidget {
  static const route = '/company-profile';

  const CompanyCompleteProfileScreen({super.key});

  @override
  State<CompanyCompleteProfileScreen> createState() =>
      _CompanyCompleteProfileScreenState();
}

class _CompanyCompleteProfileScreenState
    extends State<CompanyCompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _companyPhoneCode = '+91';
  final _businessTypeController = SelectionController<BusinessType>.single(
    allowDeselect: false,
  );
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final currentUserId = sl.isRegistered<AuthRepository>()
        ? sl<AuthRepository>().currentUserId
        : null;
    if (currentUserId == null || !sl.isRegistered<UserRepository>()) return;

    try {
      final data = await sl<UserRepository>().getUserData(currentUserId);
      if (data != null && mounted) {
        // 1. Company Name
        final dbCompanyName = data['company_name'] as String?;
        if (dbCompanyName != null && dbCompanyName.isNotEmpty) {
          _companyNameController.text = dbCompanyName;
        }

        // 2. Business Email (Never prefill personal email here)
        final dbBusinessEmail = data['business_email'] as String?;
        if (dbBusinessEmail != null && dbBusinessEmail.isNotEmpty) {
          _emailController.text = dbBusinessEmail;
        }

        // 3. Company Phone Number & Code (Dedicated business phone, not personal auth phone)
        final dbCompanyPhone = data['company_phone_number'] as String?;
        final dbCompanyPhoneCode = data['company_phone_code'] as String?;
        if (dbCompanyPhone != null && dbCompanyPhone.isNotEmpty) {
          _phoneController.text = dbCompanyPhone;
        }
        if (dbCompanyPhoneCode != null && dbCompanyPhoneCode.isNotEmpty) {
          _companyPhoneCode = dbCompanyPhoneCode;
        }

        // 4. Company Type
        final dbCompanyType = data['company_type'] as String?;
        if (dbCompanyType != null && dbCompanyType.isNotEmpty) {
          final type = BusinessType.fromApiValue(dbCompanyType);
          _businessTypeController.select(type);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessTypeController.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_businessTypeController.selectedItem == null) {
      AppSnackbar.error(context.l10n.selectCompanyType);
      return;
    }
    if (_isLoadingNotifier.value) return;

    _isLoadingNotifier.value = true;

    final currentUserId = sl.isRegistered<AuthRepository>()
        ? sl<AuthRepository>().currentUserId
        : null;

    if (currentUserId != null && sl.isRegistered<UserRepository>()) {
      try {
        final compName = _companyNameController.text.trim();
        await sl<UserRepository>().updateProfileFields(
          userId: currentUserId,
          data: {
            'company_name': compName,
            'name': compName,
            'business_email': _emailController.text.trim(),
            'company_phone_number': _phoneController.text.trim(),
            'company_phone_code': _companyPhoneCode,
            'company_type': _businessTypeController.selectedItem?.apiValue,
          },
        );
      } catch (_) {}
    }

    if (mounted) {
      _isLoadingNotifier.value = false;
      context.go(AppRoutes.uploadDocuments);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(
        showBackIcon: false,
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
                context.go(AppRoutes.login);
              }
            },
          ),
          AppSpacing.xs.w,
        ],
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
                        AppSpacing.huge.h,

                        // GuardUp Logo (Centered)
                        Center(
                          child: AppImage.asset(
                            assetPath: Assets.images.appLogo.path,
                            height: 32.wPercent(context),
                            fit: BoxFit.contain,
                          ),
                        ),
                        AppSpacing.massive.h,

                        // 1. Heading: Company Details
                        Text(
                          context.l10n.companyDetailsTitle,
                          style: context.textTheme.headlineLarge?.bold(),
                        ),
                        AppSpacing.xs.h,

                        // 2. Subtitle
                        Text(
                          context.l10n.companyDetailsSubtitle,
                          style: context.textTheme.bodyMedium?.colour(
                            context.colors.onSurfaceVariant,
                          ),
                        ),
                        AppSpacing.xxl.h,

                        // 3. Company Name Field
                        AppTextField(
                          controller: _companyNameController,
                          decoration: InputDecoration(
                            hintText: context.l10n.enterCompanyName,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.required(context, value),
                        ),
                        AppSpacing.lg.h,

                        // 4. Business Email Field
                        AppTextField.email(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: context.l10n.businessEmail,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.email(context, value),
                        ),
                        AppSpacing.lg.h,

                        // 5. Company Phone Number Field
                        AppTextField.phone(
                          controller: _phoneController,
                          phoneCountryCode: _companyPhoneCode,
                          onCountryCodeChanged: (code) {
                            _companyPhoneCode = code;
                          },
                          decoration: InputDecoration(
                            hintText: context.l10n.phoneNumber,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.phone(context, value),
                        ),
                        AppSpacing.lg.h,

                        // 6. Company Type Dropdown
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
                                    color: context.colors.primary,
                                  ),
                                ),
                              )
                              .toList(),
                          validator: (_) =>
                              _businessTypeController.selectedItem == null
                              ? context.l10n.selectCompanyType
                              : null,
                        ),

                        AppSpacing.huge.h,

                        // 7. Next Button pinned to bottom
                        ValueListenableBuilder<bool>(
                          valueListenable: _isLoadingNotifier,
                          builder: (context, isLoading, _) {
                            return AppButton(
                              text: context.l10n.next,
                              isLoading: isLoading,
                              onPressed: _handleNext,
                            );
                          },
                        ),
                        const Spacer(),
                        AppSpacing.xl.h,
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
