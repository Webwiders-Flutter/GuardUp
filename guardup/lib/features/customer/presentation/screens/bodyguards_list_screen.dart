import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/customer/customer.dart';
import 'package:quick_container/quick_container.dart';

import '../../../../shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/core/constants/app_durations.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/auth.dart';
import '/features/body_guard/body_guard.dart';
import '/features/company/company.dart';
import '/shared/bloc/pagination/pagination_event.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/navigation/app_tab_bar.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';
import '/shared/widgets/sections/app_appbar.dart';

/// All Bodyguards & Security Roster listing screen featuring live search,
/// Solo vs Company mode toggling with [AppTabBar.pill], and paginated feeds using [AppPagination].
class BodyguardsListScreen extends StatelessWidget {
  static const route = '/customer-body-guard';

  final int initialTabIndex;

  const BodyguardsListScreen({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              // Solo guards only (no company); company-managed guards are
              // listed through their company.
              sl<BodyguardsBloc>(
                param1: BodyguardFilters.customerDefault.copyWith(
                  ownership: BodyguardOwnership.solo,
                ),
              )..add(const PaginationLoadRequested()),
        ),
        BlocProvider(
          create: (_) =>
              sl<CompaniesBloc>()..add(const PaginationLoadRequested()),
        ),
      ],
      child: _BodyguardsListView(initialTabIndex: initialTabIndex),
    );
  }
}

class _BodyguardsListView extends StatefulWidget {
  final int initialTabIndex;

  const _BodyguardsListView({required this.initialTabIndex});

  @override
  State<_BodyguardsListView> createState() => _BodyguardsListViewState();
}

