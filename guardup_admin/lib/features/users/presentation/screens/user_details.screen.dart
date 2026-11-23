import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup_admin/shared/widgets/buttons/app_button.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/datetime.extension.dart';
import '/core/extensions/layout.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/string.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/services/launcher/app_launcher.service.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/data/models/user_model.dart';
import '/features/users/di/users.providers.dart';
import '/core/extensions/riverpod.extension.dart';
import '/features/users/data/models/user_document.model.dart';
import '/features/users/presentation/controllers/user_review.controller.dart';
import '/features/users/presentation/controllers/users.controller.dart';
import '/features/users/presentation/widgets/user_availability.section.dart';
import '/features/users/presentation/widgets/user_bank_accounts.section.dart';
import '/shared/widgets/admin_layout/app_side_panel.dart';
import '/shared/widgets/feedbacks/widgets/app_file_viewer.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_detail_section.dart';
import '/shared/widgets/sections/app_detail_tile.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/state/app_state_view.dart';
import '/features/dashboard/presentation/screens/dashboard.screen.dart';
import '/features/users/presentation/screens/users_management.screen.dart';

/// Screen displaying complete profile, KYC documents, and management options for a user.
class UserDetailsScreen extends ConsumerStatefulWidget {
  /// Route segment under [UsersManagementScreen.route].
  static const path = 'detail/:id';

  /// Location of the details page for user [id].
  static String location(String id) =>
      '${UsersManagementScreen.route}/detail/$id';

  const UserDetailsScreen({
    super.key,
    required this.userId,
    this.asSidebar = false,
  });

  final String userId;
  final bool asSidebar;

  static Future<void> showAsSidebar({
    required BuildContext context,
    required String userId,
  }) {
    return AppSidePanel.show<void>(
      context: context,
      title: 'User Details',
      subtitle: 'Full profile information, credentials and verification status',
      width: 75.wPercent(context),
      showFooter: false,
      body: UserDetailsScreen(userId: userId, asSidebar: true),
    );
  }

