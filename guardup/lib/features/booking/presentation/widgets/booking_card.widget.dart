import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/datetime.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/auth.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/enum/booking_status.enum.dart';
import '../../data/model/booking.model.dart';
import '/core/extensions/bodyguard.extension.dart';

/// A sleek, luxury card widget presenting a bodyguard booking assignment.
///
/// Features dynamic UI adaptations according to role perspective:
/// - **Customer Role ([UserRole.customer])**:
///   - Highlights the assigned operative (bodyguard avatar with verified badge,
///     name, specialization tag, star rating, review count, and years of experience).
///   - Completed state with review displays an embedded review & star rating box
///     plus a prominent [Book Again] action.
///   - Completed state without review displays [Rate & Review →] and [Book Again].
///   - Running state displays live start & ETA info plus [Track Live Location →] and [Chat].
///
/// - **Guard / Operative Role ([UserRole.guard])**:
///   - Highlights the client details (customer avatar, customer name, schedule,
///     pickup address, booking reference ID).
///   - Pending: [Accept Request] & [Reject].
///   - Running: [Chat] & [Share Location].
///   - Completed: Clean view without action buttons.
class BookingCard extends StatelessWidget {
  /// The booking domain model holding operative, customer, and schedule details.
  final BookingModel booking;

  /// The perspective role governing card layout. Defaults to customer if [isCustomerView] is true,
  /// otherwise resolves from auth session or defaults to [UserRole.guard].
  final UserRole? role;

  /// Explicit flag to force customer view.
  final bool? isCustomerView;

  /// Optional card tap callback.
  final VoidCallback? onTap;

  // ── Guard Callbacks ────────────────────────────────────────────────────────
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onShareLocation;
  final VoidCallback? onViewDetails;

  // ── Customer Callbacks ─────────────────────────────────────────────────────
  final VoidCallback? onRateAndReview;
  final VoidCallback? onBookAgain;
  final VoidCallback? onTrackLocation;
  final VoidCallback? onCancelRequest;

  // ── Shared Callbacks ───────────────────────────────────────────────────────
  final VoidCallback? onChat;
  final Widget? customBottomAction;

  /// Whether to suppress all bottom action buttons (defaults to false).
  final bool noAction;

  const BookingCard({
    super.key,
    required this.booking,
    this.role,
    this.isCustomerView,
    this.noAction = false,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.onShareLocation,
    this.onViewDetails,
    this.onRateAndReview,
    this.onBookAgain,
    this.onTrackLocation,
    this.onCancelRequest,
    this.onChat,
    this.customBottomAction,
  });

  bool get _isCustomer {
    if (isCustomerView != null) return isCustomerView!;
    return role == UserRole.customer;
  }

