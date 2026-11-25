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
import '/shared/widgets/misc/app_rich_text.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/enum/body_guard_status.enum.dart';
import '../../data/enum/bodyguard_availability_status.enum.dart';
import '../../data/enum/guard_service.enum.dart';
import '../../data/model/body_guard.model.dart';

/// A sleek, luxury card widget presenting a bodyguard operative in list feeds.
///
/// Features operative credentials, squircle avatar with verified badge,
/// availability status pill, hourly rate in USD, selection mode with checkbox,
/// compact spotlight layout for customer home feeds, and role-adaptive actions.
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

  /// Optional availability status override. Defaults to [BodyGuardModel.availabilityStatus].
  final BodyguardAvailabilityStatus? availabilityStatus;

  /// Optional specialization override. Defaults to [BodyGuardModel.bio]
  /// or curated service type labels.
  final String? specialization;

  /// Optional list of short skill/service tags displayed in compact mode.
  final List<String>? tags;

  /// Whether to render the sleek, compact spotlight card layout
  /// (matching the home screen spotlight card).
  final bool isCompact;

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
    this.availabilityStatus,
    this.specialization,
    this.tags,
    this.isCompact = false,
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

  List<String> get _resolvedTags {
    if (tags != null && tags!.isNotEmpty) return tags!;
    if (bodyguard.serviceTypes.isNotEmpty) {
      final result = <String>[];
      for (final s in bodyguard.serviceTypes) {
        switch (s) {
          case GuardService.armedEscort:
            result.add('Armed');
          case GuardService.tacticalDriver:
            result.add('Tactical Driver');
          case GuardService.vipCloseProtection:
            result.add('Close Protection');
          case GuardService.eventSecurity:
            result.add('Event Security');
          case GuardService.residentialProtection:
            result.add('Residential');
          case GuardService.assetProtection:
            result.add('Asset Protection');
          case GuardService.surveillanceRecon:
            result.add('Recon');
          case GuardService.crisisManagement:
            result.add('Crisis Mgmt');
        }
      }
      if (result.isNotEmpty) return result.take(2).toList();
    }
    return const ['Armed', 'Tactical Driver'];
  }

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return WrapperCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _buildCompactCard(context),
      );
    }

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

          // Admin verification of a company's bodyguard (hidden once approved
          // and never shown to customers, who only see approved bodyguards).
          if (!_isCustomer &&
              bodyguard.verificationStatus != UserStatus.active) ...[
            AppSpacing.md.h,
            _buildVerificationNote(context),
          ],

          if (showActions) ...[
            AppSpacing.sm.h,
            Divider(color: context.colors.outline, thickness: 0.4),
            AppSpacing.xxs.h,

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
  // COMPACT SPOTLIGHT CARD (Customer Home Spotlight)
  // ===========================================================================

  Widget _buildCompactCard(BuildContext context) {
    final avatarUrl = bodyguard.user.profileImageUrl;
    final isNetworkAvatar = avatarUrl != null && avatarUrl.startsWith('http');
    final isVerified = bodyguard.isVerified;
    final resolvedSpecialization =
        specialization ??
        (bodyguard.bio.isNotEmpty
            ? bodyguard.bio
            : (bodyguard.qualifications ?? 'Licensed armed, Corporate visits'));
    final rateInt = bodyguard.hourlyRate.toInt();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Bodyguard Avatar (Rounded Square + Verified Check Badge at top-right)
        Stack(
          alignment: Alignment.topRight,
          clipBehavior: Clip.none,
          children: [
            QuickContainer(
              borderColor: context.colors.primary.withValues(alpha: .5),
              h: 78,
              w: 78,
              borderWidth: 0.7,
              radius: 10,
              clipBehavior: .hardEdge,
              child: isNetworkAvatar
                  ? AppImage.network(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      borderRadius: .circular(10),
                    )
                  : AppImage.asset(
                      assetPath: avatarUrl ?? Assets.images.profilePicture.path,
                      fit: BoxFit.cover,
                      borderRadius: .circular(10),
                    ),
            ),
            if (isVerified)
              Positioned(
                top: -5,
                right: -5,
                child: AppImage.svgAsset(
                  assetPath: Assets.svg.verifiedBadge.path,
                  width: 25,
                ),
              ),
          ],
        ),
        AppSpacing.md.w,

        // 2. Details Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Name and Rating Badge (aligned to right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      bodyguard.user.name,
                      style: context.textTheme.titleMedium?.bold(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppSpacing.xs.w,
                  // Rating Badge (e.g. ★ 4.9 in dark pill with gold border)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: context.colors.primary.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: context.colors.primary,
                        ),
                        AppSpacing.xxs.w,
                        Text(
                          bodyguard.rating.toStringAsFixed(1),
                          style: context.textTheme.labelSmall?.colour(
                            context.colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.xxs.h,

              // Row 2: Subtitle / Specialization in Primary Accent
              Text(
                resolvedSpecialization,
                style: context.textTheme.bodySmall
                    ?.copyWith(fontSize: 11)
                    .colour(context.colors.primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppSpacing.xs.h,

              // Row 3: Service Tags (e.g. [Armed] [Tactical Driver])
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _resolvedTags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceDim,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      border: Border.all(
                        color: context.colors.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: context.textTheme.labelSmall
                          ?.copyWith(fontSize: 9.5, height: 1)
                          .colour(context.colors.onSurfaceVariant),
                    ),
                  );
                }).toList(),
              ),
              AppSpacing.ssm.h,

              // Row 4: Hourly Rate & Book Now Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '\$$rateInt',
                        style: context.textTheme.titleMedium?.bold(),
                      ),
                      AppSpacing.xxs.w,
                      Text(
                        '/ hr',
                        style: context.textTheme.bodySmall?.colour(
                          context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: onBookNow,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: context.colors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.primary.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Book Now',
                        style: context.textTheme.labelSmall
                            ?.copyWith(fontSize: 11)
                            .colour(context.colors.onPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STANDARD FEED / ROSTER CARD
  // ===========================================================================

  Widget _buildHeader(BuildContext context) {
    final avatarUrl = bodyguard.user.profileImageUrl;
    final isNetworkAvatar = avatarUrl != null && avatarUrl.startsWith('http');
    final isVerified = bodyguard.isVerified;

    final resolvedSpecialization =
        specialization ??
        (bodyguard.bio.isNotEmpty
            ? bodyguard.bio
            : (bodyguard.serviceTypes.isNotEmpty
                ? bodyguard.serviceTypes.map((s) => s.label).take(2).join(', ')
                : (bodyguard.qualifications ?? 'Licensed armed, Corporate visits')));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bodyguard Avatar with Verified Badge (Squircle)
        Stack(
          clipBehavior: Clip.none,
          children: [
            QuickContainer(
              borderColor: context.colors.primary.withValues(alpha: .5),
              w: 22.wPercent(context),
              h: 11.hPercent(context),
              borderWidth: 0.7,
              borderRadius: AppRadius.sm.toBorderRadius,
              child: isNetworkAvatar
                  ? AppImage.network(
                      imageUrl: avatarUrl,
                      width: 22.wPercent(context),
                      height: 11.hPercent(context),
                      fit: BoxFit.cover,
                      borderRadius: AppRadius.sm.toBorderRadius,
                    )
                  : AppImage.asset(
                      assetPath: avatarUrl ?? Assets.images.profilePicture.path,
                      width: 22.wPercent(context),
                      height: 11.hPercent(context),
                      fit: BoxFit.cover,
                      borderRadius: AppRadius.sm.toBorderRadius,
                    ),
            ),

            if (isVerified)
              Positioned(
                right: -8,
                bottom: -8,
                child: AppImage.svgAsset(
                  assetPath: Assets.svg.verifiedBadge.path,
                  width: 25,
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
              Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  _buildStatusBadge(context),
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
              ),
              AppSpacing.ssm.h,
              Text(
                bodyguard.user.name,
                style: context.textTheme.titleMedium?.bold(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppSpacing.xxs.h,
              AppSpacing.xxs.h,
              Text(
                resolvedSpecialization,
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
                    bodyguard.rating.toStringAsFixed(1),
                    style: context.textTheme.labelMedium,
                  ),
                  Text(
                    '   •   ',
                    style: context.textTheme.labelMedium?.regular().colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${bodyguard.reviewCount} reviews',
                    style: context.textTheme.labelMedium?.regular().colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '   •   ',
                    style: context.textTheme.labelMedium?.colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      bodyguard.experienceYears > 0
                          ? '${bodyguard.experienceYears}+ yrs exp'
                          : '0 yrs exp',
                      style: context.textTheme.labelMedium?.regular().colour(
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

        // Hourly Rate (e.g. "$60 /hr") and optional Checkbox
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

  Widget _buildVerificationNote(BuildContext context) {
    final verification = bodyguard.verificationStatus;
    final color = verification.color(context);
    final reason = bodyguard.rejectionReason;
    final message = switch (verification) {
      UserStatus.incomplete => 'Finish the details and documents to submit for review.',
      UserStatus.pendingApproval => 'Waiting for admin approval.',
      UserStatus.rejected =>
        (reason != null && reason.isNotEmpty)
            ? reason
            : 'Some documents were rejected. Edit to review and resubmit.',
      UserStatus.blocked => 'Suspended by admin. Contact support for details.',
      _ => null,
    };

    return QuickContainer(
      radius: AppRadius.sm,
      color: color.withValues(alpha: 0.1),
      border: Border.all(color: color.withValues(alpha: 0.35), width: 1.0),
      px: AppSpacing.sm,
      py: AppSpacing.xs,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, size: AppSizes.iconSm, color: color),
          AppSpacing.xs.w,
          Expanded(
            child: AppRichText(
              spans: [
                AppTextSpan(
                  text: verification.label,
                  style: context.textTheme.labelSmall?.semiBold().colour(color),
                ),
                if (message != null)
                  AppTextSpan(
                    text: '  •  $message',
                    style: context.textTheme.labelSmall?.colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final effectiveAvailability = availabilityStatus ?? bodyguard.availabilityStatus;
    final color = effectiveAvailability.badgeColor(context);
    final bgColor = effectiveAvailability.badgeBackgroundColor(context);
    final borderColor = effectiveAvailability.badgeBorderColor(context);

    return QuickContainer(
      radius: AppRadius.sm,
      color: bgColor,
      border: Border.all(color: borderColor, width: 1.0),
      px: AppSpacing.sm,
      py: 3.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (effectiveAvailability.hasDot) ...[
            QuickContainer(
              shape: QuickContainerShape.circle,
              color: color,
              w: 6,
              h: 6,
            ),
            AppSpacing.xs.w,
          ],
          Text(
            effectiveAvailability.label,
            style: context.textTheme.labelSmall
                ?.semiBold()
                .colour(color)
                .decreaseSize(1),
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
            size: ButtonSize.small,
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