  @override
  ConsumerState<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends ConsumerState<UserDetailsScreen> {
  @override
  void dispose() {
    if (mounted) {
      ref.invalidate(userReviewControllerProvider(widget.userId));
      ref.invalidate(userDetailsProvider(widget.userId));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncUser = ref.watch(userDetailsProvider(widget.userId));

    final body = asyncUser.when(
      skipLoadingOnReload: true,
      loading: () => const AppStateView(type: AppViewType.loading),
      error: (error, _) => AppStateView(
        type: AppViewType.error,
        message: 'Failed to load user details',
        subtitle: error.toString(),
        actionText: 'Retry',
        onAction: () => ref.invalidate(userDetailsProvider(widget.userId)),
      ),
      data: (user) => _UserDetailsBody(user: user),
    );

    if (widget.asSidebar) {
      return SizedBox(height: context.screenHeight, child: body);
    }

    return Scaffold(
      backgroundColor: context.colors.backgroundLight,
      appBar: AppAppBar.transparent(title: 'User Details'),
      body: body,
    );
  }
}

class _UserDetailsBody extends StatelessWidget {
  const _UserDetailsBody({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // 1. User Profile Hero Card
        _UserProfileHero(user: user),
        AppSpacing.md.h,

        // 2. High-level metric snapshot ribbon
        _UserQuickStats(user: user),
        AppSpacing.lg.h,

        // 3. Personal information (every role)
        _PersonalInfoSection(user: user),
        AppSpacing.md.h,

        // 4. Role-specific Information
        if (user.role.isGuard) ...[
          _GuardDetailsSection(user: user),
          AppSpacing.md.h,
        ] else if (user.role.isCompany) ...[
          _CompanyDetailsSection(user: user),
          AppSpacing.md.h,
        ],

        // 5. Weekly availability (bodyguards, or anyone who has set one)
        if (user.role.isGuard || user.availabilities?.isNotEmpty == true) ...[
          UserAvailabilitySection(user: user),
          AppSpacing.md.h,
        ],

        // 6. Payout bank accounts (bodyguards & companies)
        if (!user.role.isCustomer) ...[
          UserBankAccountsSection(user: user),
          AppSpacing.md.h,
        ],

        // 7. Verification Documents (not applicable for customers)
        if (!user.role.isCustomer) _UserDocumentsSection(user: user),
        AppSpacing.xxxl.h,
      ],
    );
  }
}

class _PersonalInfoSection extends StatelessWidget {
  const _PersonalInfoSection({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final address = user.address ?? '';
    final latitude = user.latitude;
    final longitude = user.longitude;

    return AppDetailSection(
      title: 'Personal Information',
      subtitle: 'Gender, address and app preferences',
      icon: Icons.badge_outlined,
      items: [
        (label: 'Full Name', value: user.name, icon: Icons.person_outline),
        (
          label: 'Gender',
          value: user.gender?.label(context.l10n) ?? 'Not specified',
          icon: user.gender?.icon ?? Icons.wc_outlined,
        ),
        // (
        //   label: 'Push Notifications',
        //   value: user.isPushNotificationEnabled ? 'Enabled' : 'Disabled',
        //   icon: user.isPushNotificationEnabled
        //       ? Icons.notifications_active_outlined
        //       : Icons.notifications_off_outlined,
        // ),
        (
          label: 'Last Updated',
          value: user.updatedAt?.readableDate,
          icon: Icons.update_rounded,
        ),
      ],
      child: AppDetailTile(
        label: user.role.isCompany ? 'Registered Address' : 'Address',
        value: address.isNotBlank ? address : 'Not provided',
        icon: Icons.location_on_outlined,
        onTap: address.isBlank
            ? null
            : () => latitude != null && longitude != null
                  ? AppLauncher.openMaps(
                      latitude: latitude,
                      longitude: longitude,
                    )
                  : AppLauncher.openMapsSearch(address),
        trailing: address.isNotBlank
            ? Tooltip(
                message: 'Open in Google Maps',
                child: Icon(
                  Icons.map_outlined,
                  size: AppSpacing.md + 2,
                  color: colors.primary,
                ),
              )
            : null,
      ),
    );
  }
}

/// Titled wrap of chips (services, languages, certifications).
class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.title,
    required this.values,
    required this.color,
    this.icon,
  });

  final String title;
  final List<String> values;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.sm.h,
        Text(
          title,
          style: context.textTheme.bodySmall?.semiBold().colour(
            context.colors.onSurfaceSecondary,
          ),
        ),
        AppSpacing.xs.h,
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final value in values)
              AppChip(
                title: value,
                icon: icon,
                size: AppChipSize.small,
                color: color,
              ),
          ],
        ),
      ],
    );
  }
}

