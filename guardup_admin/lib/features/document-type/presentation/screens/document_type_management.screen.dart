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
import '/features/document-type/data/models/document_type.model.dart';
import '/features/document-type/di/document_type.providers.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/shared/states/pagination.state.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/table/admin_table_builder.dart';
import '/shared/widgets/table/table_models.dart';
import '../controllers/document_type.controller.dart';
import 'document_type.form.dart';

class DocumentTypeManagementScreen extends ConsumerStatefulWidget {
  const DocumentTypeManagementScreen({super.key});

  @override
  ConsumerState<DocumentTypeManagementScreen> createState() =>
      _DocumentTypeManagementScreenState();
}

class _DocumentTypeManagementScreenState
    extends ConsumerState<DocumentTypeManagementScreen> {
  late final TextEditingController _searchController;
  late final ValueNotifier<List<DocumentTypeModel>> _selectedItemsNotifier;

  ProviderListenable<AsyncValue<PaginationState<DocumentTypeModel>>>
  get provider => documentTypeControllerProvider;
  DocumentTypeController get controller =>
      ref.read(documentTypeControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedItemsNotifier = ValueNotifier<List<DocumentTypeModel>>([]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectedItemsNotifier.dispose();
    super.dispose();
  }

  Future<void> _openDocumentTypeForm({DocumentTypeModel? item}) async {
    await DocumentTypeFormScreen.showAsSidebar(
      context: context,
      documentType: item,
      initialTargetRole: controller.filters.targetRole,
    );
  }

  Future<void> _onDeleteDocumentTypes() async {
    final items = _selectedItemsNotifier.value;
    if (items.isEmpty) return;

    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName:
          '${items.length} Document Type${items.length > 1 ? 's' : ''}',
    );

    if (result?.action == PopupAction.confirm && mounted) {
      await controller.deleteRecords(items);
      _selectedItemsNotifier.value = [];

      if (mounted) {
        ref
            .read(provider)
            .handleResult(
              successMessage: 'Selected document types deleted',
              fallbackErrorMessage: 'Failed to delete selected document types',
            );
      }
    }
  }

  Future<void> _onDeleteDocumentType(DocumentTypeModel item) async {
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
              fallbackErrorMessage: 'Failed to delete document type',
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final asyncState = ref.watch(provider);
    final paginationState =
        asyncState.value ?? const PaginationState<DocumentTypeModel>();

    ref.listen(provider, (previous, next) {
      next.showErrorSnackbar(
        fallbackErrorMessage: 'Failed to load document types',
      );
    });

    final columns = <TableColumn<DocumentTypeModel>>[
      TableColumn<DocumentTypeModel>(
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
      TableColumn<DocumentTypeModel>(
        title: 'Document Name & Details',
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
      TableColumn<DocumentTypeModel>(
        title: 'Required for',
        width: (AppSpacing.xxxl * 3) + AppSpacing.xl,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          final role = item.targetRole;
          return AppChip(
            color: role.color(context),
            title: role.label(),
            icon: role.icon,
            size: AppChipSize.small,
          );
        },
      ),
      TableColumn<DocumentTypeModel>(
        title: 'Requirement',
        width: (AppSpacing.xxxl * 3),
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return Tooltip(
            message: item.isRequired ? 'Mark as optional' : 'Mark as required',
            child: AppChip(
              color: item.isRequired ? colors.error : colors.info,
              title: item.isRequired ? 'Required' : 'Optional',
              size: AppChipSize.small,
              onTap: () => controller.toggleRequired(item.id, !item.isRequired),
            ),
          );
        },
      ),
      TableColumn<DocumentTypeModel>(
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
                message: 'Edit Document Type',
                child: InkWell(
                  onTap: () => _openDocumentTypeForm(item: item),
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
                message: 'Delete Document Type',
                child: InkWell(
                  onTap: () => _onDeleteDocumentType(item),
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
          child: AdminTableBuilder<DocumentTypeModel>(
            title: 'Document Types',
            subtitle: 'Manage verification documents required from customers, bodyguards and companies',
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
                onPressed: _onDeleteDocumentTypes,
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
            activeFilter: controller.filters.targetRole,
            filterChips: [
              (label: 'All', value: null),
              ...UserRoleType.platformRoles.map(
                (role) => (label: role.label(), value: role),
              ),
            ],
            onFilterChanged: (filter) => controller.getPaginatedRecords(
              forceRefresh: true,
              filters: controller.filters.copyWith(targetRole: filter),
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
                text: 'Add',
                leading: Icon(
                  Icons.add_rounded,
                  size: AppSpacing.lg,
                  color: colors.onPrimary,
                ),
                size: ButtonSize.normal,
                fullWidth: false,
                onPressed: () => _openDocumentTypeForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