  bool get _hasBottomActions {
    if (noAction) return false;
    if (customBottomAction != null) return true;
    if (_isCustomer) {
      // Customer has actions across all states (Rate/Book Again, Track/Chat, Cancel)
      return true;
    }
    // Guard has actions on Pending and Running
    switch (booking.status) {
      case BookingStatus.pending:
      case BookingStatus.onGoing:
      case BookingStatus.confirmed:
        return true;
      case BookingStatus.completed:
      case BookingStatus.cancelled:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WrapperCard(
      onTap: onTap,
      padding: AppSpacing.lg.allPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // -------------------------------------------------------------------
          // 1. Top Section (Avatar, Status Pill, Name, Credentials, Rate)
          // -------------------------------------------------------------------
          _isCustomer
              ? _buildCustomerViewHeader(context)
              : _buildGuardViewHeader(context),
          AppSpacing.xs.h,
          Divider(color: context.colors.outline, thickness: 0.2),
          AppSpacing.ssm.h,

          // -------------------------------------------------------------------
          // 2. Middle Section (Schedule, Tracking / Location, Reference #)
          // -------------------------------------------------------------------
          _isCustomer
              ? _buildCustomerViewMiddle(context)
              : _buildGuardViewMiddle(context),

          // -------------------------------------------------------------------
          // 3. Embedded Customer Review & Rating Box (if present in Customer view)
          // -------------------------------------------------------------------
          if (_isCustomer &&
              (booking.customerRating != null ||
                  booking.customerReviewText != null)) ...[
            AppSpacing.md.h,
            _buildReviewAndRatingBox(context),
          ],

          // -------------------------------------------------------------------
          // 4. Dynamic Bottom Action Buttons
          // -------------------------------------------------------------------
          if (_hasBottomActions) ...[
            AppSpacing.smd.h,
            Divider(color: context.colors.outline, thickness: 0.2),
            AppSpacing.smd.h,
            _buildActionButtons(context),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // CUSTOMER VIEW BUILDERS
  // ===========================================================================

  Widget _buildCustomerViewHeader(BuildContext context) {
    final guard = booking.bodyguard;
    final avatarUrl = guard.profileImageUrl;
    final isNetworkAvatar = avatarUrl != null && avatarUrl.startsWith('http');
    final isVerified = guard.isVerified;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bodyguard Avatar with Verified Badge (Squircle matching mockup)
        Stack(
          clipBehavior: Clip.none,
          children: [
            isNetworkAvatar
                ? AppImage.network(
                    imageUrl: avatarUrl,
                    width: 20.wPercent(context),
                    height: 11.hPercent(context),
                    fit: BoxFit.cover,
                    borderRadius: AppRadius.sm.toBorderRadius,
                  )
                : AppImage.asset(
                    assetPath: avatarUrl ?? Assets.images.profilePicture.path,
                    width: 20.wPercent(context),
                    height: 11.hPercent(context),
                    fit: BoxFit.cover,
                    borderRadius: AppRadius.sm.toBorderRadius,
                  ),
            if (isVerified)
              Positioned(
                right: -2,
                bottom: -2,
                child: QuickContainer(
                  shape: QuickContainerShape.circle,
                  color: context.colors.surface,
                  p: 2,
                  child: QuickContainer(
                    shape: QuickContainerShape.circle,
                    color: context.colors.primary,
                    p: 2,
                    child: Icon(
                      Icons.check_rounded,
                      size: AppSizes.iconTiny,
                      color: context.colors.onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        AppSpacing.md.w,

        // Status Badge, Bodyguard Name, Specialization, Star Rating Row
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusBadge(context),
              AppSpacing.xs.h,
              Text(
                guard.name,
                style: context.textTheme.titleMedium?.bold(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppSpacing.xxs.h,
              Text(
                booking.bodyguardSpecialization ??
                    (booking.bodyguard.bio.isNotEmpty
                        ? booking.bodyguard.bio
                        : 'Licensed armed, Corporate visits'),
                style: context.textTheme.bodySmall?.colour(
                  context.colors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppSpacing.xs.h,
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: AppSizes.iconXs,
                    color: context.colors.primary,
                  ),
                  AppSpacing.xxs.w,
                  Text(
                    guard.rating.toStringAsFixed(1),
                    style: context.textTheme.labelSmall?.colour(
                      context.colors.primary,
                    ),
                  ),
                  Text(
                    '  •  ',
                    style: context.textTheme.labelSmall?.colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${guard.reviewCount} reviews',
                    style: context.textTheme.labelSmall?.colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '  •  ',
                    style: context.textTheme.labelSmall?.colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      guard.experienceYears > 0
                          ? '${guard.experienceYears}+ yrs exp'
                          : '0 yrs exp',
                      style: context.textTheme.labelSmall?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.xs.w,

        // Hourly Rate (e.g. "$60 /hr")
        _buildHourlyRate(context),
      ],
    );
  }

  Widget _buildCustomerViewMiddle(BuildContext context) {
    final isRunning = booking.status == BookingStatus.onGoing;
    final trackingText = booking.trackingStatusText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRunning && trackingText != null && trackingText.isNotEmpty)
          _buildInfoRow(
            context: context,
            icon: QuickContainer(
              shape: QuickContainerShape.circle,
              color: context.colors.success,
              w: 7,
              h: 7,
            ),
            text: trackingText,
          )
        else
          _buildInfoRow(
            context: context,
            icon: Icon(
              Icons.calendar_today_outlined,
              size: AppSizes.iconSm,
              color: context.colors.primary,
            ),
            text:
                booking.scheduleLabel ??
                '${booking.startDateTime.readableDate} • ${booking.startDateTime.time12h} – ${booking.endDateTime.time12h}',
          ),
        AppSpacing.sm.h,
        _buildInfoRow(
          context: context,
          icon: Assets.svg.location.svg(
            width: AppSizes.iconSm,
            height: AppSizes.iconSm,
            colorFilter: ColorFilter.mode(
              context.colors.primary,
              BlendMode.srcIn,
            ),
          ),
          text: booking.pickupAddress ?? 'Yorkville Plaza, Toronto, ON',
        ),
      ],
    );
  }

  Widget _buildReviewAndRatingBox(BuildContext context) {
    final rating = booking.customerRating ?? 0.0;
    final reviewText = booking.customerReviewText ?? '';

    return QuickContainer(
      radius: AppRadius.md,
      color: context.colors.surfaceContainerHigh.withValues(alpha: 0.5),
      border: Border.all(
        color: context.colors.outlineVariant.withValues(alpha: 0.4),
        width: 1,
      ),
      p: AppSpacing.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review and Rating', style: context.textTheme.bodySmall?.bold()),
          AppSpacing.xs.h,
          Row(
            children: List.generate(5, (index) {
              final isFilled = index < rating.round();
              return Padding(
                padding: const EdgeInsets.only(right: 3.0),
                child: Icon(
                  Icons.star_rounded,
                  size: AppSizes.iconSm,
                  color: isFilled
                      ? context.colors.primary
                      : context.colors.outline.withValues(alpha: 0.4),
                ),
              );
            }),
          ),
          if (reviewText.isNotEmpty) ...[
            AppSpacing.xs.h,
            Text(
              reviewText,
              style: context.textTheme.labelSmall
                  ?.colour(context.colors.onSurfaceVariant)
                  .lineHeight(1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // GUARD VIEW BUILDERS
  // ===========================================================================

  Widget _buildGuardViewHeader(BuildContext context) {
    final avatarUrl = booking.customer.profileImageUrl;
    final isNetworkAvatar = avatarUrl != null && avatarUrl.startsWith('http');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Circular Customer Avatar
        isNetworkAvatar
            ? AppImage.network(
                imageUrl: avatarUrl,
                width: 16.wPercent(context),
                height: 16.wPercent(context),
                shape: BoxShape.circle,
                fit: BoxFit.cover,
              )
            : AppImage.asset(
                assetPath: avatarUrl ?? Assets.images.profilePicture.path,
                width: 16.wPercent(context),
                height: 16.wPercent(context),
                shape: BoxShape.circle,
                fit: BoxFit.cover,
              ),
        AppSpacing.md.w,

        // Status Badge + Customer Name Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  _buildStatusBadge(context),
                  _buildHourlyRate(context),
                ],
              ),
              AppSpacing.xs.h,
              Text(
                booking.customer.name,
                style: context.textTheme.titleMedium?.bold(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Hourly Rate (e.g. "$60 /hr")
      ],
    );
  }

  Widget _buildGuardViewMiddle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          context: context,
          icon: Icon(
            Icons.calendar_today_outlined,
            size: AppSizes.iconSm,
            color: context.colors.primary,
          ),
          text:
              booking.scheduleLabel ??
              '${booking.startDateTime.readableDate} • ${booking.startDateTime.time12h} – ${booking.endDateTime.time12h}',
        ),
        AppSpacing.sm.h,
        _buildInfoRow(
          context: context,
          icon: Assets.svg.location.svg(
            width: AppSizes.iconXs,
            height: AppSizes.iconXs,
            colorFilter: ColorFilter.mode(
              context.colors.primary,
              BlendMode.srcIn,
            ),
          ),
          text: booking.pickupAddress ?? 'Yorkville Plaza, Toronto, ON',
        ),
        AppSpacing.sm.h,
        _buildInfoRow(
          context: context,
          icon: Assets.svg.docPage.svg(
            width: AppSizes.iconXs,
            height: AppSizes.iconXs,
            colorFilter: ColorFilter.mode(
              context.colors.primary,
              BlendMode.srcIn,
            ),
          ),
          text: booking.bookingNumber,
        ),
      ],
    );
  }

  // ===========================================================================
  // COMMON SHARED SUBCOMPONENTS
  // ===========================================================================

  Widget _buildHourlyRate(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          (booking.hourlyRate ?? booking.bodyguard.hourlyRate).toUsd,
          style: context.textTheme.titleMedium?.bold().colour(
            context.colors.primary,
          ),
        ),
        Text(
          ' /hr',
          style: context.textTheme.labelSmall?.colour(
            context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final status = booking.status;
    final color = status.badgeColor(context);
    final bgColor = status.badgeBackgroundColor(context);
    final borderColor = status.badgeBorderColor(context);

    return QuickContainer(
      radius: AppRadius.sm,
      color: bgColor,
      border: Border.all(color: borderColor, width: 1.0),
      px: AppSpacing.sm,
      py: 3.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status.hasDot) ...[
            QuickContainer(
              shape: QuickContainerShape.circle,
              color: color,
              w: 6,
              h: 6,
            ),
            AppSpacing.xs.w,
          ],
          Text(
            status.label,
            style: context.textTheme.labelSmall?.semiBold().colour(color),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required Widget icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        icon,
        AppSpacing.sm.w,
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodySmall?.colour(
              context.colors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // DYNAMIC ACTION BUTTONS
  // ===========================================================================

  Widget _buildActionButtons(BuildContext context) {
    if (customBottomAction != null) {
      return customBottomAction!;
    }

    if (_isCustomer) {
      return _buildCustomerActions(context);
    }
    return _buildGuardActions(context);
  }

  /// Customer perspective action buttons
  Widget _buildCustomerActions(BuildContext context) {
    switch (booking.status) {
      // 1. Completed State
      case BookingStatus.completed:
        final hasSubmittedReview =
            booking.customerRating != null ||
            booking.customerReviewText != null;

        // Card 3: Already reviewed -> Full width "Book Again" button
        if (hasSubmittedReview) {
          return AppButton(
            text: 'Book Again',
            type: ButtonType.primary,
            size: ButtonSize.normal,
            onPressed: onBookAgain,
          );
        }

        // Card 1: Completed without review -> [Rate & Review →] & [Book Again]
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: AppButton(
                text: 'Rate & Review',
                trailing: Icon(
                  Icons.arrow_forward_rounded,
                  size: AppSizes.iconSm,
                  color: context.colors.onPrimary,
                ),
                type: ButtonType.primary,
                size: ButtonSize.normal,
                onPressed: onRateAndReview,
              ),
            ),
            AppSpacing.md.w,
            Expanded(
              flex: 2,
              child: AppButton(
                text: 'Book Again',
                type: ButtonType.secondaryOff,
                backgroundColor: context.colors.surfaceContainerHigh,
                foregroundColor: context.colors.onSurface,
                border: BorderSide(
                  color: context.colors.outlineVariant.withValues(alpha: 0.6),
                ),
                size: ButtonSize.normal,
                onPressed: onBookAgain,
              ),
            ),
          ],
        );

      // 2. Running State -> [Track Live Location →] & [Chat]
      case BookingStatus.onGoing:
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: AppButton(
                text: 'Track Live Location',
                trailing: Icon(
                  Icons.arrow_forward_rounded,
                  size: AppSizes.iconSm,
                  color: context.colors.onPrimary,
                ),
                type: ButtonType.primary,
                size: ButtonSize.normal,
                onPressed: onTrackLocation,
              ),
            ),
            AppSpacing.md.w,
            Expanded(
              flex: 1,
              child: AppButton(
                text: 'Chat',
                type: ButtonType.secondaryOff,
                backgroundColor: context.colors.surfaceContainerHigh,
                foregroundColor: context.colors.onSurface,
                border: BorderSide(
                  color: context.colors.outlineVariant.withValues(alpha: 0.6),
                ),
                size: ButtonSize.normal,
                onPressed: onChat,
              ),
            ),
          ],
        );

      // 3. Pending State -> [Cancel Request]
      case BookingStatus.pending:
        return AppButton(
          text: 'Cancel Request',
          type: ButtonType.secondaryOff,
          backgroundColor: context.colors.surfaceContainerHigh,
          foregroundColor: context.colors.onSurface,
          border: BorderSide(
            color: context.colors.outlineVariant.withValues(alpha: 0.6),
          ),
          size: ButtonSize.normal,
          onPressed: onCancelRequest,
        );

      case BookingStatus.confirmed:
        return Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Chat',
                type: ButtonType.primary,
                size: ButtonSize.normal,
                onPressed: onChat,
              ),
            ),
            AppSpacing.md.w,
            Expanded(
              child: AppButton(
                text: 'View Details',
                type: ButtonType.secondaryOff,
                backgroundColor: context.colors.surfaceContainerHigh,
                foregroundColor: context.colors.onSurface,
                border: BorderSide(
                  color: context.colors.outlineVariant.withValues(alpha: 0.6),
                ),
                size: ButtonSize.normal,
                onPressed: onViewDetails,
              ),
            ),
          ],
        );

      case BookingStatus.cancelled:
        return const SizedBox.shrink();
    }
  }

  /// Guard perspective action buttons
  Widget _buildGuardActions(BuildContext context) {
    switch (booking.status) {
      // 1. Pending Confirmation State -> [Accept Request] & [Reject]
      case BookingStatus.pending:
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: AppButton(
                text: 'Accept Request',
                type: ButtonType.primary,
                size: ButtonSize.normal,
                onPressed: onAccept,
              ),
            ),
            AppSpacing.md.w,
            Expanded(
              flex: 1,
              child: AppButton(
                text: 'Reject',
                type: ButtonType.secondaryOff,
                backgroundColor: context.colors.surfaceContainerHigh,
                foregroundColor: context.colors.onSurface,
                border: BorderSide(
                  color: context.colors.outlineVariant.withValues(alpha: 0.6),
                ),
                size: ButtonSize.normal,
                onPressed: onReject,
              ),
            ),
          ],
        );

      // 2. Running State -> [Chat] & [Share Location]
      case BookingStatus.onGoing:
        return Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Chat',
                type: ButtonType.primary,
                size: ButtonSize.normal,
                onPressed: onChat,
              ),
            ),
            AppSpacing.md.w,
            Expanded(
              child: AppButton(
                text: 'Share Location',
                type: ButtonType.secondaryOff,
                backgroundColor: context.colors.surfaceContainerHigh,
                foregroundColor: context.colors.onSurface,
                border: BorderSide(
                  color: context.colors.outlineVariant.withValues(alpha: 0.6),
                ),
                size: ButtonSize.normal,
                onPressed: onShareLocation,
              ),
            ),
          ],
        );

      // 3. Confirmed State -> [Chat] & [View Details]
      case BookingStatus.confirmed:
        return Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Chat',
                type: ButtonType.primary,
                size: ButtonSize.normal,
                onPressed: onChat,
              ),
            ),
            AppSpacing.md.w,
            Expanded(
              child: AppButton(
                text: 'View Details',
                type: ButtonType.secondaryOff,
                backgroundColor: context.colors.surfaceContainerHigh,
                foregroundColor: context.colors.onSurface,
                border: BorderSide(
                  color: context.colors.outlineVariant.withValues(alpha: 0.6),
                ),
                size: ButtonSize.normal,
                onPressed: onViewDetails,
              ),
            ),
          ],
        );

      // 4. Completed & Cancelled States -> No action buttons per design
      case BookingStatus.completed:
      case BookingStatus.cancelled:
        return const SizedBox.shrink();
    }
  }
}