class _UserProfileHero extends StatelessWidget {
  const _UserProfileHero({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final phone = user.mobileNumber.toE164(countryCode: user.phoneCode);
    final hasPhone = phone.isNotEmpty;
    final hasEmail = user.email.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: colors.borderLight.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary.withValues(alpha: 0.08),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.25),
                        width: 2,
                      ),
                    ),
                    child: user.profileImageUrl != null
                        ? ClipOval(
                            child: AppImage(
                              type: AppImageType.network,
                              imageUrl: user.profileImageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              onTap: () {
                                
                                AppFileViewer.show(
                                  context: context,
                                  title: '${user.fullName} — Photo',
                                  fileUrl: user.profileImageUrl,
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName.characters.first.toUpperCase()
                                  : 'U',
                              style: context.textTheme.titleLarge
                                  ?.bold()
                                  .colour(colors.primary),
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs / 2),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        user.role.icon,
                        size: AppSpacing.md,
                        color: user.role.color(context),
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.md.w,

              // Name, Role, Status Badges, and ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          user.fullName,
                          style: context.textTheme.titleMedium?.bold(),
                        ),
                        AppChip(
                          color: user.role.color(context),
                          title: user.role.label(context.l10n),
                          icon: user.role.icon,
                          size: AppChipSize.small,
                        ),
                        AppChip(
                          color: user.status.color(context),
                          title: user.status.label(context.l10n),
                          icon: user.status.icon,
                          size: AppChipSize.small,
                        ),
                        // ID Copy Chip
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: user.id));
                            AppSnackbar.show(
                              message: 'User ID copied to clipboard',
                              type: SnackbarType.success,
                            );
                          },
                          borderRadius: AppRadius.fullRadius,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs / 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.backgroundLight,
                              borderRadius: AppRadius.fullRadius,
                              border: Border.all(color: colors.borderLight),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ID: #${user.id.length > 8 ? user.id.substring(0, 8) : user.id}',
                                  style: context.textTheme.bodySmall
                                      ?.semiBold()
                                      .colour(colors.onSurfaceSecondary),
                                ),
                                AppSpacing.xs.w,
                                Icon(
                                  Icons.copy_rounded,
                                  size: AppSpacing.sm + 2,
                                  color: colors.onSurfaceSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.sm.h,

                    // Contact Badges: Phone & Email
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (hasPhone)
                          InkWell(
                            onTap: () => AppLauncher.callPhone(phone),
                            borderRadius: AppRadius.xsRadius,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.phone_in_talk_outlined,
                                  size: AppSpacing.md,
                                  color: colors.primary,
                                ),
                                AppSpacing.xs.w,
                                Text(
                                  phone,
                                  style: context.textTheme.bodyMedium
                                      ?.semiBold()
                                      .colour(colors.primary),
                                ),
                                AppSpacing.xs.w,
                                InkWell(
                                  onTap: () =>
                                      AppLauncher.openWhatsApp(phone: phone),
                                  borderRadius: AppRadius.roundRadius,
                                  child: Icon(
                                    Icons.chat_outlined,
                                    size: AppSpacing.md,
                                    color: colors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (hasEmail)
                          InkWell(
                            onTap: () =>
                                AppLauncher.sendEmail(email: user.email),
                            borderRadius: AppRadius.xsRadius,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: AppSpacing.md,
                                  color: colors.primary,
                                ),
                                AppSpacing.xs.w,
                                Text(
                                  user.email,
                                  style: context.textTheme.bodyMedium
                                      ?.semiBold()
                                      .colour(colors.primary),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.rejectionReason?.trim().isNotEmpty == true) ...[
            AppSpacing.md.h,
            _RejectionReasonNote(
              label: 'Profile rejection reason',
              reason: user.rejectionReason!,
            ),
          ],
          if (!user.status.isRejected) ...[
            AppSpacing.md.h,
            Divider(
              color: colors.borderLight.withValues(alpha: 0.6),
              height: 1,
            ),
            AppSpacing.md.h,
          ],

          // Actions Bar: Approve / Reject profile, Block/Unblock, Delete
          _UserActionsBar(user: user),
        ],
      ),
    );
  }
}

