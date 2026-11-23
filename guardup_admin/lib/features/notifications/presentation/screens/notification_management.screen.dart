import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/datetime.extension.dart';
import '/core/extensions/riverpod.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/states/pagination.state.dart';
import '/shared/widgets/admin_layout/admin_page_body.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/misc/app_show_more_text.dart';
import '/shared/widgets/table/admin_table_builder.dart';
import '/shared/widgets/table/table_models.dart';
import '../../data/models/notification_filters.model.dart';
import '../../data/enums/notification_type.enum.dart';
import '../../data/models/notification.model.dart';
import '../../di/notification.providers.dart';
import '../controllers/notification.controller.dart';

class NotificationManagementScreen extends ConsumerStatefulWidget {
  /// Route path of this screen.
  static const route = '/notifications';

  const NotificationManagementScreen({super.key, this.filters});

  final NotificationFilters? filters;

  @override
  ConsumerState<NotificationManagementScreen> createState() =>
      _NotificationManagementScreenState();
}

class _NotificationManagementScreenState
    extends ConsumerState<NotificationManagementScreen> {
  late final TextEditingController _searchController;
  late final ValueNotifier<List<NotificationModel>> _selectedItemsNotifier;

  ProviderListenable<AsyncValue<PaginationState<NotificationModel>>>
  get provider => notificationControllerProvider;

  NotificationController get controller =>
      ref.read(notificationControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedItemsNotifier = ValueNotifier<List<NotificationModel>>([]);
    if (widget.filters != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.getPaginatedRecords(
          forceRefresh: true,
          filters: widget.filters,
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant NotificationManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters != widget.filters) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.getPaginatedRecords(
          forceRefresh: true,
          filters: widget.filters,
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectedItemsNotifier.dispose();
    super.dispose();
  }

  Future<void> _onDeleteNotification(NotificationModel item) async {
    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName: 'Notification "${item.title}"',
    );

    if (result?.action == PopupAction.confirm && mounted) {
      await controller.deleteRecord(item.id);

      if (mounted) {
        ref
            .read(provider)
            .handleResult(
              successMessage: 'Notification deleted successfully',
              fallbackErrorMessage: 'Failed to delete notification',
            );
      }
    }
  }

  Future<void> _onDeleteSelectedNotifications() async {
    final items = _selectedItemsNotifier.value;
    if (items.isEmpty) return;

    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName:
          '${items.length} Notification${items.length > 1 ? 's' : ''}',
    );

    if (result?.action == PopupAction.confirm && mounted) {
      await controller.deleteRecords(items.map((e) => e.id).toList());
      _selectedItemsNotifier.value = [];

      if (mounted) {
        ref
            .read(provider)
            .handleResult(
              successMessage: 'Selected notifications deleted',
              fallbackErrorMessage: 'Failed to delete selected notifications',
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final asyncState = ref.watch(provider);
    final paginationState =
        asyncState.value ?? const PaginationState<NotificationModel>();

    ref.listen(provider, (previous, next) {
      next.showErrorSnackbar(
        fallbackErrorMessage: 'Failed to load notifications',
      );
    });

    final columns = <TableColumn<NotificationModel>>[
      TableColumn<NotificationModel>(
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
      TableColumn<NotificationModel>(
        title: 'Type',
        width: (AppSpacing.xxxl * 4) + AppSpacing.md,
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          final typeColor = item.type.color(context);
          return AppChip(
            color: typeColor,
            title: item.type.label,
            icon: item.type.icon,
            size: AppChipSize.small,
          );
        },
      ),
      TableColumn<NotificationModel>(
        title: 'Title',
        flex: 2,
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.title,
                style: context.textTheme.bodyMedium
                    ?.decreaseSize(1)
                    .semiBold()
                    .colour(item.isRead ? colors.onSurface : colors.primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
      TableColumn<NotificationModel>(
        title: 'Message Body',
        flex: 4,
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: AppShowMoreText(
              text: item.body,
              maxLines: 2,
              style: context.textTheme.bodyMedium
                  ?.decreaseSize(1)
                  .colour(
                    item.isRead ? colors.onSurfaceSecondary : colors.onSurface,
                  ),
              dialogTitle: item.title,
              dialogSubtitle:
                  '${item.type.apiValue} • ${item.createdAt.fullDateTime}',
            ),
          );
        },
      ),
      TableColumn<NotificationModel>(
        title: 'Status',
        width: (AppSpacing.xxxl * 2) + AppSpacing.xl,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return AppChip(
            color: item.isRead ? colors.success : colors.warning,
            title: item.isRead ? 'Read' : 'Unread',
            icon: item.isRead
                ? Icons.done_all_rounded
                : Icons.mark_email_unread_outlined,
            size: AppChipSize.small,
          );
        },
      ),
      TableColumn<NotificationModel>(
        title: 'Sent At',
        width: (AppSpacing.xxxl * 3) + AppSpacing.lg,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return Text(
            item.createdAt.fullDateTime,
            style: context.textTheme.bodySmall?.colour(
              colors.onSurfaceSecondary,
            ),
            textAlign: TextAlign.center,
          );
        },
      ),
      TableColumn<NotificationModel>(
        title: 'Actions',
        width: (AppSpacing.xxxl * 3) + AppSpacing.md,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mark as Read Button (one-way: once read, cannot toggle back)
              if (!item.isRead) ...[
                AppButton.outline(
                  size: .small,
                  type: .primary,
                  tooltip: 'Mark as Read',
                  icon: Icons.done_rounded,
                  onPressed: () => controller.markAsRead(item.id),
                ),
                AppSpacing.sm.w,
              ] else ...[
                AppButton.outline(
                  size: .small,
                  type: .secondaryOff,
                  tooltip: 'Already Read',
                  icon: Icons.done_all_rounded,
                  onPressed: null,
                ),
                AppSpacing.sm.w,
              ],

              // Delete Button
              AppButton.outline(
                size: .small,
                type: .danger,
                tooltip: 'Delete Notification',
                icon: Icons.delete_outline_rounded,
                onPressed: () => _onDeleteNotification(item),
              ),
            ],
          );
        },
      ),
    ];

    return AdminPageBody(
      child: AdminTableBuilder<NotificationModel>(
        title: 'Notifications',
        subtitle: 'Monitor system alerts, trip and order updates, and delivery status',
        columns: columns,
        tableData: paginationState.items,
        searchController: _searchController,
        showSearchField: true,
        rowHeight: AppSpacing.xxxl * 2.5,
        currentPage: paginationState.page,
        totalEntries: paginationState.total,
        rowsPerPage: paginationState.pageSize,
        showCheckbox: true,
        selectedItemsNotifier: _selectedItemsNotifier,
        selectionActions: [
          AppButton(
            text: 'Delete',
            leading: Icon(
              Icons.delete_outline_rounded,
              size: AppSpacing.md + 2,
            ),
            size: ButtonSize.small,
            type: ButtonType.danger,
            fullWidth: false,
            onPressed: _onDeleteSelectedNotifications,
          ),
        ],
        load: asyncState.isLoading,
        activeFilter: controller.filters.type,
        activeFilters: [
          if (controller.filters.isRead != null)
            (
              label: controller.filters.isRead! ? 'Read' : 'Unread',
              icon: controller.filters.isRead!
                  ? Icons.mark_email_read_outlined
                  : Icons.mark_email_unread_outlined,
              key: 'isRead',
              onRemove: () {
                controller.getPaginatedRecords(
                  forceRefresh: true,
                  filters: controller.filters.copyWith(isRead: null),
                );
              },
            ),
        ],
        onClearAllFilters: () {
          controller.getPaginatedRecords(
            forceRefresh: true,
            filters: controller.filters.copyWith(isRead: null),
          );
        },
        filterChips: [
          (label: 'All Types', value: null),
          ...NotificationType.values.map(
            (type) => (label: type.label, value: type),
          ),
        ],
        onFilterChanged: (filter) {
          controller.getPaginatedRecords(
            forceRefresh: true,
            filters: controller.filters.copyWith(
              type: filter as NotificationType?,
            ),
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
          await controller.getPaginatedRecords(page: paginationState.page - 1);
        },
        onLoadMore: () async {
          await controller.getPaginatedRecords(page: paginationState.page + 1);
        },
        onPageSelected: (page) async {
          await controller.getPaginatedRecords(page: page);
        },
        onLimitChange: (limit) {
          controller.getPaginatedRecords(forceRefresh: true, pageSize: limit);
        },
      ),
    );
  }
}
