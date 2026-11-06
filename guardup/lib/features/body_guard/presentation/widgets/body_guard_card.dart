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

  /// Optional specialization override. Defaults to [BodyGuardModel.clearanceLevel]
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

          if (showActions) ...[
            AppSpacing.md.h,
            Divider(color: context.colors.outline, thickness: 0.2),
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
  // COMPACT SPOTLIGHT CARD (Customer Home Spotlight)
  // ===========================================================================

  Widget _buildCompactCard(BuildContext context) {
    final avatarUrl = bodyguard.user.profileImageUrl;
    final isNetworkAvatar = avatarUrl != null && avatarUrl.startsWith('http');
    final isVerified = bodyguard.isVerified;
    final resolvedSpecialization =
        specialization ??
        bodyguard.clearanceLevel ??
        'Licensed armed, Corporate visits';
    final rateInt = bodyguard.hourlyRate.toInt();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Bodyguard Avatar (Rounded Square + Verified Check Badge at top-right)
        Stack(
          alignment: Alignment.topRight,
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                width: 78,
                height: 78,
                child: isNetworkAvatar
                    ? AppImage.network(imageUrl: avatarUrl, fit: BoxFit.cover)
                    : AppImage.asset(
                        assetPath:
                            avatarUrl ?? Assets.images.profilePicture.path,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            if (isVerified)
              Positioned(
                top: -3,
                right: -3,
                child: QuickContainer(
                  shape: QuickContainerShape.circle,
                  color: context.colors.primary,
                  p: 3,
                  child: Icon(
                    Icons.check_rounded,
                    size: 11,
                    color: context.colors.onPrimary,
                  ),
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
              AppSpacing.sm.h,

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
                    width: 80,
                    height: 96,
                    fit: BoxFit.cover,
                    borderRadius: AppRadius.sm.toBorderRadius,
                  )
                : AppImage.asset(
                    assetPath: avatarUrl ?? Assets.images.profilePicture.path,
                    width: 80,
                    height: 96,
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
                      '${bodyguard.experienceYears}+ yrs exp',
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
