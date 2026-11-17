import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/datetime.extension.dart';
import '/core/extensions/layout.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/services/launcher/app_launcher.service.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/data/models/user_model.dart';
import '/features/users/di/users.providers.dart';
import '/features/users/presentation/controllers/users.controller.dart';
import '/shared/widgets/admin_layout/app_side_panel.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_file_preview.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_detail_section.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/state/app_state_view.dart';

/// Screen displaying complete profile, KYC documents, and management options for a user.
class UserDetailsScreen extends ConsumerStatefulWidget {
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

        // 3. Role-specific Information
        if (user.isGuard) ...[
          _GuardDetailsSection(user: user),
          AppSpacing.md.h,
        ] else if (user.isCompany) ...[
          _CompanyDetailsSection(user: user),
          AppSpacing.md.h,
        ],

        // 4. Verification Documents (not applicable for customers)
        if (!user.isCustomer) ...[
          _UserDocumentsSection(user: user),
          AppSpacing.xxxl.h,
        ],
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
    final phone = user.displayPhone;
    final hasPhone = user.phoneNumber?.trim().isNotEmpty == true;
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
                                AppFilePreviewSheet.showDialog(
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
          AppSpacing.md.h,
          Divider(color: colors.borderLight.withValues(alpha: 0.6), height: 1),
          AppSpacing.md.h,

          // Actions Bar: Approve, Block/Unblock, Delete
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
        if (!user.isCustomer) ...[
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

  Future<void> _onApprove() async {
    // [COMING SOON GUARD] - Remove this block when ready to enable operation
    AppSnackbar.show(
      message: 'Approve user is coming soon',
      type: SnackbarType.info,
    );
    return;

    _isLoadingNotifier.value = true;
    try {
      await _controller.markVerified(widget.user.id);
      if (mounted) {
        ref.invalidate(userDetailsProvider(widget.user.id));
        AppSnackbar.show(
          message: '${widget.user.fullName} has been approved successfully',
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          message: 'Failed to approve user: $e',
          type: SnackbarType.error,
        );
      }
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  Future<void> _onReject() async {
    // [COMING SOON GUARD] - Remove this block when ready to enable operation
    AppSnackbar.show(
      message: 'Reject user is coming soon',
      type: SnackbarType.info,
    );
    return;

    final result = await AppPopup.showRejectConfirmation(
      context,
      itemName: widget.user.fullName,
    );

    if (result?.action == PopupAction.confirm && mounted) {
      _isLoadingNotifier.value = true;
      try {
        await _controller.rejectUser(widget.user.id);
        if (mounted) {
          ref.invalidate(userDetailsProvider(widget.user.id));
          AppSnackbar.show(
            message: '${widget.user.fullName} has been rejected',
            type: SnackbarType.warning,
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.show(
            message: 'Failed to reject user: $e',
            type: SnackbarType.error,
          );
        }
      } finally {
        _isLoadingNotifier.value = false;
      }
    }
  }

  Future<void> _onToggleBlock(bool block) async {
    // [COMING SOON GUARD] - Remove this block when ready to enable operation
    AppSnackbar.show(
      message: '${block ? 'Block' : 'Unblock'} user is coming soon',
      type: SnackbarType.info,
    );
    return;

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
    // [COMING SOON GUARD] - Remove this block when ready to enable operation
    AppSnackbar.show(
      message: 'Delete user is coming soon',
      type: SnackbarType.info,
    );
    return;

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
            context.go(AppRoutes.home);
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
    final colors = context.colors;
    final isApproved = widget.user.isApproved;
    final isBlocked = widget.user.isBlocked;

    return ValueListenableBuilder<bool>(
      valueListenable: _isLoadingNotifier,
      builder: (context, isLoading, _) {
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (isApproved || isBlocked) ...[
              // 1. Block / Unblock Button
              OutlinedButton.icon(
                onPressed: isLoading ? null : () => _onToggleBlock(!isBlocked),
                icon: Icon(
                  isBlocked ? Icons.lock_open_rounded : Icons.block_outlined,
                  size: 16,
                  color: isBlocked ? colors.success : colors.warning,
                ),
                label: Text(
                  isBlocked ? 'Unblock User' : 'Block User',
                  style: context.textTheme.bodySmall?.semiBold().colour(
                    isBlocked ? colors.success : colors.warning,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isBlocked ? colors.success : colors.warning,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
                ),
              ),

              // 2. Delete Button
              OutlinedButton.icon(
                onPressed: isLoading ? null : _onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: colors.error,
                ),
                label: Text(
                  'Delete User',
                  style: context.textTheme.bodySmall?.semiBold().colour(
                    colors.error,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.error),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
                ),
              ),
            ] else ...[
              // 1. Approve User Button
              AppButton(
                text: 'Approve User',
                leading: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                ),
                isLoading: isLoading,
                onPressed: _onApprove,
              ),

              // 2. Reject User Button
              OutlinedButton.icon(
                onPressed: isLoading ? null : _onReject,
                icon: Icon(
                  Icons.cancel_outlined,
                  size: 16,
                  color: colors.error,
                ),
                label: Text(
                  'Reject User',
                  style: context.textTheme.bodySmall?.semiBold().colour(
                    colors.error,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.error),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
                ),
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
    return AppDetailSection(
      title: 'Bodyguard Operative Details',
      subtitle: 'Rates, ratings, professional bio and specialized skills',
      icon: Icons.security_outlined,
      items: [
        (
          label: 'Hourly Rate',
          value: user.hourlyRate != null
              ? '\$${user.hourlyRate!.toStringAsFixed(2)} / hr'
              : 'Not set',
          icon: Icons.attach_money_rounded,
        ),
        (
          label: 'Rating',
          value: user.rating != null
              ? '★ ${user.rating!.toStringAsFixed(1)}'
              : '0.0 (New)',
          icon: Icons.star_rate_rounded,
        ),
        if (user.bio != null && user.bio!.trim().isNotEmpty)
          (label: 'Bio', value: user.bio!, icon: Icons.description_outlined),
      ],
      child: user.services != null && user.services!.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.sm.h,
                Text(
                  'Services & Specializations',
                  style: context.textTheme.bodySmall?.semiBold().colour(
                    context.colors.onSurfaceSecondary,
                  ),
                ),
                AppSpacing.xs.h,
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: user.services!
                      .map(
                        (s) => AppChip(
                          title: s,
                          size: AppChipSize.small,
                          color: context.colors.primary,
                        ),
                      )
                      .toList(),
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
          label: 'Business Email',
          value: user.businessEmail ?? user.email,
          icon: Icons.email_outlined,
        ),
        (
          label: 'Company Type',
          value: user.displayCompanyType,
          icon: Icons.category_outlined,
        ),
        (
          label: 'Contact Phone',
          value: user.displayPhone,
          icon: Icons.phone_outlined,
        ),
      ],
    );
  }
}

class _UserDocumentsSection extends StatelessWidget {
  const _UserDocumentsSection({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final docs = user.documents ?? [];

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
          final title =
              doc.fileName ?? doc.documentTypeId ?? 'Document #${index + 1}';

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
                      if (doc.documentTypeId != null) ...[
                        (AppSpacing.xs / 2).h,
                        Text(
                          doc.documentTypeId!,
                          style: context.textTheme.bodySmall?.colour(
                            colors.onSurfaceSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AppSpacing.md.w,

                // Status Badge
                // AppChip(
                //   title: doc.verificationStatus.label(),
                //   color: doc.verificationStatus.color(context),
                //   size: AppChipSize.small,
                // ),
                AppSpacing.sm.w,

                // Preview File Action
                IconButton(
                  tooltip: 'View Document',
                  icon: Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: colors.primary,
                  ),
                  onPressed: () {
                    if (doc.fileUrl.isNotEmpty) {
                      AppFilePreviewSheet.showDialog(
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
