import '/features/body_guard/presentation/widgets/body_guard_list_skeleton.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/body_guard/presentation/screens/guard_detail.screen.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_radius.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/api_error.extension.dart';
import '/features/auth/auth.dart';
import '/shared/bloc/pagination/pagination_event.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '../../bloc/company_bodyguards/company_bodyguards_bloc.dart';
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
import '/features/body_guard/data/fixtures/bodyguard.fixtures.dart';

/// Screen presenting all company or platform bodyguards with search,
/// pagination, and management actions (Add, Edit, Delete).
class CompanyBodyguardsScreen extends StatelessWidget {
  static const route = '/all-bodyguards';

  const CompanyBodyguardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id;
    if (authState.isCompany && userId != null && userId.isNotEmpty) {
      return BlocProvider(
        create: (_) =>
            sl<CompanyBodyguardsBloc>(param1: userId)
              ..add(const PaginationLoadRequested()),
        child: const _CompanyBodyguardsView(isCompany: true),
      );
    }
    return const _CompanyBodyguardsView(isCompany: false);
  }
}

class _CompanyBodyguardsView extends StatefulWidget {
  final bool isCompany;

  const _CompanyBodyguardsView({required this.isCompany});

  @override
  State<_CompanyBodyguardsView> createState() => _CompanyBodyguardsViewState();
}

class _CompanyBodyguardsViewState extends State<_CompanyBodyguardsView>
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

  Timer? _searchDebounce;
  String? _pendingDeletedName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    if (widget.isCompany) {
      final bloc = context.read<CompanyBodyguardsBloc>();
      _paginationController = PaginationController<BodyGuardModel>(
        initialState: bloc.state.pagination,
        onRefresh: () async => bloc.add(const PaginationLoadRequested()),
        onLoadMore: () async => bloc.add(const PaginationNextPageRequested()),
      );
      _searchController.addListener(_onSearchChanged);
    } else {
      _paginationController = PaginationController<BodyGuardModel>(
        initialState: PaginationState<BodyGuardModel>(
          items: bodyguardPlaceholders,
          total: 3,
          status: const ApiState.success(null),
        ),
      );
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging || !widget.isCompany) return;
    final selectedStatus = switch (_tabController.index) {
      1 => UserStatus.active,
      2 => UserStatus.pendingApproval,
      3 => UserStatus.rejected,
      _ => null,
    };
    context.read<CompanyBodyguardsBloc>().add(
      CompanyBodyguardsStatusChanged(selectedStatus),
    );
  }

  void _onSearchChanged() {
    if (!widget.isCompany) return;
    final term = _searchController.text.trim();
    final bloc = context.read<CompanyBodyguardsBloc>();
    if (term == bloc.state.search) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      AppDurations.slow,
      () {
        if (!mounted) return;
        bloc.add(PaginationSearchChanged(term));
      },
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _paginationController.dispose();
    super.dispose();
  }

  // ── Clickflow Action Handlers ──────────────────────────────────────────────

  Future<void> _handleAddBodyguard() async {
    await context.push(BodyGuardCompleteProfileScreen.route);
    // A bodyguard may have been created even if the flow was not finished.
    if (mounted && widget.isCompany) {
      context.read<CompanyBodyguardsBloc>().add(const PaginationLoadRequested());
    }
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
    if (mounted && widget.isCompany) {
      context.read<CompanyBodyguardsBloc>().add(const PaginationLoadRequested());
    }
  }

  Future<void> _handleDeleteBodyguard(BodyGuardModel bodyguard) async {
    if (!widget.isCompany) return;
    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName: bodyguard.name,
    );
    if (result?.action != PopupAction.confirm || !mounted) return;
    _pendingDeletedName = bodyguard.name;
    context.read<CompanyBodyguardsBloc>().add(
      CompanyBodyguardDeleted(bodyguard),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
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
                  if (widget.isCompany) ...[
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
            if (widget.isCompany) ...[
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
                          widget.isCompany &&
                                  _searchController.text.trim().isEmpty
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
                    onEdit: widget.isCompany
                        ? () => _handleEditBodyguard(guard)
                        : null,
                    onDelete: widget.isCompany
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

    if (!widget.isCompany) return scaffold;

    return MultiBlocListener(
      listeners: [
        BlocListener<CompanyBodyguardsBloc, CompanyBodyguardsState>(
          listenWhen: (previous, current) =>
              previous.pagination != current.pagination,
          listener: (context, state) =>
              _paginationController.updateState(state.pagination),
        ),
        BlocListener<CompanyBodyguardsBloc, CompanyBodyguardsState>(
          listenWhen: (previous, current) =>
              previous.actionStatus != current.actionStatus,
          listener: (context, state) {
            if (state.actionStatus.isSuccess) {
              final name = _pendingDeletedName;
              _pendingDeletedName = null;
              if (name != null) {
                AppSnackbar.success('$name removed.');
              }
            } else if (state.actionStatus.isFailure) {
              _pendingDeletedName = null;
              AppSnackbar.error(
                context.apiErrorText(
                  state.actionStatus.errorOrNull,
                  fallback: state.actionStatus.errorMessageOrNull,
                ),
              );
            }
          },
        ),
      ],
      child: scaffold,
    );
  }
}
