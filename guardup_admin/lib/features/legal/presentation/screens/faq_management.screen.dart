import 'package:guardup_admin/shared/widgets/table/table_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/riverpod.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '../../../users/data/enums/user_role.enum.dart';
import '../../data/models/faq.model.dart';
import '../../di/faq.providers.dart';
import '../controllers/faq.controller.dart';
import '/shared/states/pagination.state.dart';
import '/shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/table/admin_table_builder.dart';
import 'faq.form.dart';

class FaqManagementScreen extends ConsumerStatefulWidget {
  const FaqManagementScreen({super.key});

  @override
  ConsumerState<FaqManagementScreen> createState() =>
      _FaqManagementScreenState();
}

class _FaqManagementScreenState extends ConsumerState<FaqManagementScreen> {
  late final TextEditingController _searchController;
  late final ValueNotifier<List<Faq>> _selectedItemsNotifier;

  ProviderListenable<AsyncValue<PaginationState<Faq>>> get provider =>
      faqControllerProvider;
  FaqController get controller => ref.read(faqControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedItemsNotifier = ValueNotifier<List<Faq>>([]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectedItemsNotifier.dispose();
    super.dispose();
  }

  Future<void> _openFaqForm({Faq? item}) async {
    await FaqFormScreen.showAsSidebar(context: context, faq: item);
  }

  Future<void> _onDeleteFaqs() async {
    final items = _selectedItemsNotifier.value;
    if (items.isEmpty) return;

    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName: '${items.length} FAQ${items.length > 1 ? 's' : ''}',
    );

    if (result?.action == PopupAction.confirm && mounted) {
      await controller.deleteRecords(items.map((e) => e.id).toList());
      _selectedItemsNotifier.value = [];

      if (mounted) {
        ref
            .read(provider)
            .handleResult(
              successMessage: 'Selected FAQs deleted',
              fallbackErrorMessage: 'Failed to delete selected FAQs',
            );
      }
    }
  }

  Future<void> _onDeleteFaq(Faq item) async {
    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName: 'FAQ',
    );

    if (result?.action == PopupAction.confirm && mounted) {
      await controller.deleteRecord(item.id);

      if (mounted) {
        ref
            .read(provider)
            .handleResult(
              successMessage: 'FAQ deleted successfully',
              fallbackErrorMessage: 'Failed to delete FAQ',
            );
      }
    }
  }

  Widget _buildRoleChip(BuildContext context, UserRoleType? role) {
    return AppChip(
      color: role?.color(context) ?? context.colors.info,
      title: role?.label(context.l10n) ?? 'All Users',
      size: AppChipSize.small,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final asyncState = ref.watch(provider);
    final paginationState = asyncState.value ?? const PaginationState<Faq>();

    ref.listen(provider, (previous, next) {
      next.showErrorSnackbar(fallbackErrorMessage: 'Failed to load FAQs');
    });

    final columns = <TableColumn<Faq>>[
      TableColumn<Faq>(
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
      TableColumn<Faq>(
        title: 'Question',
        flex: 2,
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.question,
                style: context.textTheme.bodyMedium?.decreaseSize(1).semiBold(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if ((item.questionHi ?? '').isNotEmpty) ...[
                (AppSpacing.xs / 2).h,
                Text(
                  item.questionHi!,
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
      TableColumn<Faq>(
        title: 'Answer',
        flex: 3,
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          final ans = item.answer;
          final ansHi = item.answerHi ?? '';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                ans,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.decreaseSize(1),
              ),
              if (ansHi.isNotEmpty) ...[
                (AppSpacing.xs / 2).h,
                Text(
                  ansHi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium
                      ?.decreaseSize(1)
                      .colour(colors.onSurfaceSecondary),
                ),
              ],
            ],
          );
        },
      ),
      TableColumn<Faq>(
        title: 'Audience',
        width: (AppSpacing.xxxl * 3) + AppSpacing.md,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return _buildRoleChip(context, item.role);
        },
      ),
      TableColumn<Faq>(
        title: 'Status',
        width: (AppSpacing.xxxl * 2) + AppSpacing.xl,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return AppChip(
            color: item.isActive ? colors.success : colors.error,
            title: item.isActive ? 'Active' : 'Inactive',
            size: AppChipSize.small,
          );
        },
      ),
      TableColumn<Faq>(
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
                  activeTrackColor: colors.secondary,
                  onChanged: (value) async {
                    await controller.toggleActiveStatus(item.id, value);
                  },
                ),
              ),
              AppSpacing.xs.w,
              // Edit
              Tooltip(
                message: 'Edit FAQ',
                child: InkWell(
                  onTap: () => _openFaqForm(item: item),
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
              AppSpacing.xs.w,
              // Active Switch

              // Delete
              Tooltip(
                message: 'Delete FAQ',
                child: InkWell(
                  onTap: () => _onDeleteFaq(item),
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
          child: AdminTableBuilder<Faq>(
            title: 'Frequently Asked Questions',
            subtitle: 'Manage help knowledge base questions, localized Hindi content, and role-based guides',
            columns: columns,
            rowHeight: AppSpacing.xxxl * 2.5,
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
                onPressed: _onDeleteFaqs,
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
            activeFilter: controller.filters.role,
            filterChips: [
              (label: 'All', value: null),
              ...UserRoleType.values
                  .where((r) => !r.isAdmin)
                  .map((r) => (label: r.label(context.l10n), value: r)),
            ],
            onFilterChanged: (filter) => controller.getPaginatedRecords(
              forceRefresh: true,
              filters: controller.filters.copyWith(
                role: filter as UserRoleType?,
              ),
            ),
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
                onPressed: () => _openFaqForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
