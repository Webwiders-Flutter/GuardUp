import 'package:guardup_admin/shared/widgets/table/table_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/datetime.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/riverpod.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '../../../users/data/enums/user_role.enum.dart';
import '/shared/states/pagination.state.dart';
import '/shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/misc/app_show_more_text.dart';
import '/shared/widgets/table/admin_table_builder.dart';
import '../../data/models/contact_us.model.dart';
import '../../data/models/contact_us_filters.model.dart';
import '../../di/contact_us.providers.dart';
import '../controllers/contact_us.controller.dart';

class HelpSupportManagementScreen extends ConsumerStatefulWidget {
  const HelpSupportManagementScreen({super.key});

  @override
  ConsumerState<HelpSupportManagementScreen> createState() =>
      _HelpSupportManagementScreenState();
}

class _HelpSupportManagementScreenState
    extends ConsumerState<HelpSupportManagementScreen> {
  late final TextEditingController _searchController;
  late final ValueNotifier<List<ContactUs>> _selectedItemsNotifier;

  ProviderListenable<AsyncValue<PaginationState<ContactUs>>> get provider =>
      contactUsControllerProvider;
  ContactUsController get controller =>
      ref.read(contactUsControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedItemsNotifier = ValueNotifier<List<ContactUs>>([]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectedItemsNotifier.dispose();
    super.dispose();
  }

  Future<void> _onMarkResolved(bool resolved) async {
    final items = _selectedItemsNotifier.value;
    if (items.isEmpty) return;

    final ids = items.map((e) => e.id).toList();
    await controller.updateResolvedStatusMany(ids, resolved);
    _selectedItemsNotifier.value = [];

    if (mounted) {
      ref
          .read(provider)
          .handleResult(
            successMessage: resolved
                ? '${items.length} request${items.length > 1 ? 's' : ''} marked as resolved'
                : '${items.length} request${items.length > 1 ? 's' : ''} marked as pending',
            fallbackErrorMessage: 'Failed to update support request status',
          );
    }
  }

  Future<void> _onDeleteSelectedContactUs() async {
    final items = _selectedItemsNotifier.value;
    if (items.isEmpty) return;

    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName:
          '${items.length} Support Request${items.length > 1 ? 's' : ''}',
    );

    if (result?.action == PopupAction.confirm && mounted) {
      await controller.deleteRecords(items.map((e) => e.id).toList());
      _selectedItemsNotifier.value = [];

      if (mounted) {
        ref
            .read(provider)
            .handleResult(
              successMessage: 'Selected support requests deleted',
              fallbackErrorMessage:
                  'Failed to delete selected support requests',
            );
      }
    }
  }

  Future<void> _onDeleteContactUs(ContactUs item) async {
    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName: 'Support Request',
    );

    if (result?.action == PopupAction.confirm && mounted) {
      await controller.deleteRecord(item.id);

      if (mounted) {
        ref
            .read(provider)
            .handleResult(
              successMessage: 'Support request deleted successfully',
              fallbackErrorMessage: 'Failed to delete support request',
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final asyncState = ref.watch(provider);
    final paginationState =
        asyncState.value ?? const PaginationState<ContactUs>();

    ref.listen(provider, (previous, next) {
      next.showErrorSnackbar(
        fallbackErrorMessage: 'Failed to load support requests',
      );
    });

    final columns = <TableColumn<ContactUs>>[
      TableColumn<ContactUs>(
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
      TableColumn<ContactUs>(
        title: 'User / Contact',
        width: AppSpacing.xxxl * 6,
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.fullName,
                style: context.textTheme.bodyMedium?.decreaseSize(1).semiBold(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${item.phoneCode} ${item.mobileNumber}',
                style: context.textTheme.bodyMedium
                    ?.decreaseSize(1)
                    .colour(colors.onSurfaceSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if ((item.email ?? '').isNotEmpty) ...[
                Text(
                  item.email!,
                  style: context.textTheme.bodyMedium
                      ?.decreaseSize(1)
                      .colour(colors.onSurfaceSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          );
        },
      ),
      TableColumn<ContactUs>(
        title: 'Role',
        width: AppSpacing.xxxl * 5,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          if (item.role != null) {
            return AppChip(
              color: item.role!.color(context),
              title: item.role!.label(context.l10n),
              size: AppChipSize.small,
            );
          }
          return AppChip(
            color: colors.onSurfaceSecondary,
            title: 'General / Guest',
            size: AppChipSize.small,
          );
        },
      ),
      TableColumn<ContactUs>(
        title: 'Message',
        flex: 2,
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          return AppShowMoreText(
            text: item.message,
            maxLines: 2,
            dialogTitle: '${item.fullName} — Inquiry Message',
            dialogSubtitle:
                '${item.phoneCode} ${item.mobileNumber}'
                '${(item.email ?? '').isNotEmpty ? ' • ${item.email}' : ''}',
          );
        },
      ),
      TableColumn<ContactUs>(
        title: 'Status',
        width: AppSpacing.xxxl * 4 + AppSpacing.md,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          final isResolved = item.isResolved;
          return Tooltip(
            message: isResolved
                ? 'Click to toggle — Mark as Pending'
                : 'Click to toggle — Mark as Resolved',
            child: AppChip(
              color: isResolved ? colors.success : colors.warning,
              icon: isResolved
                  ? Icons.check_circle_rounded
                  : Icons.pending_actions_rounded,
              title: isResolved ? 'Resolved' : 'Pending',
              size: AppChipSize.normal,
              onTap: () async {
                await controller.toggleResolvedStatus(item.id, !isResolved);
              },
            ),
          );
        },
      ),
      TableColumn<ContactUs>(
        title: 'Received At',
        width: AppSpacing.xxxl * 5,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          final dt = DateTime.tryParse(item.createdAt ?? '');
          return Text(
            dt != null ? dt.fullDateTime : '—',
            style: context.textTheme.bodySmall
                ?.size(AppSpacing.md - 0.5)
                .colour(colors.onSurfaceSecondary),
            textAlign: TextAlign.center,
          );
        },
      ),
      TableColumn<ContactUs>(
        title: 'Actions',
        width: AppSpacing.xxxl * 3,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return Tooltip(
            message: 'Delete Request',
            child: InkWell(
              onTap: () => _onDeleteContactUs(item),
              borderRadius: AppRadius.smRadius,
              child: QuickContainer(
                p: AppSpacing.xs + 2,
                radius: AppRadius.sm,
                color: colors.error.withValues(alpha: 0.08),
                border: Border.all(color: colors.error.withValues(alpha: 0.25)),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: AppSpacing.lg,
                  color: colors.error,
                ),
              ),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AdminTableBuilder<ContactUs>(
            title: 'Help & Support',
            subtitle: 'Review customer inquiries, contact requests, and resolution statuses',
            columns: columns,
            rowHeight: (AppSpacing.xxxl * 2),
            tableData: paginationState.items,
            searchController: _searchController,
            showSearchField: true,
            currentPage: paginationState.page,
            totalEntries: paginationState.total,
            rowsPerPage: paginationState.pageSize,
            showCheckbox: true,
            selectedItemsNotifier: _selectedItemsNotifier,
            selectionActions: [
              AppButton(
                text: 'Mark Resolved',
                leading: Icon(
                  Icons.check_circle_outline_rounded,
                  size: AppSpacing.md + 2,
                  color: colors.onSurface,
                ),
                size: ButtonSize.small,
                type: ButtonType.success,
                fullWidth: false,
                onPressed: () => _onMarkResolved(true),
              ),
              AppButton(
                text: 'Mark Pending',
                leading: Icon(
                  Icons.pending_outlined,
                  size: AppSpacing.md + 2,
                  color: colors.onSurface,
                ),
                size: ButtonSize.small,
                type: ButtonType.warning,
                fullWidth: false,
                onPressed: () => _onMarkResolved(false),
              ),
              AppButton(
                text: 'Delete',
                leading: Icon(
                  Icons.delete_outline_rounded,
                  size: AppSpacing.md + 2,
                ),
                size: ButtonSize.small,
                type: ButtonType.danger,
                fullWidth: false,
                onPressed: _onDeleteSelectedContactUs,
              ),
            ],
            load: asyncState.isLoading,
            activeFilter: controller.currentFilter,
            filterChips: [
              (label: 'All', value: null),
              (label: 'Resolved', value: true),
              (label: 'Unresolved', value: false),
              ...UserRoleType.values
                  .where((x) => x != UserRoleType.admin)
                  .map((r) => (label: r.label(context.l10n), value: r)),
            ],
            onFilterChanged: (filter) {
              ContactUsFilters newFilters;
              if (filter == null) {
                newFilters = const ContactUsFilters();
              } else if (filter is bool) {
                newFilters = ContactUsFilters(isResolved: filter);
              } else if (filter is UserRoleType) {
                newFilters = ContactUsFilters(role: filter);
              } else {
                newFilters = const ContactUsFilters();
              }
              controller.getPaginatedRecords(
                forceRefresh: true,
                filters: newFilters,
              );
            },
            onSearch: (query) => controller.getPaginatedRecords(
              forceRefresh: true,
              search: query?.toString(),
            ),
            onRefresh: () => controller.getPaginatedRecords(forceRefresh: true),
            onPrevious: () =>
                controller.getPaginatedRecords(page: paginationState.page - 1),
            onLoadMore: () =>
                controller.getPaginatedRecords(page: paginationState.page + 1),
            onPageSelected: (page) =>
                controller.getPaginatedRecords(page: page),
            onLimitChange: (limit) => controller.getPaginatedRecords(
              forceRefresh: true,
              pageSize: limit,
            ),
          ),
        ),
      ),
    );
  }
}
