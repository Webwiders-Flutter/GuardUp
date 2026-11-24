import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/riverpod.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/string.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/company_bodyguards/di/company_bodyguards.providers.dart';
import '/features/company_bodyguards/presentation/controllers/company_bodyguard_review.controller.dart';
import '/features/company_bodyguards/presentation/controllers/company_bodyguards.controller.dart';
import '/features/company_bodyguards/presentation/widgets/company_bodyguard_avatar.widget.dart';
import '/features/company_bodyguards/presentation/widgets/company_bodyguard_review.panel.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/data/models/bodyguard.model.dart';
import '/features/users/presentation/screens/user_details.screen.dart';
import '/features/users/presentation/screens/users_management.screen.dart';
import '/shared/states/pagination.state.dart';
import '/shared/widgets/admin_layout/admin_page_body.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/table/admin_table_builder.dart';
import '/shared/widgets/table/table_models.dart';

/// Admin listing of company-managed bodyguards (added by a company in the
/// app, no login of their own), one page per status. Separate from the
/// Bodyguards (GUARD accounts) listing; review happens in
/// [CompanyBodyguardReviewPanel]. Company bodyguards are only approved,
/// rejected or deleted, never blocked.
class CompanyBodyguardsManagementScreen extends ConsumerStatefulWidget {
  /// Base route (redirects to [defaultLocation]), inside the users section.
  static const route = '${UsersManagementScreen.route}/company-bodyguards';

  /// Route segment under [UsersManagementScreen.route].
  static const path = 'company-bodyguards';

  /// Status lists, in display order. Drives the router and the sidebar.
  static const statuses = [
    UserStatus.approvalPending,
    UserStatus.active,
    UserStatus.rejected,
  ];

  /// Status opened when only [route] is in the URL.
  static const defaultStatus = UserStatus.approvalPending;

  /// `/users/company-bodyguards/<status>`, e.g. `.../pending`.
  static String location(UserStatus status) => '$route/${status.slug}';

  static String get defaultLocation => location(defaultStatus);

  const CompanyBodyguardsManagementScreen({super.key, required this.status});

  final UserStatus status;

  @override
  ConsumerState<CompanyBodyguardsManagementScreen> createState() =>
      _CompanyBodyguardsManagementScreenState();
}

