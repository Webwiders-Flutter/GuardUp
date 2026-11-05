import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/auth.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/enum/body_guard_status.enum.dart';
import '../../data/model/body_guard.model.dart';

/// A sleek, luxury card widget presenting a bodyguard operative in list feeds.
///
/// Features operative credentials, squircle avatar with verified badge,
/// availability status pill, hourly rate in USD, selection mode with checkbox,
/// and role-adaptive operational actions (Book Now for customer, Edit/Delete for company).
class BodyGuardCard extends StatelessWidget {
  /// The bodyguard domain entity holding user, rating, and operational data.
  final BodyGuardModel bodyguard;

  /// The perspective role governing card layout and actions.
  /// If [UserRole.customer], displays the "Book Now" action.
  /// If [UserRole.company] or [UserRole.guard], displays "Edit" and "Delete" actions.
  /// Defaults to session role from [AuthBloc] or [UserRole.company].
  final UserRole? role;

  /// Optional selection state for selectable lists.
  /// When non-null:
  /// - A checkbox is displayed in the card header.
  /// - The divider and bottom action buttons (Edit/Delete or Book Now) will NOT display.
  final bool? isSelected;

  /// Callback when the selection state changes.
  final ValueChanged<bool?>? onSelectedChanged;

  /// Optional status override. Defaults to [BodyGuardModel.status].
  final BodyGuardStatus? status;

  /// Optional specialization override. Defaults to [BodyGuardModel.clearanceLevel]
  /// or curated service type labels.
  final String? specialization;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when the [Edit] action is tapped.
  final VoidCallback? onEdit;

  /// Callback when the [Delete] action is tapped.
  final VoidCallback? onDelete;

  /// Callback when the [Book Now] action is tapped in customer view.
  final VoidCallback? onBookNow;

  const BodyGuardCard({
    super.key,
    required this.bodyguard,
    this.role,
    this.isSelected,
    this.onSelectedChanged,
    this.status,
    this.specialization,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onBookNow,
  });

  bool get _isCustomer {
    final effectiveRole =
        role ??
        (sl.isRegistered<AuthBloc>() ? sl<AuthBloc>().state.sessionRole : null);
    return effectiveRole == UserRole.customer;
  }

