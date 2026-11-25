import '/features/company/data/enum/business_type.enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_state.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '/features/company/presentation/screens/company_edit_profile_screen.dart';

/// Screen presenting read-only company details.
class CompanyInformationScreen extends StatelessWidget {
  static const route = '/company-information';

  final String? companyName;
  final String? email;
  final String? phone;
  final String? companyType;

  const CompanyInformationScreen({
    super.key,
    this.companyName,
    this.email,
    this.phone,
    this.companyType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      bloc: sl<AuthBloc>(),
      builder: (context, state) {
        final user = state.user;
        final company = user?.company;
        final effectiveCompanyName = companyName ??
            company?.displayName ??
            (user?.name.isNotEmpty == true ? user!.name : 'Security Company');

        final effectiveEmail = email ?? company?.businessEmail ?? user?.email ?? '';
        final effectivePhone = phone ??
            (company?.companyPhoneNumber?.isNotEmpty == true
                ? '${company!.companyPhoneCode} ${company.companyPhoneNumber}'
                : (user?.phoneNumber?.isNotEmpty == true
                    ? '${user!.phoneCode} ${user.phoneNumber}'
                    : ''));
        final effectiveCompanyType = companyType ??
            company?.companyType?.label(context.l10n) ??
            BusinessType.pvtLtd.label(context.l10n);
        final expYears = company?.experienceYears ?? 0;
        final experienceFormatted = expYears > 0 ? '$expYears+ Yrs Exp' : '0 Yrs Exp';

        return Scaffold(
          appBar: AppAppBar.transparent(
            title: context.l10n.companyInformation,
            fontSize: 14,
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: context.horizontalEdgeInsets,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        AppSpacing.xl.h,

                        // 1. Company Name Card
                        _InfoCard(
                          label: context.l10n.companyName,
                          value: effectiveCompanyName,
                        ),

                        // 2. Email Card
                        _InfoCard(
                          label: context.l10n.email,
                          value: effectiveEmail,
                        ),

                        // 3. Phone Card
                        _InfoCard(
                          label: context.l10n.phone,
                          value: effectivePhone,
                        ),

                        // 4. Company Type Card
                        _InfoCard(
                          label: context.l10n.companyType,
                          value: effectiveCompanyType,
                        ),

                        // 6. Experience Card
                        _InfoCard(
                          label: 'Experience',
                          value: experienceFormatted,
                        ),

                        Spacer(),
                        AppSpacing.xl.h,

                        // Edit Information Button
                        AppButton(
                          text: context.l10n.update,
                          onPressed: () {
                            context.push(CompanyEditProfileScreen.route);
                          },
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
      },
    );
  }
}

/// Private stateless widget rendering an info card matching the design.
class _InfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return WrapperCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.textTheme.labelMedium?.colour(
              context.colors.primary,
            ),
          ),
          AppSpacing.xs.h,
          Text(value, style: context.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
