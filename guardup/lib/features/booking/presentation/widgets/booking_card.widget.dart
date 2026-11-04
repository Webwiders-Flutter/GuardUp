import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/enum/booking_status.enum.dart';
import '../../data/model/booking.model.dart';

/// A sleek, luxury card widget presenting a bodyguard booking assignment.
///
/// Features dynamic UI adaptations according to [BookingStatus]:
/// - **Pending**: Displays "Pending Confirmation" status badge and [Accept Request] & [Reject] buttons.
/// - **Running (onGoing)**: Displays "• Running" badge with [Chat] & [Share Location] actions.
/// - **Completed**: Displays "• Completed" badge without action buttons, matching design specs.
/// - **Confirmed / Other**: Adapts status pill and contextual actions accordingly.
class BookingCard extends StatelessWidget {
  /// The booking domain model holding operative, customer, and schedule details.
  final BookingModel booking;

  /// Optional card tap callback.
  final VoidCallback? onTap;

  /// Triggered when the operative taps "Accept Request" (Pending status).
  final VoidCallback? onAccept;

  /// Triggered when the operative taps "Reject" (Pending status).
  final VoidCallback? onReject;

  /// Triggered when the operative taps "Chat" (Running/Confirmed status).
  final VoidCallback? onChat;

  /// Triggered when the operative taps "Share Location" (Running status).
  final VoidCallback? onShareLocation;

  /// Optional trigger when the operative taps "View Details".
  final VoidCallback? onViewDetails;

  /// Custom bottom action override, if specific external buttons are required.
  final Widget? customBottomAction;

  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.onChat,
    this.onShareLocation,
    this.onViewDetails,
    this.customBottomAction,
  });

  bool get _hasBottomActions {
    if (customBottomAction != null) return true;
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
          // 1. Top Section: Customer Avatar, Status Pill & Name, Hourly Rate
          // -------------------------------------------------------------------
          _buildTopHeader(context),
          AppSpacing.md.h,

          // -------------------------------------------------------------------
          // 2. Middle Section: Schedule, Location, and Booking Reference Number
          // -------------------------------------------------------------------
          _buildInfoRow(
            context: context,
            icon: Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: context.colors.onSurfaceTertiary,
            ),
            text: booking.formattedSchedule,
          ),
          AppSpacing.sm.h,
          _buildInfoRow(
            context: context,
            icon: Assets.svg.location.svg(
              width: 15,
              height: 15,
              colorFilter: ColorFilter.mode(
                context.colors.onSurfaceTertiary,
                BlendMode.srcIn,
              ),
            ),
            text: booking.pickupAddress ?? 'Yorkville Plaza, Toronto, ON',
          ),
          AppSpacing.sm.h,
          _buildInfoRow(
            context: context,
            icon: Assets.svg.docPage.svg(
              width: 15,
              height: 15,
              colorFilter: ColorFilter.mode(
                context.colors.onSurfaceTertiary,
                BlendMode.srcIn,
              ),
            ),
            text: booking.bookingNumber,
          ),

          // -------------------------------------------------------------------
          // 3. Dynamic Bottom Action Buttons (Rendered only when active)
          // -------------------------------------------------------------------
          if (_hasBottomActions) ...[
            AppSpacing.md.h,
            Divider(
              color: context.colors.outlineVariant.withValues(alpha: 0.4),
              height: 1.0,
              thickness: 1.0,
            ),
            AppSpacing.md.h,
            _buildActionButtons(context),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Header Subcomponent
  // ---------------------------------------------------------------------------
  Widget _buildTopHeader(BuildContext context) {
    final avatarUrl = booking.customer.profileImageUrl;
    final isNetworkAvatar = avatarUrl != null && avatarUrl.startsWith('http');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Circular Customer Avatar
        isNetworkAvatar
            ? AppImage.network(
                imageUrl: avatarUrl,
                width: 48,
                height: 48,
                shape: BoxShape.circle,
                fit: BoxFit.cover,
              )
            : AppImage.asset(
                assetPath: avatarUrl ?? Assets.images.profilePicture.path,
                width: 48,
                height: 48,
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
              _buildStatusBadge(context),
              AppSpacing.xxs.h,
              Text(
                booking.customer.name,
                style: context.textTheme.titleMedium?.bold(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        AppSpacing.sm.w,

        // Hourly Rate (e.g. "$60 /hr")
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '\$${booking.effectiveHourlyRate.toInt()}',
              style: context.textTheme.titleMedium?.bold().colour(
                context.colors.primary,
              ),
            ),
            Text(
              '/hr',
              style: context.textTheme.labelSmall?.colour(
                context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Status Badge Subcomponent
  // ---------------------------------------------------------------------------
  Widget _buildStatusBadge(BuildContext context) {
    final status = booking.status;
    final color = status.badgeColor(context);
    final bgColor = status.badgeBackgroundColor(context);
    final borderColor = status.badgeBorderColor(context);

    return QuickContainer(
      radius: AppRadius.full,
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

  // ---------------------------------------------------------------------------
  // Info Row Subcomponent
  // ---------------------------------------------------------------------------
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
            style: context.textTheme.bodySmall?.medium(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Dynamic Action Buttons Subcomponent
  // ---------------------------------------------------------------------------
  Widget _buildActionButtons(BuildContext context) {
    if (customBottomAction != null) {
      return customBottomAction!;
    }

    switch (booking.status) {
      // 1. Pending Confirmation State -> [Accept Request (Primary)] & [Reject (Secondary)]
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

      // 2. Running State -> [Chat (Primary)] & [Share Location (Secondary)]
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

      // 3. Confirmed State -> [Chat (Primary)] & [View Details (Secondary)]
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