class _BodyguardsListViewState extends State<_BodyguardsListView>
    with SingleTickerProviderStateMixin {
  late final TabController _quickFilterTabController;
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _quickFilters = ['Solo', 'Company'];

  Timer? _searchDebounce;

  late final PaginationController<BodyGuardModel> _guardsPaginationController;
  late final PaginationController<CompanyModel> _companiesPaginationController;

  @override
  void initState() {
    super.initState();
    _quickFilterTabController = TabController(
      length: _quickFilters.length,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, _quickFilters.length - 1),
    );

    final guardsBloc = context.read<BodyguardsBloc>();
    _guardsPaginationController = PaginationController<BodyGuardModel>(
      initialState: guardsBloc.state.pagination,
      onRefresh: () async => guardsBloc.add(const PaginationLoadRequested()),
      onLoadMore: () async =>
          guardsBloc.add(const PaginationNextPageRequested()),
    );

    final companiesBloc = context.read<CompaniesBloc>();
    _companiesPaginationController = PaginationController<CompanyModel>(
      initialState: companiesBloc.state.pagination,
      onRefresh: () async => companiesBloc.add(const PaginationLoadRequested()),
      onLoadMore: () async =>
          companiesBloc.add(const PaginationNextPageRequested()),
    );

    _searchController.addListener(_handleSearch);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_handleSearch);
    _searchController.dispose();
    _quickFilterTabController.dispose();
    _guardsPaginationController.dispose();
    _companiesPaginationController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final query = _searchController.text.trim();

    _searchDebounce?.cancel();
    _searchDebounce = Timer(AppDurations.slow, () {
      if (!mounted) return;
      context.read<BodyguardsBloc>().add(PaginationSearchChanged(query));
      context.read<CompaniesBloc>().add(PaginationSearchChanged(query));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BodyguardsBloc, BodyguardsState>(
          listenWhen: (previous, current) =>
              previous.pagination != current.pagination,
          listener: (context, state) =>
              _guardsPaginationController.updateState(state.pagination),
        ),
        BlocListener<CompaniesBloc, CompaniesState>(
          listenWhen: (previous, current) =>
              previous.pagination != current.pagination,
          listener: (context, state) =>
              _companiesPaginationController.updateState(state.pagination),
        ),
      ],
      child: Scaffold(
        backgroundColor: context.colors.transparent,
        appBar: AppAppBar.transparent(
          title: 'Bodyguards',
          showBackIcon: true,
          alignTitle: AlignTitle.center,
          onBackTap: () => context.pop(),
        ),
        body: Column(
          children: [
            // Top Search & Mode Switcher
            Padding(
              padding: context.horizontalEdgeInsets,
              child: Column(
                children: [
                  AppSpacing.sm.h,

                  // Search Input with Luxury Tune/Filter Prefix
                  AppTextField.search(
                    controller: _searchController,
                    size: AppInputSize.small,
                    decoration: InputDecoration(
                      hintText: 'Search by name, clearance, or skill...',
                      suffixIcon: Padding(
                        padding: AppSpacing.sm.allPadding,
                        child: QuickContainer(
                          onTap: () {
                            context.push(SearchBodyguardsScreen.route);
                          },
                          w: 36,
                          h: 36,
                          radius: AppRadius.md,
                          color: context.colors.primary.withValues(alpha: 0.12),
                          border: Border.all(
                            color: context.colors.primary.withValues(
                              alpha: 0.35,
                            ),
                            width: 1.0,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.tune_rounded,
                            color: context.colors.primary,
                            size: AppSizes.iconSm,
                          ),
                        ),
                      ),
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
                  Divider(color: context.colors.outlineVariant, height: 25),

                  // Solo vs Company Pill Tabs
                  AppTabBar.pill(
                    controller: _quickFilterTabController,
                    tabNames: _quickFilters,
                    radius: AppRadius.sm,
                    height: 38,
                  ),
                  AppSpacing.md.h,
                ],
              ),
            ),

            // Tab Content Views
            Expanded(
              child: TabBarView(
                controller: _quickFilterTabController,
                children: [
                  _buildSoloGuardsList(context),
                  _buildCompaniesList(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Solo Bodyguards Tab (AppPagination + BodyGuardCard) ────────────────────

  Widget _buildSoloGuardsList(BuildContext context) {
    return AppPagination<BodyGuardModel>.list(
      controller: _guardsPaginationController,
      padding: context.horizontalEdgeInsets.add(
        const EdgeInsets.only(bottom: AppSpacing.xxl),
      ),
      separatorBuilder: (context, index) => AppSpacing.md.h,
      initialLoaderBuilder: (context) =>
          const BodyGuardListSkeleton(itemCount: 4),
      emptyBuilder: (context) => Center(
        child: Padding(
          padding: AppSpacing.xl.allPadding,
          child: Text(
            'No active bodyguards found.',
            style: context.textTheme.bodyMedium?.colour(
              context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
      itemBuilder: (context, guard, index) {
        return BodyGuardCard(
          bodyguard: guard,
          isCompact: false,
          role: UserRole.customer,
          onTap: () {
            context.push(GuardDetailScreen.route, extra: guard);
          },
          onBookNow: () {
            AppSnackbar.show(message: "Coming soon");
    return;
            context.push(CustomerBookingDetailsScreen.route, extra: guard);
          },
        );
      },
    );
  }

  // ── Companies Tab (AppPagination + CompanyCard) ────────────────────────────

  Widget _buildCompaniesList(BuildContext context) {
    return AppPagination<CompanyModel>.list(
      controller: _companiesPaginationController,
      padding: context.horizontalEdgeInsets.add(
        const EdgeInsets.only(bottom: AppSpacing.xxl),
      ),
      separatorBuilder: (context, index) => AppSpacing.md.h,
      emptyBuilder: (context) => Center(
        child: Padding(
          padding: AppSpacing.xl.allPadding,
          child: Text(
            'No companies found.',
            style: context.textTheme.bodyMedium?.colour(
              context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
      itemBuilder: (context, comp, index) {
        return CompanyCard(
          company: comp,
          onTap: () {
            context.push(CompanyDetailsScreen.route, extra: comp);
          },
          onBookNow: () {
            AppSnackbar.show(message: "Coming soon");
    return;
            context.push(BookingScreen.route, extra: comp);
          },
        );
      },
    );
  }
}
