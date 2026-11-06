import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_sizes.dart';
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
import '/features/auth/auth.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/enum/transaction_type.enum.dart';
import '../../data/model/transaction.model.dart';

/// Screen presenting the one-time registration fee for verification and priority onboarding.
class RegistrationFeeScreen extends StatelessWidget {
  const RegistrationFeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(
        alignTitle: .center,
        titleWidget: Assets.svg.appBanner.svg(height: AppSizes.iconLg),
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
                              w: AppSizes.iconGiant,
                              h: AppSizes.iconGiant,
                              radius: AppRadius.full,
                              color: context.colors.primary.withValues(
                                alpha: 0.15,
                              ),
                              border: Border.all(
                                color: context.colors.primary.withValues(
                                  alpha: 0.45,
                                ),
                                width: 1.5,
                              ),
                              alignment: Alignment.center,
                              child: Assets.svg.dollar.svg(
                                width: AppSizes.iconLg,
                                height: AppSizes.iconLg,
                              ),
                            ),
                            AppSpacing.lg.h,

                            // 2. Title
                            Text(
                              context.l10n.oneTimeRegistrationFee,
                              textAlign: TextAlign.center,
                              style: context.textTheme.titleMedium
                                  ?.bold()
                                  .textSpacing(0.8),
                            ),
                            AppSpacing.xs.h,

                            // 3. Subtitle / Description
                            Text(
                              context.l10n.registrationFeeSubtitle,
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodySmall
                                  ?.colour(context.colors.onSurfaceVariant)
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
                                      .increaseSize(4)
                                      .lineHeight(1.0),
                                ),
                                AppSpacing.xs.w,
                                Text(
                                  '/ ${context.l10n.lifetime}',
                                  style: context.textTheme.labelMedium
                                      ?.colour(context.colors.onSurfaceVariant)
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
                              color: Colors.black,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: AppSizes.iconSm,
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

                              makeItGlow: true,
                              onPressed: () => context.push(
                                AppRoutes.paymentSuccess,
                                extra: (
                                  transaction: TransactionModel(
                                    id: '884920',
                                    referenceId: '#GD - 884920',
                                    bookingId: '#GD - 884920',
                                    amount: 49.0,
                                    currency: 'USD',
                                    type: TransactionType.debit,
                                    title: 'Registration Fee',
                                    gateway: 'Stripe Verified',
                                    scheduleText: 'Today, 2:00 PM – 4:00 PM',
                                    dateTime: DateTime.now(),
                                    discountNote:
                                        context.l10n.incMembershipDiscount,
                                  ),
                                  user: const UserModel(
                                    id: 'usr_securepro',
                                    name: 'SecurePro Security Ltd.',
                                    profileImageUrl: null,
                                    role: UserRole.company,
                                  ),
                                  buttonText: context.l10n.next,
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
                                      ?.textSpacing(-0.2),
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