class _CompanyBodyguardsManagementScreenState
    extends ConsumerState<CompanyBodyguardsManagementScreen> {
  late final TextEditingController _searchController;

  AsyncNotifierProvider<
    CompanyBodyguardsController,
    PaginationState<BodyguardModel>
  >
  get _provider => companyBodyguardsControllerProvider(widget.status);

  CompanyBodyguardsController get _controller =>
      ref.read(_provider.notifier);

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

  static String _nameOf(BodyguardModel item) =>
      item.name.isNotEmpty ? item.name : 'Unnamed bodyguard';

  void _onView(BodyguardModel item) {
    CompanyBodyguardReviewPanel.show(context: context, bodyguardId: item.id);
  }

  /// Runs a review action and reports its result. The (auto-dispose) review
  /// controller is kept alive until the result has been read.
  Future<void> _runReviewAction(
    BodyguardModel item,
    Future<void> Function(CompanyBodyguardReviewController controller) action, {
    required String successMessage,
    required String fallbackErrorMessage,
  }) async {
    final provider = companyBodyguardReviewControllerProvider(item.id);
    final subscription = ref.listenManual(provider, (_, _) {});
    try {
      await action(ref.read(provider.notifier));
      if (mounted) {
        ref
            .read(provider)
            .handleResult(
              successMessage: successMessage,
              fallbackErrorMessage: fallbackErrorMessage,
            );
      }
    } finally {
      subscription.close();
    }
  }

  Future<void> _onDelete(BodyguardModel item) async {
    final name = _nameOf(item);
    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName: name,
    );
    if (result?.action != PopupAction.confirm || !mounted) return;

    await _runReviewAction(
      item,
      (controller) => controller.delete(),
      successMessage: '$name deleted successfully',
      fallbackErrorMessage: 'Failed to delete bodyguard',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final asyncState = ref.watch(_provider);
    final paginationState =
        asyncState.value ?? const PaginationState<BodyguardModel>();

    ref.listen(_provider, (previous, next) {
      next.showErrorSnackbar(
        fallbackErrorMessage: 'Failed to load company bodyguards',
      );
    });

    final columns = <TableColumn<BodyguardModel>>[
      TableColumn<BodyguardModel>(
        title: '#',
        width: AppSpacing.xxxl + AppSpacing.lg,
        alignment: Alignment.center,
        cellBuilder: (item, index) => Text(
          (paginationState.pageSize * (paginationState.page - 1) + index + 1)
              .toString(),
          style: context.textTheme.bodyMedium
              ?.decreaseSize(1)
              .medium()
              .colour(colors.onSurfaceSecondary),
          textAlign: TextAlign.center,
        ),
      ),
      TableColumn<BodyguardModel>(
        title: 'Profile',
        width: AppSpacing.xxxl * 2 + AppSpacing.md,
        alignment: Alignment.center,
        cellBuilder: (item, index) =>
            CompanyBodyguardAvatar(bodyguard: item, size: 48),
      ),
      TableColumn<BodyguardModel>(
        title: 'Bodyguard',
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _nameOf(item),
              style: context.textTheme.bodyMedium?.decreaseSize(1).semiBold(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!item.isActive) ...[
              (AppSpacing.xs / 2).h,
              Text(
                'Switched off by company',
                style: context.textTheme.bodySmall?.colour(
                  colors.onSurfaceSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
      TableColumn<BodyguardModel>(
        title: 'Company',
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          final company = item.company;
          final companyName = company?.companyName?.trim() ?? '';
          final label = Text(
            companyName.isNotEmpty ? companyName : '—',
            style: context.textTheme.bodyMedium
                ?.decreaseSize(1)
                .semiBold()
                .colour(company != null ? colors.primary : colors.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
          if (company == null) return label;
          return Tooltip(
            message: 'View company',
            child: InkWell(
              onTap: () => UserDetailsScreen.showAsSidebar(
                context: context,
                userId: company.userId,
              ),
              child: label,
            ),
          );
        },
      ),
      TableColumn<BodyguardModel>(
        title: 'Company Phone',
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          final phone = (item.company?.companyPhoneNumber ?? '').toE164(
            countryCode: item.company?.companyPhoneCode ?? '-',
          );
          return Text(
            phone.isNotEmpty ? phone : '—',
            style: context.textTheme.bodyMedium?.decreaseSize(1).semiBold(),
            maxLines: 1,
          );
        },
      ),
      TableColumn<BodyguardModel>(
        title: 'Hourly Rate',
        width: AppSpacing.xxxl * 3,
        alignment: Alignment.centerLeft,
        cellBuilder: (item, index) {
          final rate = item.hourlyRate ?? 0;
          return Text(
            rate > 0 ? '${rate.toUsdAmount} / hr' : '—',
            style: context.textTheme.bodyMedium?.decreaseSize(1).semiBold(),
            maxLines: 1,
          );
        },
      ),
      TableColumn<BodyguardModel>(
        title: 'Status',
        width: AppSpacing.xxxl * 4,
        alignment: Alignment.center,
        cellBuilder: (item, index) => AppChip(
          color: item.status.color(context),
          title: item.status.label(),
          icon: item.status.icon,
          size: AppChipSize.small,
        ),
      ),
      TableColumn<BodyguardModel>(
        title: 'Actions',
        width: AppSpacing.xxxl * 5,
        alignment: Alignment.center,
        cellBuilder: (item, index) {
          final status = item.status;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Same as the users list: approve / reject live in the review
              // panel; pending rows only open it.
              if (!status.isPendingApproval) ...[
                AppButton.outline(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete Bodyguard',
                  type: .danger,
                  onPressed: () => _onDelete(item),
                  size: .small,
                ),
                AppSpacing.sm.w,
              ],
              AppButton.outline(
                icon: Icons.remove_red_eye,
                tooltip: status.isUnderReview ? 'Review' : 'Details',
                type: status.isUnderReview ? .warning : .primary,
                onPressed: () => _onView(item),
                size: .small,
              ),
            ],
          );
        },
      ),
    ];

    return AdminPageBody(
      child: AdminTableBuilder<BodyguardModel>(
        title: 'Company Bodyguards — ${widget.status.label()}',
        subtitle:
            'Bodyguards added by security companies: verification and '
            'documents',
        columns: columns,
        rowHeight: AppSpacing.xxxl * 2,
        tableData: paginationState.items,
        searchController: _searchController,
        showSearchField: true,
        currentPage: paginationState.page,
        totalEntries: paginationState.total,
        rowsPerPage: paginationState.pageSize,
        load: asyncState.isLoading,
        onRowTap: _onView,
        onFilterChanged: (filter) {
          _controller.getPaginatedRecords(
            forceRefresh: true,
            search: _searchController.text,
          );
        },
        onSearch: (query) {
          _controller.getPaginatedRecords(
            forceRefresh: true,
            search: query?.toString(),
          );
        },
        onRefresh: () => _controller.getPaginatedRecords(forceRefresh: true),
        onPrevious: () =>
            _controller.getPaginatedRecords(page: paginationState.page - 1),
        onLoadMore: () =>
            _controller.getPaginatedRecords(page: paginationState.page + 1),
        onPageSelected: (page) => _controller.getPaginatedRecords(page: page),
        onLimitChange: (limit) {
          _controller.getPaginatedRecords(forceRefresh: true, pageSize: limit);
        },
      ),
    );
  }
}
