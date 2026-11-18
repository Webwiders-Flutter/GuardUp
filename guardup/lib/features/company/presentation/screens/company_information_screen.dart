import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '/app/routes/app_routes.dart';
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

/// Screen presenting read-only company details.
class CompanyInformationScreen extends StatelessWidget {
  static const route = '/company-information';

  final String? companyName;
  final String? email;
  final String? phone;
  final String? address;
  final String? companyType;

  const CompanyInformationScreen({
    super.key,
    this.companyName,
    this.email,
    this.phone,
    this.address,
    this.companyType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      bloc: sl<AuthBloc>(),
      builder: (context, state) {
        final effectiveCompanyName = companyName ??
            (state.companyName.isNotEmpty
                ? state.companyName
                : 'Security Company');

        final effectiveEmail = email ?? state.businessEmail;
        final effectivePhone = phone ?? state.displayPhone;
        final effectiveAddress = address ??
            (state.address.isNotEmpty
                ? state.address
                : 'Not specified');
        final effectiveCompanyType = companyType ??
            (state.companyType.isNotEmpty
                ? state.companyType
                : 'Private Limited (Pvt Ltd)');

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

                        // 4. Address Card
                        _InfoCard(
                          label: context.l10n.address,
                          value: effectiveAddress,
                        ),

                        // 5. Company Type Card
                        _InfoCard(
                          label: context.l10n.companyType,
                          value: effectiveCompanyType,
                        ),

                        Spacer(),
                        AppSpacing.xl.h,

                        // Edit Information Button
                        AppButton(
                          text: context.l10n.update,
                          onPressed: () {
                            context.push(AppRoutes.companyEditProfile);
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
