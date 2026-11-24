import '/features/body_guard/presentation/widgets/body_guard_list_skeleton.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/body_guard/presentation/screens/guard_detail.screen.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_radius.dart';
import '/core/di/injection_container.dart';
import '/features/auth/auth.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '../../bloc/company_bodyguards/company_bodyguards_cubit.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/state/api_state.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../../data/model/body_guard.model.dart';
import '../widgets/body_guard_card.dart';
import '/features/body_guard/presentation/screens/body_guard_complete_profile_screen.dart';
import '/features/body_guard/presentation/screens/body_guard_profile_screen.dart';
import '/features/customer/presentation/screens/customer_home_screen.dart';
import '/shared/widgets/navigation/app_tab_bar.dart';

/// Screen presenting all company or platform bodyguards with search,
/// pagination, and management actions (Add, Edit, Delete).
class CompanyBodyguardsScreen extends StatefulWidget {
  static const route = '/all-bodyguards';

  const CompanyBodyguardsScreen({super.key});

  @override
  State<CompanyBodyguardsScreen> createState() =>
      _CompanyBodyguardsScreenState();
}

class _CompanyBodyguardsScreenState extends State<CompanyBodyguardsScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final PaginationController<BodyGuardModel> _paginationController;
  late final TabController _tabController;

  static const List<String> _statusTabs = [
    'All',
    'Approved',
    'Pending',
    'Rejected',
  ];

  /// Companies see and manage their own bodyguards (live data). Other roles
  /// still browse the sample roster until the public listing is built.
  late final bool _isCompany =
      sl.isRegistered<AuthBloc>() && sl<AuthBloc>().state.isCompany;
  CompanyBodyguardsCubit? _cubit;
  StreamSubscription<CompanyBodyguardsState>? _cubitSubscription;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    if (_isCompany) {
      final cubit = sl<CompanyBodyguardsCubit>();
      _cubit = cubit;
      _paginationController = PaginationController<BodyGuardModel>(
        initialState: cubit.state.pagination,
        onRefresh: cubit.refresh,
        onLoadMore: cubit.loadMore,
      );
      _cubitSubscription = cubit.stream.listen(_onCubitState);
      _searchController.addListener(_onSearchChanged);
      cubit.refresh();
    } else {
      _paginationController = PaginationController<BodyGuardModel>(
        initialState: PaginationState<BodyGuardModel>(
          items: BodyGuardModel.fakeData,
          total: 3,
          status: const ApiState.success(null),
        ),
      );
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final selectedStatus = switch (_tabController.index) {
      1 => UserStatus.active,
      2 => UserStatus.pendingApproval,
      3 => UserStatus.rejected,
      _ => null,
    };
    _cubit?.refresh(status: selectedStatus, updateStatus: true);
  }

  void _onCubitState(CompanyBodyguardsState state) {
    if (!mounted) return;
    _paginationController.updateState(state.pagination);
    final error = state.actionError;
    if (error != null) AppSnackbar.error(error);
  }

  void _onSearchChanged() {
    final term = _searchController.text.trim();
    if (term == _cubit?.state.search) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      AppDurations.slow,
      () => _cubit?.refresh(search: term),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchDebounce?.cancel();
    _cubitSubscription?.cancel();
    _cubit?.close();
    _searchController.dispose();
    _paginationController.dispose();
    super.dispose();
  }

  // ── Clickflow Action Handlers ──────────────────────────────────────────────

  Future<void> _handleAddBodyguard() async {
    await context.push(BodyGuardCompleteProfileScreen.route);
    // A bodyguard may have been created even if the flow was not finished.
    if (mounted) _cubit?.refresh();
  }

  Future<void> _handleEditBodyguard(BodyGuardModel bodyguard) async {
    if (bodyguard.verificationStatus == UserStatus.active) {
      await context.push(BodyGuardProfileScreen.route, extra: bodyguard);
    } else {
      await context.push(
        BodyGuardCompleteProfileScreen.route,
        extra: bodyguard,
      );
    }
    if (mounted) _cubit?.refresh();
  }

  Future<void> _handleDeleteBodyguard(BodyGuardModel bodyguard) async {
    final cubit = _cubit;
    if (cubit == null) return;
    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName: bodyguard.user.name,
    );
    if (result?.action != PopupAction.confirm || !mounted) return;
    final deleted = await cubit.delete(bodyguard);
    if (deleted && mounted) {
      AppSnackbar.success('${bodyguard.user.name} removed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(
        title: 'All Bodyguards',
        fontSize: 14,
        showBackIcon: true,
        onBackTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(CustomerHomeScreen.route);
          }
        },
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.md.h,
            // -----------------------------------------------------------------
            // 1. Search Bar & Add Bodyguard CTA Row
            // -----------------------------------------------------------------
            Padding(
              padding: context.horizontalEdgeInsets,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppTextField.search(
                      controller: _searchController,
                      size: AppInputSize.small,
                      decoration: InputDecoration(
                        hintText: 'Search bodyguards near you...',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.xl.toBorderRadius,
                          borderSide: BorderSide(
                            color: context.colors.outlineVariant,
                          ),
                        ),
                        fillColor: context.colors.onPrimary,
                      ),
                      style: TextStyle(color: context.colors.onSurface),
                    ),
                  ),
                  if (_isCompany) ...[
                    AppSpacing.sm.w,
                    Expanded(
                      child: AppButton(
                        text: 'Add',
                        isFlexible: true,
                        leading: Icon(
                          Icons.add_rounded,
                          size: AppSizes.iconMd,
                          color: context.colors.onPrimary,
                        ),
                        type: ButtonType.primary,
                        size: ButtonSize.normal,
                        onPressed: _handleAddBodyguard,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_isCompany) ...[
              AppSpacing.sm.h,
              Padding(
                padding: context.horizontalEdgeInsets,
                child: AppTabBar.pill(
                  tabNames: _statusTabs,
                  controller: _tabController,
                  isScrollable: false,
                ),
              ),
            ],
            AppSpacing.md.h,

            // -----------------------------------------------------------------
            // 2. Paginated Bodyguards List using AppPagination.list
            // -----------------------------------------------------------------
            Expanded(
              child: AppPagination<BodyGuardModel>.list(
                controller: _paginationController,
                padding: context.horizontalEdgeInsets + AppSpacing.lg.bPadding,
                separatorBuilder: (context, index) => AppSpacing.md.h,
                initialLoaderBuilder: (context) =>
                    const BodyGuardListSkeleton(itemCount: 4),
                emptyBuilder: (context) => Center(
                  child: Padding(
                    padding: AppSpacing.xxl.allPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.security_rounded,
                          size: AppSizes.icon2Xl,
                          color: context.colors.outline,
                        ),
                        AppSpacing.md.h,
                        Text(
                          'No bodyguards found',
                          style: context.textTheme.titleSmall?.semiBold(),
                        ),
                        AppSpacing.xs.h,
                        Text(
                          _isCompany && _searchController.text.trim().isEmpty
                              ? 'Tap Add to register your first bodyguard.'
                              : 'Try adjusting your search criteria.',
                          style: context.textTheme.bodySmall?.colour(
                            context.colors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                itemBuilder: (context, guard, index) {
                  return BodyGuardCard(
                    bodyguard: guard,
                    onTap: () {
                      context.push(GuardDetailScreen.route, extra: guard);
                    },
                    onEdit: _isCompany
                        ? () => _handleEditBodyguard(guard)
                        : null,
                    onDelete: _isCompany
                        ? () => _handleDeleteBodyguard(guard)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
