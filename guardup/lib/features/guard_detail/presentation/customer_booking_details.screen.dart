import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/body_guard/data/model/body_guard.model.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';

/// Screen 4: Final Booking Details & Payment Summary review screen before payment authorization.
class CustomerBookingDetailsScreen extends StatelessWidget {
  final BodyGuardModel? bodyguard;
  final DateTime startDate;
  final TimeOfDay startTime;
  final DateTime endDate;
  final TimeOfDay endTime;
  final int durationHours;
  final double hourlyRate;

  const CustomerBookingDetailsScreen({
    super.key,
    this.bodyguard,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    this.durationHours = 4,
    this.hourlyRate = 60.0,
  });

  double get operativeSubtotal => hourlyRate * durationHours;
  double get discountAmount => 15.0;
  double get finalTotal => operativeSubtotal - discountAmount;

  @override
  Widget build(BuildContext context) {
    final guardName = bodyguard?.user.name ?? 'Vikram Singh';
    final photoPath =
        bodyguard?.user.profileImageUrl ?? Assets.images.onboardingImage01.path;

    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedStartDate = dateFormat.format(startDate);
    final formattedEndDate = dateFormat.format(endDate);

    final startPeriod = startTime.period == DayPeriod.am ? 'AM' : 'PM';
    final formattedStartTime =
        '${startTime.hourOfPeriod.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} $startPeriod';

    final endPeriod = endTime.period == DayPeriod.am ? 'AM' : 'PM';
    final formattedEndTime =
        '${endTime.hourOfPeriod.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')} $endPeriod';

    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar.transparent(
        title: 'Booking Details',
        showBackIcon: true,
        alignTitle: AlignTitle.right,
        onBackTap: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: context.horizontalEdgeInsets,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpacing.sm.h,

                    // 1. Mini Bodyguard Summary Card
                    QuickContainer(
                      w: double.infinity,
                      px: 12,
                      py: 15,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      color: context.colors.onPrimary,
                      border: Border.all(
                        color: context.colors.borderColor.withValues(
                          alpha: 0.5,
                        ),
                        width: 1,
                      ),
                      child: Row(
                        children: [
                          Stack(
                            alignment: AlignmentGeometry.bottomRight,
                            children: [
                              QuickContainer(
                                mb: 5,
                                mr: 5,
                                borderColor: context.colors.primary.withValues(
                                  alpha: 0.6,
                                ),
                                borderWidth: 0.6,
                                clipBehavior: .hardEdge,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                child: SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: AppImage.asset(
                                    assetPath: photoPath,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                child: Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: context.colors.primary,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.sm.w,

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: .start,
                              children: [
                                Row(
                                  mainAxisAlignment: .spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          guardName,
                                          style: context.textTheme.titleSmall
                                              ?.bold()
                                              .colour(context.colors.onSurface),
                                        ),
                                        AppSpacing.xxs.w,
                                        Assets.svg.verifiedShieldBadge.svg(
                                          width: 14,
                                          height: 14,
                                        ),
                                      ],
                                    ),
                                    // Rate in Primary
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '\$${hourlyRate.toInt()}',
                                            style: context.textTheme.titleSmall
                                                ?.bold()
                                                .colour(context.colors.primary),
                                          ),
                                          TextSpan(
                                            text: ' /hr',
                                            style: context.textTheme.labelSmall
                                                ?.copyWith(fontSize: 10)
                                                .colour(
                                                  context
                                                      .colors
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                AppSpacing.xs.h,

                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: context.colors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    AppSpacing.sm.w,
                                    Text(
                                      'Licensed armed, Corporate visits',
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(fontSize: 10)
                                          .colour(context.colors.primary),
                                    ),
                                  ],
                                ),
                                AppSpacing.xs.h,

                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 13,
                                      color: context.colors.primary,
                                    ),
                                    AppSpacing.xxs.w,
                                    Text(
                                      '4.9',
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          )
                                          .colour(context.colors.onSurface),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.lg.h,

                    // 2. DATE & TIME Section
                    Text(
                      'DATE & TIME',
                      style: context.textTheme.labelMedium
                          ?.bold()
                          .copyWith(letterSpacing: 0.8)
                          .colour(context.colors.onSurfaceVariant),
                    ),
                    AppSpacing.sm.h,

                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoTile(
                                context,
                                label: 'START DATE',
                                value: formattedStartDate,
                                icon: Icons.calendar_today_rounded,
                              ),
                            ),
                            AppSpacing.md.w,
                            Expanded(
                              child: _buildInfoTile(
                                context,
                                label: 'START TIME',
                                value: formattedStartTime,
                                icon: Icons.access_time_rounded,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.md.h,
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoTile(
                                context,
                                label: 'END DATE',
                                value: formattedEndDate,
                                icon: Icons.calendar_today_rounded,
                              ),
                            ),
                            AppSpacing.md.w,
                            Expanded(
                              child: _buildInfoTile(
                                context,
                                label: 'END TIME',
                                value: formattedEndTime,
                                icon: Icons.access_time_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    AppSpacing.lg.h,

                    // 3. PAYMENT SUMMARY Section
                    QuickContainer(
                      w: double.infinity,
                      p: AppSpacing.md,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      color: context.colors.onPrimary,
                      border: Border.all(
                        color: context.colors.borderColor.withValues(
                          alpha: 0.5,
                        ),
                        width: 1,
                      ),
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PAYMENT SUMMARY',
                                style: context.textTheme.labelMedium
                                    ?.bold()
                                    .copyWith(letterSpacing: 0.8)
                                    .colour(context.colors.onSurfaceVariant),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: context.colors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: context.colors.primary.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  'EXECUTIVE TIER',
                                  style: context.textTheme.labelSmall
                                      ?.copyWith(
                                        fontSize: 9.5,
                                        letterSpacing: 0.5,
                                      )
                                      .colour(context.colors.primary),
                                ),
                              ),
                            ],
                          ),

                          Divider(
                            color: context.colors.outlineVariant.withValues(
                              alpha: 0.4,
                            ),
                            height: 25,
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Operative Rate (\$${hourlyRate.toStringAsFixed(2)} x $durationHours hrs)',
                                style: context.textTheme.bodySmall?.colour(
                                  context.colors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '\$${operativeSubtotal.toStringAsFixed(2)}',
                                style: context.textTheme.bodySmall?.colour(
                                  context.colors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.sm.h,

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '20% Discount ',
                                    style: context.textTheme.bodySmall?.colour(
                                      context.colors.success,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.colors.success.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.xs,
                                      ),
                                      border: .all(
                                        color: context.colors.success,
                                        width: 0.3,
                                      ),
                                    ),

                                    child: Text(
                                      'Gold Sentinel',
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(fontSize: 9)
                                          .colour(context.colors.success),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '-\$${discountAmount.toStringAsFixed(2)}',
                                style: context.textTheme.bodySmall?.colour(
                                  context.colors.success,
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            color: context.colors.outlineVariant.withValues(
                              alpha: 0.4,
                            ),
                            height: 25,
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL AMOUNT',
                                style: context.textTheme.labelMedium
                                    ?.bold()
                                    .colour(context.colors.onSurface),
                              ),
                              Text(
                                '\$${finalTotal.toStringAsFixed(2)}',
                                style: context.textTheme.titleLarge
                                    ?.bold()
                                    .colour(context.colors.primary),
                              ),
                            ],
                          ),
                          // AppSpacing.xxs.h,

                          Text(
                            'Includes all taxes & insurance',
                            style: context.textTheme.labelSmall
                                ?.copyWith(fontSize: 10)
                                .colour(
                                  context.colors.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),

                    AppSpacing.xl.h,
                  ],
                ),
              ),
            ),

            // Bottom Pinned Next Button
            Padding(
              padding: context.horizontalEdgeInsets.add(
                const EdgeInsets.only(bottom: AppSpacing.lg),
              ),
              child: AppButton(
                text: 'Next',
                size: ButtonSize.large,
                trailing: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: context.colors.onPrimary,
                ),
                onPressed: () {
                  context.push(AppRoutes.paymentSuccess);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.surfaceDim,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.labelSmall
                ?.copyWith(fontSize: 9.5)
                .colour(context.colors.onSurfaceVariant),
          ),
          6.h,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelMedium,
                ),
              ),
              Icon(icon, size: 14, color: context.colors.primary),
            ],
          ),
        ],
      ),
    );
  }
}
