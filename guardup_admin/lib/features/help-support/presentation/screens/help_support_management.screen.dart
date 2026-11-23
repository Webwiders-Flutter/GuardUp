import 'package:guardup_admin/core/extensions/spacing.extension.dart';
import 'package:guardup_admin/shared/widgets/table/table_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/datetime.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/riverpod.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/help-support/data/enums/contact_us_status.enum.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/presentation/screens/user_details.screen.dart';
import '/shared/states/pagination.state.dart';
import '/shared/widgets/admin_layout/admin_page_body.dart';
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
  /// Route path of this screen.
  static const route = '/help-support';

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

  Future<void> _onUpdateSelectedStatus(ContactUsStatus status) async {
    final items = _selectedItemsNotifier.value;
    if (items.isEmpty) return;

    final ids = items.map((e) => e.id).toList();
    await controller.updateStatusMany(ids, status);
    _selectedItemsNotifier.value = [];

    if (mounted) {
      ref
          .read(provider)
          .handleResult(
            successMessage:
                '${items.length} request${items.length > 1 ? 's' : ''} '
                'marked as ${status.label(context.l10n)}',
            fallbackErrorMessage: 'Failed to update support request status',
          );
    }
  }

  Future<void> _onUpdateStatus(ContactUs item, ContactUsStatus status) async {
    if (item.status == status) return;
    await controller.updateStatus(item.id, status);
    if (mounted) {
      ref
          .read(provider)
          .handleResult(
            successMessage: 'Request marked as ${status.label(context.l10n)}',
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
                item.email,
                style: context.textTheme.bodyMedium
                    ?.decreaseSize(1)
                    .colour(colors.onSurfaceSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
            dialogSubtitle: item.email,
          );
        },
      ),
      // TableColumn<ContactUs>(
      //   title: 'Status',
      //   width: AppSpacing.xxxl * 4 + AppSpacing.md,
      //   alignment: Alignment.center,
      //   cellBuilder: (item, index) {
      //     return
      //   },
      // ),
      TableColumn<ContactUs>(
        title: 'Received At',
        width: AppSpacing.xxxl * 5,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return Text(
            item.createdAt?.fullDateTime ?? '—',
            style: context.textTheme.bodySmall
                ?.size(AppSpacing.md - 0.5)
                .colour(colors.onSurfaceSecondary),
            textAlign: TextAlign.center,
          );
        },
      ),
      TableColumn<ContactUs>(
        title: 'Actions',
        width: AppSpacing.xxxl * 7,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          final userId = item.userId;
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: .end,
            children: [
              // Registered sender: open their profile.
              PopupMenuButton<ContactUsStatus>(
                tooltip: 'Change status',
                initialValue: item.status,
                onSelected: (status) => _onUpdateStatus(item, status),
                itemBuilder: (context) => [
                  for (final status in ContactUsStatus.values)
                    PopupMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Icon(
                            status.icon,
                            size: AppSpacing.md + 2,
                            color: status.color(context),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(status.label(context.l10n)),
                        ],
                      ),
                    ),
                ],
                child: AppChip(
                  color: item.status.color(context),
                  icon: item.status.icon,
                  title: item.status.label(context.l10n),
                  size: AppChipSize.normal,
                ),
              ),
              if (userId != null) ...[
                AppSpacing.sm.w,
                AppButton.outline(
                  size: .small,
                  type: .primary,
                  tooltip: 'View User',
                  icon: Icons.person_search_outlined,
                  onPressed: () => UserDetailsScreen.showAsSidebar(
                    context: context,
                    userId: userId,
                  ),
                ),
              ],
              AppSpacing.sm.w,
              AppButton.outline(
                size: .small,
                type: .danger,
                tooltip: 'Delete Request',
                icon: Icons.delete_outline_rounded,
                onPressed: () => _onDeleteContactUs(item),
              ),
            ],
          );
        },
      ),
    ];

    return AdminPageBody(
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
          for (final status in ContactUsStatus.values)
            AppButton(
              text: 'Mark ${status.label(context.l10n)}',
              leading: Icon(
                status.icon,
                size: AppSpacing.md + 2,
                color: colors.onSurface,
              ),
              size: ButtonSize.small,
              type: switch (status) {
                ContactUsStatus.pending => ButtonType.warning,
                ContactUsStatus.inProgress => ButtonType.info,
                ContactUsStatus.resolved => ButtonType.success,
                ContactUsStatus.closed => ButtonType.secondaryOff,
              },
              fullWidth: false,
              onPressed: () => _onUpdateSelectedStatus(status),
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
          ...ContactUsStatus.values.map(
            (s) => (label: s.label(context.l10n), value: s),
          ),
          ...UserRoleType.values
              .where((x) => !x.isAdmin)
              .map((r) => (label: r.label(context.l10n), value: r)),
        ],
        onFilterChanged: (filter) {
          ContactUsFilters newFilters;
          if (filter == null) {
            newFilters = const ContactUsFilters();
          } else if (filter is ContactUsStatus) {
            newFilters = ContactUsFilters(status: filter);
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
        onPageSelected: (page) => controller.getPaginatedRecords(page: page),
        onLimitChange: (limit) =>
            controller.getPaginatedRecords(forceRefresh: true, pageSize: limit),
      ),
    );
  }
}