  @override
  Widget build(BuildContext context) {
    final showActions = isSelected == null;

    return WrapperCard(
      onTap:
          (onTap != null || (isSelected != null && onSelectedChanged != null))
          ? () {
              if (isSelected != null && onSelectedChanged != null) {
                onSelectedChanged!(!isSelected!);
              }
              onTap?.call();
            }
          : null,
      padding: AppSpacing.xl.allPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // -------------------------------------------------------------------
          // 1. Operative Header Section (Avatar, Status Pill, Details, Rate, Checkbox)
          // -------------------------------------------------------------------
          _buildHeader(context),

          if (showActions) ...[
            AppSpacing.md.h,
            Divider(color: context.colors.outline, thickness: 0.4),
            AppSpacing.sm.h,

            // -------------------------------------------------------------------
            // 2. Action Buttons (Edit & Delete for Company/Guard OR Book Now for Customer)
            // -------------------------------------------------------------------
            _buildActionButtons(context),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // SUBCOMPONENTS
  // ===========================================================================

  Widget _buildHeader(BuildContext context) {
    final avatarUrl = bodyguard.user.profileImageUrl;
    final isNetworkAvatar = avatarUrl != null && avatarUrl.startsWith('http');
    final isVerified = bodyguard.isVerified;

    final resolvedSpecialization =
        specialization ??
        bodyguard.clearanceLevel ??
        (bodyguard.serviceTypes.isNotEmpty
            ? bodyguard.serviceTypes.map((s) => s.label).take(2).join(', ')
            : 'Licensed armed, Corporate visits');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bodyguard Avatar with Verified Badge (Squircle)
        Stack(
          clipBehavior: Clip.none,
          children: [
            isNetworkAvatar
                ? AppImage.network(
                    imageUrl: avatarUrl,
                    width: 22.wPercent(context),
                    height: 12.hPercent(context),
                    fit: BoxFit.cover,
                    borderRadius: AppRadius.sm.toBorderRadius,
                  )
                : AppImage.asset(
                    assetPath: avatarUrl ?? Assets.images.profilePicture.path,
                    width: 22.wPercent(context),
                    height: 12.hPercent(context),
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
        AppSpacing.lg.w,

        // Status Badge, Bodyguard Name, Specialization, Star Rating Row
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusBadge(context),
              AppSpacing.smd.h,
              Text(
                bodyguard.user.name,
                style: context.textTheme.titleMedium?.bold(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppSpacing.xs.h,
              Text(
                resolvedSpecialization,
                style: context.textTheme.bodySmall?.colour(
                  context.colors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppSpacing.smd.h,
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: AppSizes.iconXs,
                    color: context.colors.primary,
                  ),
                  AppSpacing.xxs.w,
                  Text(
                    bodyguard.rating.toStringAsFixed(1),
                    style: context.textTheme.labelSmall,
                  ),
                  Text(
                    '  •  ',
                    style: context.textTheme.labelSmall?.regular().colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${bodyguard.reviewCount} reviews',
                    style: context.textTheme.labelSmall?.regular().colour(
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
                      '${bodyguard.experienceYears}+ yrs exp',
                      style: context.textTheme.labelSmall?.regular().colour(
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

        // Hourly Rate (e.g. "$60 /hr") and optional Checkbox
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHourlyRate(context),
            if (isSelected != null) ...[
              AppSpacing.md.w,
              _buildCheckbox(context),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    final checked = isSelected ?? false;
    return GestureDetector(
      onTap: onSelectedChanged != null
          ? () => onSelectedChanged!(!checked)
          : null,
      behavior: HitTestBehavior.opaque,
      child: QuickContainer(
        w: 22,
        h: 22,
        radius: AppRadius.sm,
        color: checked ? context.colors.primary : context.colors.transparent,
        border: Border.all(
          color: checked
              ? context.colors.primary
              : context.colors.outlineVariant,
          width: 1.5,
        ),
        alignment: Alignment.center,
        child: checked
            ? Icon(
                Icons.check_rounded,
                size: AppSizes.iconTiny,
                color: context.colors.onPrimary,
              )
            : null,
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final effectiveStatus = status ?? bodyguard.status;
    final color = effectiveStatus.badgeColor(context);
    final bgColor = effectiveStatus.badgeBackgroundColor(context);
    final borderColor = effectiveStatus.badgeBorderColor(context);

    return QuickContainer(
      radius: AppRadius.sm,
      color: bgColor,
      border: Border.all(color: borderColor, width: 1.0),
      px: AppSpacing.sm,
      py: 3.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (effectiveStatus.hasDot) ...[
            QuickContainer(
              shape: QuickContainerShape.circle,
              color: color,
              w: 6,
              h: 6,
            ),
            AppSpacing.xs.w,
          ],
          Text(
            effectiveStatus.label,
            style: context.textTheme.labelSmall?.semiBold().colour(color),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyRate(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          bodyguard.hourlyRate.toUsd,
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

  Widget _buildActionButtons(BuildContext context) {
    if (_isCustomer) {
      return Row(
        children: [
          AppButton(
            text: 'Book Now',
            type: ButtonType.primary,
            size: ButtonSize.normal,
            isFlexible: true,
            trailing: Icon(
              Icons.arrow_forward_rounded,
              size: AppSizes.iconSm,
              color: context.colors.onPrimary,
            ),
            onPressed: onBookNow,
          ),
        ],
      );
    }

    return Row(
      children: [
        // Primary Edit Button (Gold Gradient)
        Expanded(
          child: AppButton(
            text: 'Edit',
            type: ButtonType.primary,
            size: ButtonSize.normal,
            onPressed: onEdit,
          ),
        ),
        AppSpacing.md.w,

        // Danger / Destructive Delete Button (Dark Red Outlined)
        Expanded(
          child: AppButton(
            text: 'Delete',
            type: ButtonType.secondaryOff,
            backgroundColor: context.colors.error.withValues(alpha: 0.15),
            foregroundColor: context.colors.error,
            border: BorderSide(
              color: context.colors.error.withValues(alpha: 0.4),
              width: 1.0,
            ),
            size: ButtonSize.normal,
            onPressed: onDelete,
          ),
        ),
      ],
    );
  }
}
