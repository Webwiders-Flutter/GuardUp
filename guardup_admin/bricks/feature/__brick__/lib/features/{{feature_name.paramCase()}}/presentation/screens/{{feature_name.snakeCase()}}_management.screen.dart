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
import '/shared/states/pagination.state.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/table/admin_table_builder.dart';
import '/shared/widgets/table/table_models.dart';
import '../../data/models/{{feature_name.snakeCase()}}.model.dart';
import '../../di/{{feature_name.snakeCase()}}.providers.dart';
import '../controllers/{{feature_name.snakeCase()}}.controller.dart';
import '{{feature_name.snakeCase()}}.form.dart';

class {{feature_name.pascalCase()}}ManagementScreen extends ConsumerStatefulWidget {
  const {{feature_name.pascalCase()}}ManagementScreen({super.key});

  @override
  ConsumerState<{{feature_name.pascalCase()}}ManagementScreen> createState() =>
      _{{feature_name.pascalCase()}}ManagementScreenState();
}

class _{{feature_name.pascalCase()}}ManagementScreenState
    extends ConsumerState<{{feature_name.pascalCase()}}ManagementScreen> {
  late final TextEditingController _searchController;
  late final ValueNotifier<List<{{feature_name.pascalCase()}}>> _selectedItemsNotifier;

  ProviderListenable<AsyncValue<PaginationState<{{feature_name.pascalCase()}}>>> get provider =>
      {{feature_name.camelCase()}}ControllerProvider;
  {{feature_name.pascalCase()}}Controller get controller =>
      ref.read({{feature_name.camelCase()}}ControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedItemsNotifier = ValueNotifier<List<{{feature_name.pascalCase()}}>>([]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectedItemsNotifier.dispose();
    super.dispose();
  }

  Future<void> _open{{feature_name.pascalCase()}}Form({{{feature_name.pascalCase()}}? item}) async {
    await {{feature_name.pascalCase()}}FormScreen.showAsSidebar(
      context: context,
      {{feature_name.camelCase()}}: item,
    );
  }

  Future<void> _onDelete{{feature_name.pascalCase()}}s() async {
    final items = _selectedItemsNotifier.value;
    if (items.isEmpty) return;

    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName:
          '${items.length} {{entity_name.titleCase()}}${items.length > 1 ? 's' : ''}',
    );

    if (result?.action == PopupAction.confirm && mounted) {
      await controller.deleteRecords(items);
      _selectedItemsNotifier.value = [];

      if (mounted) {
        ref
            .read(provider)
            .handleResult(
              successMessage: 'Selected {{entity_name.lowerCase()}}s deleted',
              fallbackErrorMessage: 'Failed to delete selected {{entity_name.lowerCase()}}s',
            );
      }
    }
  }

  Future<void> _onDelete{{feature_name.pascalCase()}}({{feature_name.pascalCase()}} item) async {
    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName: '{{entity_name.titleCase()}}',
    );

    if (result?.action == PopupAction.confirm && mounted) {
      await controller.deleteRecord(item.id);

      if (mounted) {
        ref
            .read(provider)
            .handleResult(
              successMessage: '{{entity_name.titleCase()}} deleted successfully',
              fallbackErrorMessage: 'Failed to delete {{entity_name.lowerCase()}}',
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final asyncState = ref.watch(provider);
    final paginationState =
        asyncState.value ?? const PaginationState<{{feature_name.pascalCase()}}>();

    ref.listen(provider, (previous, next) {
      next.showErrorSnackbar(
        fallbackErrorMessage: 'Failed to load {{entity_name.lowerCase()}}s',
      );
    });

    final columns = <TableColumn<{{feature_name.pascalCase()}}>>[
      TableColumn<{{feature_name.pascalCase()}}>(
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
      TableColumn<{{feature_name.pascalCase()}}>(
        title: 'ID',
        flex: 2,
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          return Text(
            item.id,
            style: context.textTheme.bodyMedium?.decreaseSize(1).semiBold(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
      TableColumn<{{feature_name.pascalCase()}}>(
        title: 'Actions',
        width: AppSpacing.xxxl * 3,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Tooltip(
                message: 'Edit {{entity_name.titleCase()}}',
                child: InkWell(
                  onTap: () => _open{{feature_name.pascalCase()}}Form(item: item),
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
                message: 'Delete {{entity_name.titleCase()}}',
                child: InkWell(
                  onTap: () => _onDelete{{feature_name.pascalCase()}}(item),
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
          child: AdminTableBuilder<{{feature_name.pascalCase()}}>(
            title: '{{entity_name.titleCase()}}s',
            subtitle: 'Manage {{entity_name.lowerCase()}} records',
            columns: columns,
            rowHeight: AppSpacing.xxxl * 2,
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
                onPressed: _onDelete{{feature_name.pascalCase()}}s,
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
                text: 'Add',
                leading: const Icon(
                  Icons.add_rounded,
                  size: AppSpacing.lg,
                ),
                size: ButtonSize.normal,
                fullWidth: false,
                onPressed: () => _open{{feature_name.pascalCase()}}Form(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
