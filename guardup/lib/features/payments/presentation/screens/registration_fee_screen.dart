import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import 'payment_success_screen.dart';

/// Screen presenting the one-time registration fee for verification and priority onboarding.
class RegistrationFeeScreen extends StatelessWidget {
  const RegistrationFeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar.transparent(
        alignTitle: .center,
        titleWidget: Assets.svg.appBanner.svg(height: 24),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: context.horizontalEdgeInsets,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      AppSpacing.md.h,

                      // Registration Fee Card via WrapperCard
                      WrapperCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.xxl,
                        ),
                        borderColor: context.colors.primaryContainer,

                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Dollar Coin Badge
                            QuickContainer(
                              w: 58,
                              h: 58,
                              radius: AppRadius.full,
                              color: context.colors.surfaceContainerHigh
                                  .withValues(alpha: 0.8),
                              border: Border.all(
                                color: context.colors.primary.withValues(
                                  alpha: 0.45,
                                ),
                                width: 1.5,
                              ),
                              alignment: Alignment.center,
                              child: Assets.svg.dollar.svg(
                                width: 26,
                                height: 26,
                              ),
                            ),
                            AppSpacing.lg.h,

                            // 2. Title
                            Text(
                              context.l10n.oneTimeRegistrationFee,
                              textAlign: TextAlign.center,
                              style: context.textTheme.titleMedium
                                  ?.bold()
                                  .colour(context.colors.onSurface)
                                  .textSpacing(0.8),
                            ),
                            AppSpacing.xs.h,

                            // 3. Subtitle / Description
                            Text(
                              context.l10n.registrationFeeSubtitle,
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodySmall
                                  ?.regular()
                                  .colour(context.colors.onSurfaceVariant)
                                  .lineHeight(1.35),
                            ),
                            AppSpacing.xxl.h,

                            // 4. Price & Lifetime Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  49.toUsd,
                                  style: context.textTheme.headlineLarge
                                      ?.bold()
                                      .colour(context.colors.primary)
                                      .size(36)
                                      .lineHeight(1.0),
                                ),
                                AppSpacing.xs.w,
                                Text(
                                  '/ ${context.l10n.lifetime}',
                                  style: context.textTheme.labelMedium
                                      ?.regular()
                                      .colour(context.colors.onSurfaceVariant)
                                      .textSpacing(0.8),
                                ),
                              ],
                            ),
                            AppSpacing.xxl.h,

                            // 5. Secure Stripe Pill Badge
                            QuickContainer(
                              px: AppSpacing.lg,
                              py: AppSpacing.sm,
                              radius: AppRadius.round,
                              color: context.colors.successContainer,
                              border: Border.all(
                                color: context.colors.success.withValues(
                                  alpha: 0.4,
                                ),
                                width: 1,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: 15,
                                    color: context.colors.success,
                                  ),
                                  AppSpacing.xs.w,
                                  Text(
                                    context.l10n.securePaymentWithStripe,
                                    style: context.textTheme.labelSmall?.colour(
                                      context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppSpacing.xl.h,

                            // 6. Pay Now Button (with primary glow)
                            AppButton(
                              text: context.l10n.payNow,
                              size: ButtonSize.large,
                              makeItGlow: true,
                              onPressed: () => context.push(
                                AppRoutes.paymentSuccess,
                                extra: PaymentSuccessArgs(
                                  referenceId: '#GD - 884920',
                                  companyOrOperativeName:
                                      'SecurePro Security Ltd.',
                                  companyInitials: 'SP',
                                  scheduleText: 'Today, 2:00 PM – 4:00 PM',
                                  amountText: r'$49',
                                  discountNote:
                                      context.l10n.incMembershipDiscount,
                                  onTap: () =>
                                      context.go(AppRoutes.adminApproval),
                                ),
                              ),
                            ),
                            AppSpacing.lg.h,

                            // 7. Powered by Stripe Footer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '${context.l10n.poweredBy}  ',
                                  style: context.textTheme.labelSmall?.colour(
                                    context.colors.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  'stripe',
                                  style: context.textTheme.titleSmall
                                      ?.textSpacing(-0.2)
                                      .colour(context.colors.onSurface),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),
                      AppSpacing.xl.h,
                    ],
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
