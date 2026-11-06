import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';

/// Screen presenting read-only company details.
class CompanyInformationScreen extends StatelessWidget {
  final String companyName;
  final String email;
  final String phone;
  final String address;
  final String companyType;

  const CompanyInformationScreen({
    super.key,
    this.companyName = 'SecurePro Security Ltd.',
    this.email = 'info@securepro.com',
    this.phone = '+1 416 555 0123',
    this.address = '123 Business Rd, Toronto, ON M5V 2T6',
    this.companyType = 'Security Services',
  });

  @override
  Widget build(BuildContext context) {
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
                  // crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSpacing.xl.h,

                    // 1. Company Name Card
                    _InfoCard(
                      label: context.l10n.companyName,
                      value: companyName,
                    ),

                    // 2. Email Card
                    _InfoCard(label: context.l10n.email, value: email),

                    // 3. Phone Card
                    _InfoCard(label: context.l10n.phone, value: phone),

                    // 4. Address Card
                    _InfoCard(label: context.l10n.address, value: address),

                    // 5. Company Type Card
                    _InfoCard(
                      label: context.l10n.companyType,
                      value: companyType,
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
