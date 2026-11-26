import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/api_error.extension.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/features/auth/auth.dart';
import '/features/company/presentation/screens/company_upload_documents_screen.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_dropdown.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/selection/selection.controller.dart';
import '../../bloc/company_profile/company_profile_bloc.dart';
import '../../data/enum/business_type.enum.dart';
import '../../data/model/company_profile_request.model.dart';

/// Screen for company registration / entering company details.
class CompanyCompleteProfileScreen extends StatelessWidget {
  static const route = '/company-profile';

  const CompanyCompleteProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<CompanyProfileBloc>()..add(const CompanyProfileStarted()),
      child: const _CompanyCompleteProfileView(),
    );
  }
}

class _CompanyCompleteProfileView extends StatefulWidget {
  const _CompanyCompleteProfileView();

  @override
  State<_CompanyCompleteProfileView> createState() =>
      _CompanyCompleteProfileViewState();
}

class _CompanyCompleteProfileViewState
    extends State<_CompanyCompleteProfileView> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _companyPhoneCode = '+91';
  final _businessTypeController = SelectionController<BusinessType>.single(
    allowDeselect: false,
  );

  @override
  void initState() {
    super.initState();
    final company = context.read<AuthBloc>().state.user?.company;
    if (company != null) {
      if ((company.companyName ?? '').isNotEmpty) {
        _companyNameController.text = company.companyName!;
      }
      if ((company.businessEmail ?? '').isNotEmpty) {
        _emailController.text = company.businessEmail!;
      }
      if ((company.companyPhoneNumber ?? '').isNotEmpty) {
        _phoneController.text = company.companyPhoneNumber!;
      }
      if (company.companyPhoneCode.isNotEmpty) {
        _companyPhoneCode = company.companyPhoneCode;
      }
      if (company.companyType != null) {
        _businessTypeController.select(company.companyType!);
      }
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }

  void _handleNext(CompanyProfileState state) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_businessTypeController.selectedItem == null) {
      AppSnackbar.error(context.l10n.selectCompanyType);
      return;
    }
    if (state.submitStatus.isLoading) return;

    final authState = context.read<AuthBloc>().state;
    final resubmitForReview =
        authState.isRejected && !authState.hasRejectedDocuments;

    context.read<CompanyProfileBloc>().add(
      CompanyProfileSubmitted(
        CompanyProfileRequest(
          companyName: _companyNameController.text.trim(),
          businessEmail: _emailController.text.trim(),
          companyType: _businessTypeController.selectedItem,
          companyPhoneCode: _companyPhoneCode,
          companyPhoneNumber: _phoneController.text.trim(),
        ),
        resubmitForReview: resubmitForReview,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompanyProfileBloc, CompanyProfileState>(
      listenWhen: (prev, curr) =>
          prev.loadStatus != curr.loadStatus ||
          prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.loadStatus.isSuccess && state.company != null) {
          final company = state.company!;
          if (_companyNameController.text.isEmpty &&
              (company.companyName ?? '').isNotEmpty) {
            _companyNameController.text = company.companyName!;
          }
          if (_emailController.text.isEmpty &&
              (company.businessEmail ?? '').isNotEmpty) {
            _emailController.text = company.businessEmail!;
          }
          if (_phoneController.text.isEmpty &&
              (company.companyPhoneNumber ?? '').isNotEmpty) {
            _phoneController.text = company.companyPhoneNumber!;
          }
          if (company.companyPhoneCode.isNotEmpty) {
            setState(() => _companyPhoneCode = company.companyPhoneCode);
          }
          if (_businessTypeController.selectedItem == null &&
              company.companyType != null) {
            _businessTypeController.select(company.companyType!);
          }
        }

        if (state.submitStatus.isSuccess) {
          if (state.resubmittedForReview) {
            AppSnackbar.success(
              'Company details updated successfully! Your application has been resubmitted for review.',
            );
            context.go(AdminApprovalScreen.route);
          } else {
            context.go(UploadDocumentsScreen.route);
          }
        } else if (state.submitStatus.isFailure) {
          AppSnackbar.error(
            context.apiErrorText(
              state.submitStatus.errorOrNull,
              fallback: 'Failed to save company details. Please try again.',
            ),
          );
        }
      },
      builder: (context, state) {
        final authState = context.watch<AuthBloc>().state;
        final profileReason = authState.profileRejectionReason;
        final isResubmit =
            authState.isRejected && !authState.hasRejectedDocuments;
        final isLoading = state.submitStatus.isLoading;

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
                  if (result?.action == PopupAction.confirm &&
                      context.mounted) {
                    context.read<AuthBloc>().add(const AuthSignOutRequested());
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
                return SingleChildScrollView(
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
                            AppSpacing.lg.h,

                            // Profile Rejection Reason Banner
                            if (authState.isRejected &&
                                profileReason != null &&
                                profileReason.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.lg),
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
                                              'Company Profile Revision Requested',
                                              style: context
                                                  .textTheme
                                                  .labelMedium
                                                  ?.bold()
                                                  .colour(context.colors.error),
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
                            AppSpacing.sm.h,

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
                            AppButton(
                              text: isResubmit
                                  ? 'Resubmit Company Profile for Review'
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
      },
    );
  }
}
