import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/sections/wrapper_card.dart';

/// Arguments passed to [PaymentSuccessScreen].
class PaymentSuccessArgs {
  final String? referenceId;
  final String? companyOrOperativeName;
  final String? companyInitials;
  final String? scheduleText;
  final String? amountText;
  final String? discountNote;
  final String? buttonText;
  final VoidCallback? onTap;

  const PaymentSuccessArgs({
    this.referenceId,
    this.companyOrOperativeName,
    this.companyInitials,
    this.scheduleText,
    this.amountText,
    this.discountNote,
    this.buttonText,
    this.onTap,
  });
}

/// Screen displaying a luxury payment confirmation receipt matching GuardUp design standards.
class PaymentSuccessScreen extends StatelessWidget {
  final PaymentSuccessArgs? args;

  const PaymentSuccessScreen({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    final referenceId = args?.referenceId ?? '#GD - 884920';
    final companyName =
        args?.companyOrOperativeName ?? 'SecurePro Security Ltd.';
    final initials = args?.companyInitials ?? 'SP';
    final scheduleText = args?.scheduleText ?? 'Today, 2:00 PM – 4:00 PM';
    final amountText = args?.amountText ?? r'$49';
    final discountNote =
        args?.discountNote ?? context.l10n.incMembershipDiscount;
    final buttonText = args?.buttonText ?? context.l10n.next;

    return Scaffold(
      backgroundColor: context.colors.transparent,
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
                      AppSpacing.colossal.h,

                      // 1. Verified Shield Badge (Gold outline, no glow around icon)
                      Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            QuickContainer(
                              w: 114,
                              h: 114,
                              radius: AppRadius.round,
                              color: context.colors.surfaceDim,
                              border: Border.all(
                                color: context.colors.primary.withValues(
                                  alpha: 0.85,
                                ),
                                width: 1.5,
                              ),
                              alignment: Alignment.center,
                              child: Assets.svg.verifiedShieldBadge.svg(
                                width: 54,
                                height: 54,
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.colors.success,
                                  border: Border.all(
                                    color: context.colors.surfaceDim,
                                    width: 3,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.check,
                                  size: 16,
                                  color: context.colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.xl.h,

                      // 2. Heading: "Payment Successful!"
                      Text(
                        context.l10n.paymentSuccessTitle,
                        textAlign: TextAlign.center,
                        style: context.textTheme.headlineMedium
                            ?.bold()
                            
                            .size(24)
                            .textSpacing(-0.2),
                      ),
                      AppSpacing.xs.h,

                      // 3. Subtitle: "Your Booking has been confirmed."
                      Text(
                        context.l10n.bookingConfirmedSubtitle,
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium
                            ?.regular()
                            .colour(context.colors.onSurfaceVariant)
                            .size(14),
                      ),
                      AppSpacing.xl.h,

                      // 4. Receipt Details Card via WrapperCard (Upward success glow + visible dividers)
                      WrapperCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl,
                          vertical: AppSpacing.xxxl,
                        ),
                        borderWidth: 1.2,
                        shadows: [
                          // Upward subtle success glow radiating above the card
                          BoxShadow(
                            color: context.colors.success.withValues(
                              alpha: 0.20,
                            ),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, -12),
                          ),
                        ],
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 4a. Company Header Row
                            Row(
                              children: [
                                QuickContainer(
                                  w: 18.wPercent(context),
                                  h: 18.wPercent(context),
                                  radius: AppRadius.full,
                                  color: context.colors.surfaceDim,
                                  border: Border.all(
                                    color: context.colors.primary,
                                    width: 1.5,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initials,
                                    style: context.textTheme.titleMedium
                                        ?.bold()
                                        .colour(context.colors.primary)
                                        .size(16),
                                  ),
                                ),
                                AppSpacing.lg.w,
                                Expanded(
                                  child: Text(
                                    companyName,
                                    style: context.textTheme.titleMedium
                                        ?.bold()
                                        
                                        .size(16),
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.lg.h,

                            // 4b. Divider below company header (visible hairline)
                            Container(
                              height: 1,
                              color: context.colors.outline.withValues(
                                alpha: 0.25,
                              ),
                            ),
                            AppSpacing.lg.h,

                            // 4c. Reference ID
                            _buildInfoRow(
                              context,
                              label: context.l10n.referenceId,
                              valueWidget: Text(
                                referenceId,
                                style: context.textTheme.bodyMedium
                                    ?.bold()
                                    
                                    .size(13)
                                    .textSpacing(0.5),
                              ),
                            ),
                            AppSpacing.md.h,

                            // 4d. Date & Schedule
                            _buildInfoRow(
                              context,
                              label: context.l10n.dateAndSchedule,
                              valueWidget: Text(
                                scheduleText,
                                style: context.textTheme.bodyMedium
                                    ?.medium()
                                    
                                    .size(13),
                              ),
                            ),
                            AppSpacing.md.h,

                            // 4e. Payment Gateway (Stripe Verified)
                            _buildInfoRow(
                              context,
                              label: context.l10n.paymentGateway,
                              valueWidget: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.l10n.stripeVerified,
                                    style: context.textTheme.bodyMedium
                                        ?.medium()
                                        
                                        .size(13),
                                  ),
                                  AppSpacing.sm.w,
                                  Assets.svg.paymentVerified.svg(height: 14),
                                ],
                              ),
                            ),
                            AppSpacing.lg.h,

                            // 4f. Divider above Total Paid (visible hairline)
                            Container(
                              height: 1,
                              color: context.colors.outline.withValues(
                                alpha: 0.25,
                              ),
                            ),
                            AppSpacing.lg.h,

                            // 4g. Total Paid Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.xxs,
                                  ),
                                  child: Text(
                                    context.l10n.totalPaid,
                                    style: context.textTheme.titleMedium
                                        ?.medium()
                                        
                                        .size(16),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      amountText,
                                      style: context.textTheme.headlineMedium
                                          ?.bold()
                                          .colour(context.colors.primary)
                                          .size(24)
                                          .lineHeight(1.0),
                                    ),
                                    AppSpacing.xs.h,
                                    Text(
                                      discountNote,
                                      style: context.textTheme.bodySmall
                                          ?.regular()
                                          .colour(
                                            context.colors.onSurfaceVariant,
                                          )
                                          .size(11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      AppSpacing.huge.h,

                      // 5. Action Button (default "Next", no arrow icon)
                      AppButton(
                        text: buttonText,
                        size: ButtonSize.large,
                        onPressed: () {
                          if (args?.onTap != null) {
                            args!.onTap!();
                          } else {
                            context.go(AppRoutes.adminApproval);
                          }
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
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required Widget valueWidget,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.textTheme.bodyMedium
              ?.regular()
              .colour(context.colors.onSurfaceVariant)
              .size(13),
        ),
        valueWidget,
      ],
    );
  }
}
