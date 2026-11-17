import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/riverpod.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/services/data/models/service.model.dart';
import '/features/services/di/services.providers.dart';
import '/shared/states/pagination.state.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/table/admin_table_builder.dart';
import '/shared/widgets/table/table_models.dart';
import '../controllers/services.controller.dart';
import 'service.form.dart';

class ServicesManagementScreen extends ConsumerStatefulWidget {
  const ServicesManagementScreen({super.key});

  @override
  ConsumerState<ServicesManagementScreen> createState() =>
      _ServicesManagementScreenState();
}

class _ServicesManagementScreenState
    extends ConsumerState<ServicesManagementScreen> {
  late final TextEditingController _searchController;
  late final ValueNotifier<List<ServiceModel>> _selectedItemsNotifier;

  ProviderListenable<AsyncValue<PaginationState<ServiceModel>>> get provider =>
      servicesControllerProvider;
  ServicesController get controller =>
      ref.read(servicesControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedItemsNotifier = ValueNotifier<List<ServiceModel>>([]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectedItemsNotifier.dispose();
    super.dispose();
  }

  Future<void> _openServiceForm({ServiceModel? item}) async {
    await ServiceFormScreen.showAsSidebar(
      context: context,
      service: item,
    );
  }

  Future<void> _onDeleteServices() async {
    final items = _selectedItemsNotifier.value;
    if (items.isEmpty) return;

    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName:
          '${items.length} Service${items.length > 1 ? 's' : ''}',
    );

    if (result?.action == PopupAction.confirm && mounted) {
      await controller.deleteRecords(items);
      _selectedItemsNotifier.value = [];

      if (mounted) {
        ref
            .read(provider)
            .handleResult(
              successMessage: 'Selected services deleted',
              fallbackErrorMessage: 'Failed to delete selected services',
            );
      }
    }
  }

  Future<void> _onDeleteService(ServiceModel item) async {
    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName: item.name,
    );

    if (result?.action == PopupAction.confirm && mounted) {
      await controller.deleteRecord(item.id);

      if (mounted) {
        ref
            .read(provider)
            .handleResult(
              successMessage: '${item.name} deleted successfully',
              fallbackErrorMessage: 'Failed to delete service',
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final asyncState = ref.watch(provider);
    final paginationState =
        asyncState.value ?? const PaginationState<ServiceModel>();

    ref.listen(provider, (previous, next) {
      next.showErrorSnackbar(
        fallbackErrorMessage: 'Failed to load services',
      );
    });

    final columns = <TableColumn<ServiceModel>>[
      TableColumn<ServiceModel>(
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
      TableColumn<ServiceModel>(
        title: 'Service Name & Details',
        flex: 3,
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.name,
                style: context.textTheme.bodyMedium?.decreaseSize(1).semiBold(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if ((item.description ?? '').isNotEmpty) ...[
                (AppSpacing.xs / 2).h,
                Text(
                  item.description!,
                  style: context.textTheme.bodySmall?.colour(
                    colors.onSurfaceSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          );
        },
      ),
      TableColumn<ServiceModel>(
        title: 'Status',
        width: (AppSpacing.xxxl * 3),
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return AppChip(
            color: item.isActive ? colors.success : colors.error,
            title: item.isActive ? 'Active' : 'Inactive',
            size: AppChipSize.small,
          );
        },
      ),
      TableColumn<ServiceModel>(
        title: 'Actions',
        width: (AppSpacing.xxxl * 5),
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 0.7,
                child: Switch.adaptive(
                  value: item.isActive,
                  activeTrackColor: colors.primary,
                  onChanged: (value) async {
                    await controller.toggleActiveStatus(item.id, value);
                  },
                ),
              ),
              AppSpacing.sm.w,
              Tooltip(
                message: 'Edit Service',
                child: InkWell(
                  onTap: () => _openServiceForm(item: item),
                  borderRadius: AppRadius.smRadius,
                  child: QuickContainer(
                    p: AppSpacing.xs + 2,
                    radius: AppRadius.sm,
                    color: colors.backgroundLight,
                    border: Border.all(
                      color: colors.borderLight.withValues(alpha: 0.6),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: AppSpacing.lg,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
              AppSpacing.sm.w,
              Tooltip(
                message: 'Delete Service',
                child: InkWell(
                  onTap: () => _onDeleteService(item),
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
          );
        },
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AdminTableBuilder<ServiceModel>(
            title: 'Protection Services',
            subtitle:
                'Manage executive security service offerings and catalog status',
            columns: columns,
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
                text: 'Delete',
                leading: Icon(
                  Icons.delete_outline_rounded,
                  size: AppSpacing.md + 2,
                ),
                size: ButtonSize.small,
                type: ButtonType.danger,
                fullWidth: false,
                onPressed: _onDeleteServices,
              ),
            ],
            onReorder: (oldIndex, newIndex) async {
              controller.reorderRecords(
                paginationState.items[oldIndex].id,
                oldIndex,
                newIndex,
              );
            },
            load: asyncState.isLoading,
            activeFilter: controller.filters.isActive,
            filterChips: const [
              (label: 'All', value: null),
              (label: 'Active', value: true),
              (label: 'Inactive', value: false),
            ],
            onFilterChanged: (filter) => controller.getPaginatedRecords(
              forceRefresh: true,
              filters: controller.filters.copyWith(isActive: filter),
            ),
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
            actions: [
              AppButton(
                text: 'Add Service',
                leading: Icon(
                  Icons.add_rounded,
                  size: AppSpacing.lg,
                  color: colors.onPrimary,
                ),
                size: ButtonSize.normal,
                fullWidth: false,
                onPressed: () => _openServiceForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
