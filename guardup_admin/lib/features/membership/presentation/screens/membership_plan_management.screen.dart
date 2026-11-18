import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/riverpod.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/states/pagination.state.dart';
import '/shared/widgets/buttons/app_button.dart';
// import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/table/admin_table_builder.dart';
import '/shared/widgets/table/table_models.dart';
import '../../data/models/membership_plan.model.dart';
import '../../di/membership_plan.providers.dart';
import '../controllers/membership_plan.controller.dart';
import 'membership_plan.form.dart';
import 'membership_plan_details.screen.dart';

class MembershipPlanManagementScreen extends ConsumerStatefulWidget {
  const MembershipPlanManagementScreen({super.key});

  @override
  ConsumerState<MembershipPlanManagementScreen> createState() =>
      _MembershipPlanManagementScreenState();
}

class _MembershipPlanManagementScreenState
    extends ConsumerState<MembershipPlanManagementScreen> {
  late final TextEditingController _searchController;
  late final ValueNotifier<List<MembershipPlan>> _selectedItemsNotifier;

  MembershipPlanController get _controller =>
      ref.read(membershipPlanControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedItemsNotifier = ValueNotifier<List<MembershipPlan>>([]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectedItemsNotifier.dispose();
    super.dispose();
  }

  Future<void> _openForm({MembershipPlan? item}) async {
    await MembershipPlanFormScreen.showAsSidebar(context: context, plan: item);
  }

  void _openDetails(MembershipPlan item) {
    MembershipPlanDetailsScreen.showAsSidebar(context: context, planId: item.id);
  }

  // Delete is disabled for now.
  // Future<void> _onDeleteSelected() async {
    // final items = _selectedItemsNotifier.value;
    // if (items.isEmpty) return;

    // final result = await AppPopup.showDeleteConfirmation(
      // context,
      // deleteItemName:
          // '${items.length} Membership Plan${items.length > 1 ? 's' : ''}',
    // );

    // if (result?.action == PopupAction.confirm && mounted) {
      // await _controller.deleteRecords(items.map((e) => e.id).toList());
      // _selectedItemsNotifier.value = [];

      // if (mounted) {
        // ref
            // .read(membershipPlanControllerProvider)
            // .handleResult(
              // successMessage: 'Selected membership plans deleted',
              // fallbackErrorMessage: 'Failed to delete selected plans',
            // );
      // }
    // }
  // }

  // Future<void> _onDelete(MembershipPlan item) async {
    // final result = await AppPopup.showDeleteConfirmation(
      // context,
      // deleteItemName: item.name,
    // );

    // if (result?.action == PopupAction.confirm && mounted) {
      // await _controller.deleteRecord(item.id);

      // if (mounted) {
        // ref
            // .read(membershipPlanControllerProvider)
            // .handleResult(
              // successMessage: '${item.name} deleted successfully',
              // fallbackErrorMessage: 'Failed to delete membership plan',
            // );
      // }
    // }
  // }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final asyncState = ref.watch(membershipPlanControllerProvider);
    final paginationState =
        asyncState.value ?? const PaginationState<MembershipPlan>();

    ref.listen(membershipPlanControllerProvider, (previous, next) {
      next.showErrorSnackbar(
        fallbackErrorMessage: 'Failed to load membership plans',
      );
    });

    final cellStyle = context.textTheme.bodyMedium?.decreaseSize(1);
    final mutedStyle = context.textTheme.bodySmall?.colour(
      colors.onSurfaceSecondary,
    );

    final columns = <TableColumn<MembershipPlan>>[
      TableColumn<MembershipPlan>(
        title: '#',
        width: AppSpacing.xxxl + AppSpacing.lg,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return Text(
            (paginationState.pageSize * (paginationState.page - 1) + index + 1)
                .toString(),
            style: cellStyle?.medium().colour(colors.onSurfaceSecondary),
            textAlign: TextAlign.center,
          );
        },
      ),
      TableColumn<MembershipPlan>(
        title: 'Plan',
        flex: 3,
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          final benefitCount = item.description.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      item.name,
                      style: cellStyle?.semiBold(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.isPopular) ...[
                    AppSpacing.sm.w,
                    AppChip(
                      color: colors.warning,
                      title: 'Popular',
                      icon: Icons.star_rounded,
                      size: AppChipSize.small,
                    ),
                  ],
                ],
              ),
              (AppSpacing.xs / 2).h,
              Text(
                benefitCount == 0
                    ? 'No benefits listed'
                    : '$benefitCount benefit${benefitCount > 1 ? 's' : ''}',
                style: mutedStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
      TableColumn<MembershipPlan>(
        title: 'Monthly',
        flex: 1,
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          return Text(
            item.pricePerMonth.toInrAmount,
            style: cellStyle?.semiBold(),
          );
        },
      ),
      TableColumn<MembershipPlan>(
        title: 'Yearly',
        flex: 1,
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          final savingsPercent = item.yearlySavingsPercent;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.pricePerYear.toInrAmountOr(),
                style: cellStyle?.semiBold(),
              ),
              if (savingsPercent != null) ...[
                (AppSpacing.xs / 2).h,
                Text(
                  'Saves $savingsPercent%',
                  style: context.textTheme.bodySmall?.medium().colour(
                    colors.success,
                  ),
                ),
              ],
            ],
          );
        },
      ),
      TableColumn<MembershipPlan>(
        title: 'Booking Discount',
        flex: 2,
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          return Row(
            children: [
              Icon(
                item.discountType.icon,
                size: AppSpacing.md,
                color: item.hasDiscount
                    ? colors.primary
                    : colors.onSurfaceSecondary,
              ),
              AppSpacing.xs.w,
              Flexible(
                child: Text(
                  item.discountLabel,
                  style: cellStyle?.medium(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
      TableColumn<MembershipPlan>(
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
      TableColumn<MembershipPlan>(
        title: 'Actions',
        width: (AppSpacing.xxxl * 6),
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Tooltip(
                message: item.isActive ? 'Deactivate' : 'Activate',
                child: Transform.scale(
                  scale: 0.7,
                  child: Switch.adaptive(
                    value: item.isActive,
                    activeTrackColor: colors.primary,
                    onChanged: (value) =>
                        _controller.toggleActiveStatus(item.id, value),
                  ),
                ),
              ),
              AppSpacing.sm.w,
              _ActionIcon(
                tooltip: 'View Plan',
                icon: Icons.visibility_outlined,
                color: colors.secondary,
                onTap: () => _openDetails(item),
              ),
              AppSpacing.sm.w,
              _ActionIcon(
                tooltip: 'Edit Plan',
                icon: Icons.edit_outlined,
                color: colors.primary,
                onTap: () => _openForm(item: item),
              ),
              // Delete is disabled for now.
              // AppSpacing.sm.w,
              // _ActionIcon(
                // tooltip: 'Delete Plan',
                // icon: Icons.delete_outline_rounded,
                // color: colors.error,
                // isDanger: true,
                // onTap: () => _onDelete(item),
              // ),
            ],
          );
        },
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AdminTableBuilder<MembershipPlan>(
            title: 'Membership Plans',
            subtitle:
                'Customer membership tiers, pricing and booking discounts. Drag to reorder tiers.',
            columns: columns,
            tableData: paginationState.items,
            searchController: _searchController,
            showSearchField: true,
            currentPage: paginationState.page,
            totalEntries: paginationState.total,
            rowsPerPage: paginationState.pageSize,
            // Delete is disabled for now.
            // showCheckbox: true,
            // selectedItemsNotifier: _selectedItemsNotifier,
            onRowTap: _openDetails,
            // selectionActions: [
              // AppButton(
                // text: 'Delete',
                // leading: Icon(
                  // Icons.delete_outline_rounded,
                  // size: AppSpacing.md + 2,
                // ),
                // size: ButtonSize.small,
                // type: ButtonType.danger,
                // fullWidth: false,
                // onPressed: _onDeleteSelected,
              // ),
            // ],
            onReorder: (oldIndex, newIndex) async {
              await _controller.reorderRecords(
                paginationState.items[oldIndex].id,
                oldIndex,
                newIndex,
              );
            },
            load: asyncState.isLoading,
            activeFilter: _controller.filters.isActive,
            filterChips: const [
              (label: 'All', value: null),
              (label: 'Active', value: true),
              (label: 'Inactive', value: false),
            ],
            onFilterChanged: (filter) => _controller.getPaginatedRecords(
              forceRefresh: true,
              filters: _controller.filters.copyWith(isActive: filter),
            ),
            onSearch: (query) {
              _controller.getPaginatedRecords(
                forceRefresh: true,
                search: query?.toString(),
              );
            },
            onRefresh: () async {
              await _controller.getPaginatedRecords(forceRefresh: true);
            },
            onPrevious: () async {
              await _controller.getPaginatedRecords(
                page: paginationState.page - 1,
              );
            },
            onLoadMore: () async {
              await _controller.getPaginatedRecords(
                page: paginationState.page + 1,
              );
            },
            onPageSelected: (page) async {
              await _controller.getPaginatedRecords(page: page);
            },
            onLimitChange: (limit) {
              _controller.getPaginatedRecords(
                forceRefresh: true,
                pageSize: limit,
              );
            },
            actions: [
              AppButton(
                text: 'Add Plan',
                leading: Icon(
                  Icons.add_rounded,
                  size: AppSpacing.lg,
                  color: colors.onPrimary,
                ),
                size: ButtonSize.normal,
                fullWidth: false,
                onPressed: () => _openForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
    // Only used by the delete action, which is disabled for now.
    // ignore: unused_element_parameter
    this.isDanger = false,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smRadius,
        child: QuickContainer(
          p: AppSpacing.xs + 2,
          radius: AppRadius.sm,
          color: isDanger
              ? colors.error.withValues(alpha: 0.08)
              : colors.backgroundLight,
          border: Border.all(
            color: isDanger
                ? colors.error.withValues(alpha: 0.25)
                : colors.borderLight.withValues(alpha: 0.6),
          ),
          child: Icon(icon, size: AppSpacing.lg, color: color),
        ),
      ),
    );
  }
}
