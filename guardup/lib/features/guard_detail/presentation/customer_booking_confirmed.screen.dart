import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/body_guard/data/model/body_guard.model.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';

/// Screen 6: Booking Confirmed Screen displaying verified badge, bodyguard summary,
/// booking ID reference, and quick navigation to chat or live operative tracking.
class CustomerBookingConfirmedScreen extends StatelessWidget {
  static const route = '/booking-confirmed';

  final BodyGuardModel? bodyguard;
  final String? guardName;
  final String? guardPhoto;
  final DateTime? startDate;
  final TimeOfDay? startTime;
  final DateTime? endDate;
  final TimeOfDay? endTime;
  final double? hourlyRate;
  final String? bookingId;
  final VoidCallback? onChatTap;
  final VoidCallback? onTrackLiveTap;

  const CustomerBookingConfirmedScreen({
    super.key,
    this.bodyguard,
    this.guardName,
    this.guardPhoto,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.hourlyRate,
    this.bookingId,
    this.onChatTap,
    this.onTrackLiveTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGuardName =
        guardName ?? bodyguard?.user.name ?? 'Vikram Singh';
    final effectivePhoto =
        guardPhoto ??
        bodyguard?.user.profileImageUrl ??
        Assets.images.onboardingImage01.path;
    final effectiveRate = hourlyRate ?? bodyguard?.hourlyRate ?? 60.0;
    final effectiveBookingId = bookingId ?? '#GUPT25456';

    // Format schedule text (e.g., 'Apr 26, 2025 • 10:00 AM - 2:00 PM')
    final effectiveStartDate = startDate ?? DateTime(2025, 4, 26);
    final effectiveStartTime =
        startTime ?? const TimeOfDay(hour: 10, minute: 0);
    final effectiveEndTime = endTime ?? const TimeOfDay(hour: 14, minute: 0);

    final dateStr = DateFormat('MMM d, yyyy').format(effectiveStartDate);
    final startPeriod = effectiveStartTime.period == DayPeriod.am ? 'AM' : 'PM';
    final formattedStartTime =
        '${effectiveStartTime.hourOfPeriod == 0 ? 12 : effectiveStartTime.hourOfPeriod}:${effectiveStartTime.minute.toString().padLeft(2, '0')} $startPeriod';
    final endPeriod = effectiveEndTime.period == DayPeriod.am ? 'AM' : 'PM';
    final formattedEndTime =
        '${effectiveEndTime.hourOfPeriod == 0 ? 12 : effectiveEndTime.hourOfPeriod}:${effectiveEndTime.minute.toString().padLeft(2, '0')} $endPeriod';

    final scheduleText = '$dateStr • $formattedStartTime - $formattedEndTime';

    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar.transparent(
        title: 'Booking confirmed',
        showBackIcon: true,
        alignTitle: AlignTitle.right,
        onBackTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.horizontalEdgeInsets,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.xl.h,

              // 1. Center Verified Shield Badge with Success Checkmark
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceDim,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: context.colors.primary.withValues(alpha: 0.85),
                          width: 1.5,
                        ),
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
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.colors.success,
                          border: Border.all(
                            color: context.colors.surfaceDim,
                            width: 2.5,
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

              // 2. Heading "Booking Confirmed!"
              Text(
                'Booking Confirmed!',
                textAlign: TextAlign.center,
                style: context.textTheme.headlineSmall?.bold().colour(
                  context.colors.onSurface,
                ),
              ),
              AppSpacing.xs.h,

              // 3. Subtitle
              Text(
                'Your booking has been confirmed.\nYou will receive a notification shortly.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium
                    ?.copyWith(height: 1.4)
                    .colour(context.colors.onSurfaceVariant),
              ),
              AppSpacing.xl.h,

              // 4. Booking Summary Card (Guard info, rate, Booking ID)
              QuickContainer(
                w: double.infinity,
                px: 14,
                py: 14,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                color: context.colors.onPrimary,
                border: Border.all(
                  color: context.colors.borderColor.withValues(alpha: 0.5),
                  width: 1,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 4a. Bodyguard Row
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: AppImage.asset(
                              assetPath: effectivePhoto,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        12.w,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                effectiveGuardName,
                                style: context.textTheme.titleSmall
                                    ?.bold()
                                    .colour(context.colors.onSurface),
                              ),
                              4.h,
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 12,
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                  5.w,
                                  Expanded(
                                    child: Text(
                                      scheduleText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(fontSize: 10.5)
                                          .colour(
                                            context.colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.xs.w,
                        // Hourly Rate
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '\$${effectiveRate.toInt()}',
                                style: context.textTheme.titleSmall
                                    ?.bold()
                                    .colour(context.colors.primary),
                              ),
                              TextSpan(
                                text: '/hr',
                                style: context.textTheme.labelSmall
                                    ?.copyWith(fontSize: 10)
                                    .colour(context.colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    Divider(
                      height: 24,
                      color: context.colors.outlineVariant.withValues(
                        alpha: 0.35,
                      ),
                    ),

                    // 4b. Booking ID Row with Copy
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'BOOKING ID',
                          style: context.textTheme.labelSmall
                              ?.copyWith(
                                fontSize: 10.5,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w600,
                              )
                              .colour(context.colors.onSurfaceVariant),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              effectiveBookingId,
                              style: context.textTheme.labelMedium
                                  ?.bold()
                                  .colour(context.colors.primary),
                            ),
                            6.w,
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: effectiveBookingId),
                                );
                                AppSnackbar.success(
                                  'Booking ID copied to clipboard',
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Icon(
                                  Icons.copy_rounded,
                                  size: 14,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              AppSpacing.xl.h,

              // 5. Button 1: "Chat with vikram singh"
              QuickContainer(
                w: double.infinity,
                h: 48,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                color: context.colors.onPrimary,
                border: Border.all(
                  color: context.colors.borderColor.withValues(alpha: 0.5),
                  width: 1,
                ),
                alignment: Alignment.center,
                onTap: () {
                  // if (onChatTap != null) {
                  //   onChatTap!();
                  // } else {
                  //   context.push(AppRoutes.chat);
                  // }
                },
                child: Text(
                  'Chat with ${effectiveGuardName.toLowerCase()}',
                  style: context.textTheme.titleSmall?.semiBold().colour(
                    context.colors.onSurface,
                  ),
                ),
              ),
              AppSpacing.md.h,

              // 6. Button 2: "Track Live ->"
              AppButton(
                text: 'Track Live',
                height: 48,
                size: ButtonSize.large,
                trailing: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: context.colors.onPrimary,
                ),
                onPressed: () {
                  if (onTrackLiveTap != null) {
                    onTrackLiveTap!();
                  } else {
                    context.go(AppRoutes.bookings);
                  }
                },
              ),

              AppSpacing.xl.h,
            ],
          ),
        ),
      ),
    );
  }
}
