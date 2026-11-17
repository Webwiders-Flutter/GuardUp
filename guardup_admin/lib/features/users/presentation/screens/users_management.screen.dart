import 'package:guardup_admin/features/users/presentation/controllers/users.controller.dart';
import 'package:guardup_admin/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import 'package:guardup_admin/shared/widgets/table/table_models.dart';
import 'package:flutter_riverpod/misc.dart';

import '/features/users/presentation/screens/user_details.screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/riverpod.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/data/models/user_model.dart';
import '/features/users/di/users.providers.dart';
import '/shared/states/pagination.state.dart';
import '../../../../shared/widgets/feedbacks/widgets/app_file_preview.dart';
import '../../../../shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/table/admin_table_builder.dart';

class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({
    super.key,
    required this.role,
    required this.status,
  });

  final UserRoleType role;
  final UserStatus status;

  @override
  ConsumerState<UsersManagementScreen> createState() =>
      _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen> {
  late final TextEditingController _searchController;

  ProviderListenable<AsyncValue<PaginationState<UserModel>>> get provider =>
      usersControllerProvider((role: widget.role, status: widget.status));
  UsersController get controller => ref.read(
    usersControllerProvider((role: widget.role, status: widget.status))
        .notifier,
  );

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onVerifyUser(UserModel item) async {
    AppSnackbar.info('Comming soon');
    // await controller.markVerified(item.id);
    // if (mounted) {
    //   ref
    //       .read(provider)
    //       .handleResult(
    //         successMessage: '${item.fullName} has been verified',
    //         fallbackErrorMessage: 'Failed to verify user',
    //       );
    // }
  }

  Future<void> _onViewUser(UserModel item) async {
    // context.push(AppRoutes.userDetail(id: item.id));
    UserDetailsScreen.showAsSidebar(context: context, userId: item.id);
  }

  Future<void> _onRejectUser(UserModel item) async {
    AppSnackbar.info('Comming soon');
    // final result = await AppPopup.showRejectConfirmation(
    //   context,
    //   itemName: item.fullName,
    //   alsoDelete: true,
    // );
    //
    // if (result?.action == PopupAction.confirm && mounted) {
    //   await controller.deleteRecord(item.id);
    //
    //   if (mounted) {
    //     ref
    //         .read(provider)
    //         .handleResult(
    //           successMessage: 'User rejected and deleted successfully',
    //           fallbackErrorMessage: 'Failed to reject user',
    //         );
    //   }
    // }
  }

  Future<void> _onToggleBlock(UserModel item, bool block) async {
    AppSnackbar.info('Comming soon');
    // final result = block
    //     ? await AppPopup.showBlockConfirmation(context, itemName: item.fullName)
    //     : await AppPopup.showUnblockConfirmation(
    //         context,
    //         itemName: item.fullName,
    //       );
    //
    // if (result?.action == PopupAction.confirm && mounted) {
    //   await controller.toggleBlock(item.id, block);
    //
    //   if (mounted) {
    //     ref
    //         .read(provider)
    //         .handleResult(
    //           successMessage: block
    //               ? '${item.fullName} has been blocked'
    //               : '${item.fullName} has been unblocked',
    //           fallbackErrorMessage: 'Failed to update user status',
    //         );
    //   }
    // }
  }

  Future<void> _onDeleteUser(UserModel item) async {
    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName: item.fullName,
    );

    if (result?.action == PopupAction.confirm && mounted) {
      await controller.deleteRecord(item.id);

      if (mounted) {
        ref
            .read(provider)
            .handleResult(
              successMessage: 'User deleted successfully',
              fallbackErrorMessage: 'Failed to delete user',
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final asyncState = ref.watch(provider);
    final paginationState =
        asyncState.value ?? const PaginationState<UserModel>();

    ref.listen(provider, (previous, next) {
      next.showErrorSnackbar(fallbackErrorMessage: 'Failed to load Users');
    });

    final columns = <TableColumn<UserModel>>[
      TableColumn<UserModel>(
        title: '#',
        width: AppSpacing.xxxl + AppSpacing.lg,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return Text(
            (paginationState.pageSize * (paginationState.page - 1) + index + 1)
                .toString(),
            style: context.textTheme.bodyMedium
                ?.decreaseSize(1)
                .medium()
                .colour(colors.onSurfaceSecondary),
            textAlign: TextAlign.center,
          );
        },
      ),
      TableColumn<UserModel>(
        title: 'Profile',
        width: AppSpacing.xxxl * 2 + AppSpacing.md,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return AppImage.network(
            key: ValueKey(
              '${item.id}_${item.profileImageUrl}_${item.updatedAt}',
            ),
            imageUrl: item.profileImageUrl,
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(AppRadius.full),
            fit: BoxFit.cover,
            onTap:
                item.profileImageUrl != null && item.profileImageUrl!.isNotEmpty
                ? () {
                    AppFilePreviewSheet.showDialog(
                      context: context,
                      title: '${item.fullName} — Profile Photo',
                      fileUrl: item.profileImageUrl,
                    );
                  }
                : null,
            errorWidget: QuickContainer(
              w: 48,
              h: 48,
              radius: AppRadius.full,
              color: widget.role.color(context).withValues(alpha: 0.12),
              alignment: Alignment.center,
              child: Icon(
                widget.role.icon,
                size: 20,
                color: widget.role.color(context),
              ),
            ),
          );
        },
      ),
      TableColumn<UserModel>(
        title: 'User Details',
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          return Text(
            item.fullName,
            style: context.textTheme.bodyMedium?.decreaseSize(1).semiBold(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
      TableColumn<UserModel>(
        title: 'Email',
        width: AppSpacing.xxxl * 9,
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          final hasEmail = item.email.trim().isNotEmpty;
          return Text(
            hasEmail ? item.email : '—',
            style: context.textTheme.bodyMedium
                ?.decreaseSize(1)
                .semiBold()
                .colour(
                  hasEmail ? colors.onSurface : colors.onSurfaceSecondary,
                ),
            maxLines: 1,
            // overflow: TextOverflow.ellipsis,
          );
        },
      ),
      TableColumn<UserModel>(
        title: 'Phone Number',
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          final phone = '${item.phoneCode} ${item.mobileNumber}';
          return Text(
            phone.trim().isNotEmpty ? phone : '—',
            style: context.textTheme.bodyMedium?.decreaseSize(1).semiBold(),
            maxLines: 1,
          );
        },
      ),
      TableColumn<UserModel>(
        title: 'Role',
        width: AppSpacing.xxxl * 4 + AppSpacing.lg,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return AppChip(
            color: item.role.color(context),
            title: item.role.label(context.l10n),
            icon: item.role.icon,
            size: AppChipSize.small,
          );
        },
      ),
      TableColumn<UserModel>(
        title: 'Status',
        width: AppSpacing.xxxl * 4,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return AppChip(
            color: item.registrationStatus.color(context),
            title: item.registrationStatus.label(context.l10n),
            icon: item.registrationStatus.icon,
            size: AppChipSize.small,
          );
        },
      ),
      TableColumn<UserModel>(
        title: 'Actions',
        width: AppSpacing.xxxl * 4,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          final isPending =
              item.registrationStatus == UserStatus.approvalPending;
          final isVerified = item.registrationStatus == UserStatus.active;
          final isBlocked = item.registrationStatus == UserStatus.blocked;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isPending) ...[
                // Verify button
                Tooltip(
                  message: 'Verify User',
                  child: InkWell(
                    onTap: () => _onVerifyUser(item),
                    borderRadius: AppRadius.smRadius,
                    child: QuickContainer(
                      p: AppSpacing.xs + 2,
                      radius: AppRadius.sm,
                      color: colors.success.withValues(alpha: 0.1),
                      border: Border.all(
                        color: colors.success.withValues(alpha: 0.3),
                      ),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        size: AppSpacing.lg,
                        color: colors.success,
                      ),
                    ),
                  ),
                ),
                AppSpacing.xs.w,
                // Reject button (deletes user)
                Tooltip(
                  message: 'Reject & Delete User',
                  child: InkWell(
                    onTap: () => _onRejectUser(item),
                    borderRadius: AppRadius.smRadius,
                    child: QuickContainer(
                      p: AppSpacing.xs + 2,
                      radius: AppRadius.sm,
                      color: colors.error.withValues(alpha: 0.1),
                      border: Border.all(
                        color: colors.error.withValues(alpha: 0.3),
                      ),
                      child: Icon(
                        Icons.cancel_outlined,
                        size: AppSpacing.lg,
                        color: colors.error,
                      ),
                    ),
                  ),
                ),
              ] else if (isVerified) ...[
                // Block button
                Tooltip(
                  message: 'Block User',
                  child: InkWell(
                    onTap: () => _onToggleBlock(item, true),
                    borderRadius: AppRadius.smRadius,
                    child: QuickContainer(
                      p: AppSpacing.xs + 2,
                      radius: AppRadius.sm,
                      color: colors.warning.withValues(alpha: 0.1),
                      border: Border.all(
                        color: colors.warning.withValues(alpha: 0.3),
                      ),
                      child: Icon(
                        Icons.block_outlined,
                        size: AppSpacing.lg,
                        color: colors.warning,
                      ),
                    ),
                  ),
                ),
                AppSpacing.xs.w,
                // Delete button
                Tooltip(
                  message: 'Delete User',
                  child: InkWell(
                    onTap: () => _onDeleteUser(item),
                    borderRadius: AppRadius.smRadius,
                    child: QuickContainer(
                      p: AppSpacing.xs + 2,
                      radius: AppRadius.sm,
                      color: colors.error.withValues(alpha: 0.08),
                      border: Border.all(
                        color: colors.error.withValues(alpha: 0.25),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: AppSpacing.lg,
                        color: colors.error,
                      ),
                    ),
                  ),
                ),
              ] else if (isBlocked) ...[
                // Unblock button
                Tooltip(
                  message: 'Unblock User',
                  child: InkWell(
                    onTap: () => _onToggleBlock(item, false),
                    borderRadius: AppRadius.smRadius,
                    child: QuickContainer(
                      p: AppSpacing.xs + 2,
                      radius: AppRadius.sm,
                      color: colors.success.withValues(alpha: 0.1),
                      border: Border.all(
                        color: colors.success.withValues(alpha: 0.3),
                      ),
                      child: Icon(
                        Icons.lock_open_rounded,
                        size: AppSpacing.lg,
                        color: colors.success,
                      ),
                    ),
                  ),
                ),
                AppSpacing.xs.w,
                // Delete button
                Tooltip(
                  message: 'Delete User',
                  child: InkWell(
                    onTap: () => _onDeleteUser(item),
                    borderRadius: AppRadius.smRadius,
                    child: QuickContainer(
                      p: AppSpacing.xs + 2,
                      radius: AppRadius.sm,
                      color: colors.error.withValues(alpha: 0.08),
                      border: Border.all(
                        color: colors.error.withValues(alpha: 0.25),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: AppSpacing.lg,
                        color: colors.error,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Unverified state: allow verify, block, or delete
                Tooltip(
                  message: 'Verify User',
                  child: InkWell(
                    onTap: () => _onVerifyUser(item),
                    borderRadius: AppRadius.smRadius,
                    child: QuickContainer(
                      p: AppSpacing.xs + 2,
                      radius: AppRadius.sm,
                      color: colors.success.withValues(alpha: 0.1),
                      border: Border.all(
                        color: colors.success.withValues(alpha: 0.3),
                      ),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        size: AppSpacing.lg,
                        color: colors.success,
                      ),
                    ),
                  ),
                ),
                AppSpacing.xs.w,
                Tooltip(
                  message: 'Delete User',
                  child: InkWell(
                    onTap: () => _onDeleteUser(item),
                    borderRadius: AppRadius.smRadius,
                    child: QuickContainer(
                      p: AppSpacing.xs + 2,
                      radius: AppRadius.sm,
                      color: colors.error.withValues(alpha: 0.08),
                      border: Border.all(
                        color: colors.error.withValues(alpha: 0.25),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: AppSpacing.lg,
                        color: colors.error,
                      ),
                    ),
                  ),
                ),
              ],

              AppSpacing.xs.w,
              Tooltip(
                message: 'Details',
                child: InkWell(
                  onTap: () => _onViewUser(item),
                  borderRadius: AppRadius.smRadius,
                  child: QuickContainer(
                    p: AppSpacing.xs + 2,
                    radius: AppRadius.sm,
                    color: colors.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.3),
                    ),
                    child: Icon(
                      Icons.remove_red_eye,
                      size: AppSpacing.lg,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ];

    final roleLabel = widget.role.label(context.l10n);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AdminTableBuilder<UserModel>(
            title: '$roleLabel Management',
            subtitle:
                'Manage $roleLabel accounts, verification statuses, and credentials',
            columns: columns,
            rowHeight: AppSpacing.xxxl * 2,
            tableData: paginationState.items,
            searchController: _searchController,
            showSearchField: true,
            currentPage: paginationState.page,
            totalEntries: paginationState.total,
            rowsPerPage: paginationState.pageSize,
            load: asyncState.isLoading,
            onRowTap: _onViewUser,
            onFilterChanged: (filter) {
              controller.getPaginatedRecords(
                forceRefresh: true,
                search: _searchController.text,
              );
            },
            onSearch: (query) {
              controller.getPaginatedRecords(
                forceRefresh: true,
                search: query?.toString(),
              );
            },
            onRefresh: () async {
              await controller.getPaginatedRecords(forceRefresh: true);
            },
            onPrevious: () async {
              await controller.getPaginatedRecords(
                page: paginationState.page - 1,
              );
            },
            onLoadMore: () async {
              await controller.getPaginatedRecords(
                page: paginationState.page + 1,
              );
            },
            onPageSelected: (page) async {
              await controller.getPaginatedRecords(page: page);
            },
            onLimitChange: (limit) {
              controller.getPaginatedRecords(
                forceRefresh: true,
                pageSize: limit,
              );
            },
          ),
        ),
      ),
    );
  }
}
