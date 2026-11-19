import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '../../../../core/extensions/number.extension.dart';
import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/string.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/config/admin_settings/admin_settings.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '/features/auth/data/model/user.model.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/model/transaction.model.dart';

/// Screen displaying a luxury payment confirmation receipt matching GuardUp design standards.
class PaymentSuccessScreen extends StatelessWidget {
  static const route = '/payment-success';

  final TransactionModel? transaction;
  final UserModel? user;
  final String? buttonText;
  final VoidCallback? onTap;

  const PaymentSuccessScreen({
    super.key,
    this.transaction,
    this.user,
    this.buttonText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final authState = sl.isRegistered<AuthBloc>() ? sl<AuthBloc>().state : null;
    final effectiveUser = user ?? authState?.user;
    final isGuard =
        (effectiveUser?.role == UserRole.guard) ||
        (authState?.isGuard ?? false);
    final companyName = (effectiveUser?.name.isNotEmpty == true
        ? effectiveUser!.name
        : (authState?.companyName ?? 'SecurePro Security Ltd.'));
    final officerName = (effectiveUser?.name.isNotEmpty == true
        ? effectiveUser!.name
        : (authState?.displayName ?? 'Michael Carter'));
    final initials = companyName.isNotEmpty ? companyName.getInitials() : 'SP';
    final referenceId = transaction?.referenceId ??
        transaction?.bookingId ??
        (authState?.userData?['metadata']?['payment_reference'] as String?) ??
        '#GD-884920';
    final scheduleText =
        transaction?.scheduleText ??
        transaction?.formattedDate ??
        'Today, 2:00 PM – 4:00 PM';
    final dynamicFee = transaction?.amount ??
        double.tryParse(
          authState?.userData?['metadata']?['payment_amount']?.toString() ?? '',
        ) ??
        context.read<AdminSettingsCubit>().getRegistrationFee(
          isGuard ? UserRole.guard : UserRole.company,
        );
    final amountText = dynamicFee.toUsd;
    final gateway = transaction?.gateway ?? context.l10n.stripeVerified;
    final discountNote =
        transaction?.discountNote ?? context.l10n.incMembershipDiscount;
    final effectiveButtonText = buttonText ?? context.l10n.next;

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
                                width: AppSizes.iconGiant,
                                height: AppSizes.iconGiant,
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                width: AppSizes.iconMdl,
                                height: AppSizes.iconMdl,
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
                                  size: AppSizes.iconSm,
                                  color: context.colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.xl.h,

                      // 2. Heading: "Payment Successful!"
                      QuickContainer(
                        shadows: [
                          // Upward subtle success glow radiating above the card
                          BoxShadow(
                            color: context.colors.success.withValues(
                              alpha: 0.30,
                            ),
                            blurRadius: 120,
                            spreadRadius: 8,
                            offset: Offset(0, 10),
                          ),
                        ],
                        child: Column(
                          mainAxisSize: .min,
                          children: [
                            Text(
                              context.l10n.paymentSuccessTitle,
                              textAlign: TextAlign.center,
                              style: context.textTheme.headlineLarge
                                  ?.semiBold(),
                            ),
                            AppSpacing.xs.h,

                            // 3. Subtitle: "Your Booking has been confirmed."
                            Text(
                              context.l10n.bookingConfirmedSubtitle,
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyMedium?.colour(
                                context.colors.onSurfaceVariant,
                              ),
                            ),
                            AppSpacing.xl.h,
                          ],
                        ),
                      ),

                      // 4. Receipt Details Card via WrapperCard (Upward success glow + visible dividers)
                      WrapperCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl,
                          vertical: AppSpacing.xxxl,
                        ),
                        borderWidth: 1.2,

                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 4a. Header Row (Guard vs Company)
                            if (isGuard)
                              Row(
                                children: [
                                  QuickContainer(
                                    w: 14.wPercent(context),
                                    h: 14.wPercent(context),
                                    radius: AppRadius.full,
                                    color: context.colors.surfaceDim,
                                    border: Border.all(
                                      color: context.colors.primary,
                                      width: 1.5,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: context.colors.primary,
                                      size: AppSizes.iconMd,
                                    ),
                                  ),
                                  AppSpacing.md.w,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'ASSIGNED OFFICER',
                                          style: context.textTheme.labelSmall
                                              ?.semiBold()
                                              .copyWith(
                                                color: context
                                                    .colors
                                                    .onSurfaceVariant,
                                                letterSpacing: 0.8,
                                              ),
                                        ),
                                        AppSpacing.xxs.h,
                                        Text(
                                          officerName,
                                          style: context.textTheme.titleSmall
                                              ?.bold(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  QuickContainer(
                                    px: AppSpacing.sm,
                                    py: AppSpacing.xxs,
                                    radius: AppRadius.round,
                                    color: context.colors.success.withValues(
                                      alpha: 0.15,
                                    ),
                                    border: Border.all(
                                      color: context.colors.success.withValues(
                                        alpha: 0.5,
                                      ),
                                      width: 1,
                                    ),
                                    child: Text(
                                      'Armed Escort',
                                      style: context.textTheme.labelSmall
                                          ?.semiBold()
                                          .copyWith(
                                            color: context.colors.success,
                                          ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  QuickContainer(
                                    w: 16.wPercent(context),
                                    h: 16.wPercent(context),
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
                                          .colour(context.colors.primary),
                                    ),
                                  ),
                                  AppSpacing.lg.w,
                                  Expanded(
                                    child: Text(
                                      companyName,
                                      style: context.textTheme.titleMedium
                                          ?.bold(),
                                    ),
                                  ),
                                ],
                              ),
                            AppSpacing.lg.h,

                            // 4b. Divider below company header (visible hairline)
                            Divider(
                              height: 1,
                              color: context.colors.outlineVariant,
                            ),
                            AppSpacing.lg.h,

                            // 4c. Reference ID
                            _buildInfoRow(
                              context,
                              label: context.l10n.referenceId,
                              valueWidget: Text(
                                referenceId,
                                style: context.textTheme.bodySmall?.medium(),
                              ),
                            ),
                            AppSpacing.md.h,

                            // 4d. Date & Schedule
                            _buildInfoRow(
                              context,
                              label: context.l10n.dateAndSchedule,
                              valueWidget: Text(
                                scheduleText,
                                style: context.textTheme.bodySmall?.medium(),
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
                                    gateway,
                                    style: context.textTheme.bodySmall
                                        ?.medium(),
                                  ),
                                  AppSpacing.sm.w,
                                  Assets.svg.paymentVerified.svg(
                                    height: AppSizes.iconXs,
                                  ),
                                ],
                              ),
                            ),
                            AppSpacing.lg.h,

                            // 4f. Divider above Total Paid (visible hairline)
                            Divider(
                              height: 1,
                              color: context.colors.outlineVariant,
                            ),
                            AppSpacing.lg.h,

                            // 4g. Total Paid Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  context.l10n.totalPaid,
                                  style: context.textTheme.titleMedium
                                      ?.medium(),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      amountText,
                                      style: context.textTheme.headlineMedium
                                          ?.bold()
                                          .colour(context.colors.primary),
                                    ),
                                    AppSpacing.xs.h,
                                    Text(
                                      discountNote,
                                      style: context.textTheme.bodySmall
                                          ?.colour(
                                            context.colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      AppSpacing.huge.h,

                      // 5. Action Button (default "Next ->")
                      AppButton(
                        text: effectiveButtonText,

                        onPressed: () {
                          if (onTap != null) {
                            onTap!();
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
          style: context.textTheme.bodySmall?.colour(
            context.colors.onSurfaceVariant,
          ),
        ),
        valueWidget,
      ],
    );
  }
}