class _UserQuickStats extends StatelessWidget {
  const _UserQuickStats({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final docsCount = user.documents?.length ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Platform Role',
            value: user.role.label(context.l10n),
            icon: user.role.icon,
            accentColor: user.role.color(context),
          ),
        ),
        AppSpacing.sm.w,
        Expanded(
          child: _StatCard(
            label: 'Account Status',
            value: user.status.label(context.l10n),
            icon: user.status.icon,
            accentColor: user.status.color(context),
          ),
        ),
        if (!user.role.isCustomer) ...[
          AppSpacing.sm.w,
          Expanded(
            child: _StatCard(
              label: 'Documents',
              value: '$docsCount Submitted',
              icon: Icons.description_outlined,
              accentColor: colors.primary,
            ),
          ),
        ],
        AppSpacing.sm.w,
        Expanded(
          child: _StatCard(
            label: 'Registered On',
            value: user.createdAt?.readableDate ?? '—',
            icon: Icons.calendar_today_outlined,
            accentColor: colors.secondary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: colors.borderLight.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.smRadius,
            ),
            child: Icon(icon, size: AppSpacing.md + 2, color: accentColor),
          ),
          AppSpacing.sm.w,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: context.textTheme.bodySmall
                      ?.size(11)
                      .colour(colors.onSurfaceSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                (AppSpacing.xs / 2).h,
                Text(
                  value,
                  style: context.textTheme.bodyMedium?.bold().size(13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserActionsBar extends ConsumerStatefulWidget {
  const _UserActionsBar({required this.user});

  final UserModel user;

  @override
  ConsumerState<_UserActionsBar> createState() => _UserActionsBarState();
}

class _UserActionsBarState extends ConsumerState<_UserActionsBar> {
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);

  ({UserRoleType role, UserStatus status}) get _params =>
      (role: widget.user.role, status: widget.user.status);

  UsersController get _controller =>
      ref.read(usersControllerProvider(_params).notifier);

  @override
  void dispose() {
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  UserReviewController get _reviewController =>
      ref.read(userReviewControllerProvider(widget.user.id).notifier);

  /// Shown only once every document is approved.
  Future<void> _onApproveProfile() async {
    await _reviewController.approveUser();
    if (mounted) {
      ref
          .read(userReviewControllerProvider(widget.user.id))
          .handleResult(
            successMessage:
                '${widget.user.fullName} has been approved successfully',
            fallbackErrorMessage: 'Failed to approve user',
          );
    }
  }

  /// Rejects the profile with a reason (stored on the user). The user stays
  /// in the system with status REJECTED and is notified.
  Future<void> _onRejectProfile() async {
    final result = await AppPopup.showRejectWithReason(
      context,
      title: 'Reject ${widget.user.fullName}',
      message:
          'The user will be notified with this reason. Their account is kept.',
      confirmLabel: 'Reject Profile',
    );
    final reason = result?.data;
    if (result?.action != PopupAction.confirm || reason == null || !mounted) {
      return;
    }

    await _reviewController.rejectUser(reason);
    if (mounted) {
      ref
          .read(userReviewControllerProvider(widget.user.id))
          .handleResult(
            successMessage: '${widget.user.fullName} has been rejected',
            fallbackErrorMessage: 'Failed to reject user',
          );
    }
  }

  Future<void> _onToggleBlock(bool block) async {
    final result = block
        ? await AppPopup.showBlockConfirmation(
            context,
            itemName: widget.user.fullName,
          )
        : await AppPopup.showUnblockConfirmation(
            context,
            itemName: widget.user.fullName,
          );

    if (result?.action == PopupAction.confirm && mounted) {
      _isLoadingNotifier.value = true;
      try {
        await _controller.toggleBlock(widget.user.id, block);

        if (mounted) {
          ref.invalidate(userDetailsProvider(widget.user.id));
          AppSnackbar.show(
            message: block
                ? '${widget.user.fullName} has been blocked'
                : '${widget.user.fullName} has been unblocked',
            type: block ? SnackbarType.error : SnackbarType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.show(
            message: 'Failed to update user status: $e',
            type: SnackbarType.error,
          );
        }
      } finally {
        _isLoadingNotifier.value = false;
      }
    }
  }

  Future<void> _onDelete() async {
    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName: widget.user.fullName,
    );

    if (result?.action == PopupAction.confirm && mounted) {
      _isLoadingNotifier.value = true;
      try {
        await _controller.deleteRecord(widget.user.id);

        if (mounted) {
          AppSnackbar.show(
            message: '${widget.user.fullName} deleted successfully',
            type: SnackbarType.success,
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go(DashboardScreen.route);
          }
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.show(
            message: 'Failed to delete user: $e',
            type: SnackbarType.error,
          );
        }
      } finally {
        _isLoadingNotifier.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = widget.user.status.isApproved;
    final isBlocked = widget.user.status.isBlocked;
    final allDocumentsApproved = (widget.user.documents ?? const []).every(
      (doc) => doc.verificationStatus.isVerified,
    );
    final isReviewing = ref
        .watch(userReviewControllerProvider(widget.user.id))
        .isLoading;

    return ValueListenableBuilder<bool>(
      valueListenable: _isLoadingNotifier,
      builder: (context, isLoading, _) {
        final isBusy = isLoading || isReviewing;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (isApproved || isBlocked) ...[
              // 1. Block / Unblock Button
              AppButton.outline(
                text: isBlocked ? 'Unblock User' : 'Block User',
                type: isBlocked ? .success : .warning,
                size: .small,
                fullWidth: false,
                onPressed: isBusy ? null : () => _onToggleBlock(!isBlocked),
                trailing: Icon(
                  isBlocked ? Icons.lock_open_rounded : Icons.block_outlined,
                  size: 16,
                ),
              ),

              // 2. Delete Button
              AppButton.outline(
                text: 'Delete User',
                type: .danger,
                size: .small,
                fullWidth: false,
                onPressed: isBusy ? null : _onDelete,
                trailing: const Icon(Icons.delete_outline_rounded, size: 16),
              ),
            ] else if (widget.user.status.isPendingApproval) ...[
              // 1. Approve Profile: only once every document is approved
              AppButton.outline(
                text: 'Approve Profile',
                tooltip: !allDocumentsApproved
                    ? 'All documents must be approved before approving the profile'
                    : 'Approve profile',
                type: .success,
                size: .small,
                fullWidth: false,
                onPressed: isBusy || !allDocumentsApproved
                    ? null
                    : _onApproveProfile,
                trailing: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                ),
              ),

              // 2. Reject Profile (asks for a reason)
              AppButton.outline(
                text: 'Reject Profile',
                type: .danger,
                size: .small,
                fullWidth: false,
                onPressed: isBusy ? null : _onRejectProfile,
                trailing: const Icon(Icons.cancel_outlined, size: 16),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GuardDetailsSection extends StatelessWidget {
  const _GuardDetailsSection({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bio = user.bio?.trim();
    final languages = user.languages?.toCommaSeparatedList ?? const [];
    final certifications =
        user.certifications?.toCommaSeparatedList ?? const [];
    final experienceYears = user.experienceYears ?? 0;
    final hasChips =
        user.services.isNotEmpty ||
        languages.isNotEmpty ||
        certifications.isNotEmpty;

    return AppDetailSection(
      title: 'Bodyguard Operative Details',
      subtitle: 'Rates, experience, skills and professional bio',
      icon: Icons.security_outlined,
      items: [
        (
          label: 'Hourly Rate',
          value: (user.hourlyRate ?? 0) > 0
              ? '${user.hourlyRate!.toUsdAmount} / hr'
              : 'Not set',
          icon: Icons.attach_money_rounded,
        ),
        (
          label: 'Rating',
          value: user.rating != null && user.rating! > 0
              ? '★ ${user.rating!.toStringAsFixed(1)}'
              : '0.0 (New)',
          icon: Icons.star_rate_rounded,
        ),
        (
          label: 'Experience',
          value: experienceYears > 0
              ? '$experienceYears ${experienceYears == 1 ? 'year' : 'years'}'
              : 'Less than a year',
          icon: Icons.workspace_premium_outlined,
        ),
        if (bio != null && bio.isNotEmpty)
          (label: 'Bio', value: bio, icon: Icons.description_outlined),
      ],
      child: hasChips
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.services.isNotEmpty)
                  _ChipGroup(
                    title: 'Services & Specializations',
                    values: user.services,
                    color: colors.primary,
                  ),
                if (languages.isNotEmpty)
                  _ChipGroup(
                    title: 'Languages',
                    values: languages,
                    color: colors.info,
                    icon: Icons.translate_rounded,
                  ),
                if (certifications.isNotEmpty)
                  _ChipGroup(
                    title: 'Certifications & Licenses',
                    values: certifications,
                    color: colors.success,
                    icon: Icons.verified_outlined,
                  ),
              ],
            )
          : null,
    );
  }
}

class _CompanyDetailsSection extends StatelessWidget {
  const _CompanyDetailsSection({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final businessEmail = user.businessEmail ?? '';
    final email = businessEmail.isNotBlank ? businessEmail : user.email;
    final contactPhone = user.mobileNumber.toE164(countryCode: user.phoneCode);
    final companyPhone = (user.companyPhoneNumber ?? '').toE164(
      countryCode: user.companyPhoneCode,
    );

    return AppDetailSection(
      title: 'Security Company Details',
      subtitle: 'Corporate registration and business contacts',
      icon: Icons.business_outlined,
      items: [
        (
          label: 'Company Name',
          value: user.companyName ?? user.fullName,
          icon: Icons.business_outlined,
        ),
        (
          label: 'Company Type',
          value: user.companyType?.label(context.l10n) ?? '—',
          icon: user.companyType?.icon ?? Icons.category_outlined,
        ),
        (label: 'Contact Person', value: user.name, icon: Icons.person_outline),
        (
          label: 'Contact Person Phone',
          value: contactPhone.isNotEmpty ? contactPhone : '—',
          icon: Icons.phone_outlined,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDetailTile(
            label: 'Company Phone',
            value: companyPhone.isNotEmpty ? companyPhone : '—',
            icon: Icons.phone_in_talk_outlined,
            onTap: companyPhone.isNotEmpty
                ? () => AppLauncher.callPhone(companyPhone)
                : null,
            isCopyable: companyPhone.isNotEmpty,
          ),
          AppDetailTile(
            label: 'Business Email',
            value: email,
            icon: Icons.email_outlined,
            onTap: () => AppLauncher.sendEmail(email: email),
            isCopyable: true,
          ),
          if (user.services.isNotEmpty)
            _ChipGroup(
              title: 'Offered Services & Capabilities',
              values: user.services,
              color: colors.primary,
            ),
        ],
      ),
    );
  }
}

class _UserDocumentsSection extends ConsumerWidget {
  const _UserDocumentsSection({required this.user});

  final UserModel user;

  Future<void> _onApproveDocument(
    BuildContext context,
    WidgetRef ref,
    UserDocumentModel doc,
    String title,
  ) async {
    await ref
        .read(userReviewControllerProvider(user.id).notifier)
        .approveDocument(doc.id);
    if (context.mounted) {
      ref
          .read(userReviewControllerProvider(user.id))
          .handleResult(
            successMessage: '$title approved',
            fallbackErrorMessage: 'Failed to approve document',
          );
    }
  }

  /// Rejecting any document also moves the user to REJECTED.
  Future<void> _onRejectDocument(
    BuildContext context,
    WidgetRef ref,
    UserDocumentModel doc,
    String title,
  ) async {
    final result = await AppPopup.showRejectWithReason(
      context,
      title: 'Reject $title',
      message:
          'The reason is saved on this document. Rejecting a document also '
          'rejects ${user.fullName}\'s profile.',
      confirmLabel: 'Reject Document',
    );
    final reason = result?.data;
    if (result?.action != PopupAction.confirm ||
        reason == null ||
        !context.mounted) {
      return;
    }

    await ref
        .read(userReviewControllerProvider(user.id).notifier)
        .rejectDocument(doc.id, reason);
    if (context.mounted) {
      ref
          .read(userReviewControllerProvider(user.id))
          .handleResult(
            successMessage: '$title rejected',
            fallbackErrorMessage: 'Failed to reject document',
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final docs = user.documents ?? [];
    final canReview = user.status.isUnderReview;
    final isReviewing = ref
        .watch(userReviewControllerProvider(user.id))
        .isLoading;

    if (docs.isEmpty) {
      return AppDetailSection(
        title: 'Verification Documents',
        subtitle: 'No documents submitted yet',
        icon: Icons.folder_outlined,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            'User has not uploaded any verification credentials yet.',
            style: context.textTheme.bodyMedium?.colour(
              colors.onSurfaceSecondary,
            ),
          ),
        ),
      );
    }

    return AppDetailSection(
      title: 'Verification Documents',
      subtitle: '${docs.length} submitted credentials and licenses',
      icon: Icons.folder_shared_outlined,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: docs.length,
        separatorBuilder: (_, _) => AppSpacing.sm.h,
        itemBuilder: (context, index) {
          final doc = docs[index];
          final docName = doc.resolvedDocumentName;
          final title = docName?.isNotEmpty == true
              ? docName!
              : (doc.fileName?.isNotEmpty == true
                    ? doc.fileName!
                    : (doc.documentTypeId ?? 'Document #${index + 1}'));
          final subtitle = docName?.isNotEmpty == true
              ? (doc.fileName ?? doc.documentTypeId)
              : doc.documentTypeId;

          final isApproved = doc.verificationStatus.isVerified;
          final isRejected = doc.verificationStatus.isRejected;

          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.backgroundLight,
              borderRadius: AppRadius.smRadius,
              border: Border.all(color: colors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: AppRadius.xsRadius,
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                AppSpacing.md.w,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.bodyMedium?.bold(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        (AppSpacing.xs / 2).h,
                        Text(
                          subtitle,
                          style: context.textTheme.bodySmall?.colour(
                            colors.onSurfaceSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (doc.uploadedAt != null || doc.validTill != null) ...[
                        AppSpacing.xs.h,
                        _DocumentDates(doc: doc),
                      ],
                      if (doc.rejectionReason?.trim().isNotEmpty == true) ...[
                        AppSpacing.xs.h,
                        _RejectionReasonNote(
                          label: 'Rejection reason',
                          reason: doc.rejectionReason!,
                        ),
                      ],
                    ],
                  ),
                ),
                AppSpacing.md.w,

                // Status Badge
                AppChip(
                  title: doc.verificationStatus.label(),
                  color: doc.verificationStatus.color(context),
                  size: AppChipSize.small,
                ),
                AppSpacing.sm.w,

                // Review Actions (only while the application is under review)
                if (canReview && !isRejected && !isApproved) ...[
                  AppButton.outline(
                    size: .small,
                    type: .success,
                    tooltip: 'Approve Document',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: isReviewing
                        ? null
                        : () => _onApproveDocument(context, ref, doc, title),
                  ),
                  AppSpacing.xs.w,
                  AppButton.outline(
                    size: .small,
                    type: .danger,
                    tooltip: 'Reject Document',
                    icon: Icons.cancel_outlined,
                    onPressed: isReviewing
                        ? null
                        : () => _onRejectDocument(context, ref, doc, title),
                  ),
                  AppSpacing.xs.w,
                ],

                // Preview File Action
                AppButton.outline(
                  size: .small,
                  type: .primary,
                  tooltip: 'View Document',
                  icon: Icons.visibility_outlined,
                  onPressed: () {
                    if (doc.fileUrl.isNotEmpty) {
                      AppFileViewer.show(
                        context: context,
                        title: title,
                        fileUrl: doc.fileUrl,
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Upload date and expiry (`valid_till`) of a document; expired ones are
/// flagged in red.
class _DocumentDates extends StatelessWidget {
  const _DocumentDates({required this.doc});

  final UserDocumentModel doc;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final metaStyle = context.textTheme.bodySmall?.colour(
      colors.onSurfaceSecondary,
    );
    final uploadedAt = doc.uploadedAt;
    final validTill = doc.validTill;
    final isExpired =
        validTill != null && validTill.isBefore(DateTime.now().startOfDay);

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (uploadedAt != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.upload_file_outlined,
                size: AppSpacing.md - 2,
                color: colors.onSurfaceSecondary,
              ),
              (AppSpacing.xs / 2).w,
              Text('Uploaded ${uploadedAt.readableDate}', style: metaStyle),
            ],
          ),
        if (validTill != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_outlined,
                size: AppSpacing.md - 2,
                color: isExpired ? colors.error : colors.onSurfaceSecondary,
              ),
              (AppSpacing.xs / 2).w,
              Text(
                'Valid till ${validTill.readableDate}',
                style: isExpired
                    ? context.textTheme.bodySmall?.semiBold().colour(
                        colors.error,
                      )
                    : metaStyle,
              ),
              if (isExpired) ...[
                AppSpacing.xs.w,
                AppChip(
                  title: 'Expired',
                  color: colors.error,
                  size: AppChipSize.small,
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// Highlighted rejection reason (profile or document).
class _RejectionReasonNote extends StatelessWidget {
  const _RejectionReasonNote({required this.label, required this.reason});

  final String label;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.06),
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: colors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: colors.error),
          AppSpacing.xs.w,
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: context.textTheme.bodySmall?.semiBold().colour(
                      colors.error,
                    ),
                  ),
                  TextSpan(
                    text: reason,
                    style: context.textTheme.bodySmall?.colour(
                      colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
