import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/customer/customer.dart';
import 'package:quick_container/quick_container.dart';

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
class BodyguardsListScreen extends StatefulWidget {
  static const route = '/customer-body-guard';

  final int initialTabIndex;

  const BodyguardsListScreen({super.key, this.initialTabIndex = 0});

  @override
  State<BodyguardsListScreen> createState() => _BodyguardsListScreenState();
}

class _BodyguardsListScreenState extends State<BodyguardsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _quickFilterTabController;
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _quickFilters = ['Solo', 'Company'];

  late final BodyguardsCubit _guardsCubit;
  StreamSubscription<BodyguardsState>? _guardsSubscription;
  Timer? _searchDebounce;

  late final CompaniesBloc _companiesBloc;
  StreamSubscription<CompaniesState>? _companiesSubscription;

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

    _guardsCubit = sl<BodyguardsCubit>();
    _guardsPaginationController = PaginationController<BodyGuardModel>(
      initialState: _guardsCubit.state.pagination,
      onRefresh: () => _guardsCubit.refresh(
        status: UserStatus.active,
        search: _searchController.text.trim(),
      ),
      onLoadMore: _guardsCubit.loadMore,
    );

    _guardsSubscription = _guardsCubit.stream.listen((state) {
      if (!mounted) return;
      _guardsPaginationController.updateState(state.pagination);
    });

    _guardsCubit.refresh(status: UserStatus.active);

    _companiesBloc = sl<CompaniesBloc>();
    _companiesPaginationController = PaginationController<CompanyModel>(
      initialState: _companiesBloc.state.pagination,
      onRefresh: () async => _companiesBloc.add(const PaginationLoadRequested()),
      onLoadMore: () async =>
          _companiesBloc.add(const PaginationNextPageRequested()),
    );

    _companiesSubscription = _companiesBloc.stream.listen((state) {
      if (!mounted) return;
      _companiesPaginationController.updateState(state.pagination);
    });

    _companiesBloc.add(const PaginationLoadRequested());

    _searchController.addListener(_handleSearch);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _guardsSubscription?.cancel();
    _guardsCubit.close();
    _companiesSubscription?.cancel();
    unawaited(_companiesBloc.close());
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
      _guardsCubit.refresh(
        search: query,
        status: UserStatus.active,
      );
      _companiesBloc.add(PaginationSearchChanged(query));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          color: context.colors.primary.withValues(alpha: 0.35),
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
      initialLoaderBuilder: (context) => const BodyGuardListSkeleton(itemCount: 4),
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
            context.push(BookingScreen.route, extra: comp);
          },
        );
      },
    );
  }
}
