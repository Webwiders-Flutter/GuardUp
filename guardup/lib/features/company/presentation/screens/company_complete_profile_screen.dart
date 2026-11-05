import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_sizes.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_dropdown.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/selection/selection.controller.dart';
import '../../data/enum/business_type.enum.dart';

/// Screen for company registration / entering company details.
class CompanyCompleteProfileScreen extends StatefulWidget {
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
  final _businessTypeController = SelectionController<BusinessType>.single(
    allowDeselect: false,
  );

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }

  void _handleNext() {
    // Navigate directly to document upload stage
    context.push(AppRoutes.uploadDocuments);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

                        // 5. Phone Number Field
                        AppTextField.phone(
                          controller: _phoneController,
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

                        AppSpacing.huge.h,

                        // 7. Next Button pinned to bottom
                        AppButton(
                          text: context.l10n.next,
                          size: ButtonSize.large,
                          onPressed: _handleNext,
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
