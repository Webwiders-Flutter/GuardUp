import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '../../../../shared/widgets/feedbacks/widgets/app_snackbar.dart';
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
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../widgets/customer_header.widget.dart';
import '../widgets/customer_promo_banner.widget.dart';
import '../widgets/customer_services_row.widget.dart';
import 'all_services_screen.dart';
import 'bodyguards_list_screen.dart';
import '/features/customer/presentation/screens/booking_screen.dart';

/// Screen 1: Primary Customer Home Screen displaying greeting, search bar,
/// quick filters, elite promo banner, services, top security companies,
/// and top bodyguards.
class CustomerHomeScreen extends StatelessWidget {
  /// Shared `/home` route: one shell tab whose builder in `app_router.dart`
  /// shows the customer, company or bodyguard home based on the session role.
  static const route = '/home';

  const CustomerHomeScreen({super.key});

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
      child: const _CustomerHomeView(),
    );
  }
}

class _CustomerHomeView extends StatefulWidget {
  const _CustomerHomeView();

  @override
  State<_CustomerHomeView> createState() => _CustomerHomeViewState();
}

class _CustomerHomeViewState extends State<_CustomerHomeView>
    with SingleTickerProviderStateMixin {
  late final TabController _quickFilterTabController;
  final ValueNotifier<String> _serviceCategoryNotifier = ValueNotifier<String>(
    'all',
  );

  static const List<String> _quickFilters = ['Near By', 'Rated', 'Available'];

  late final PaginationController<BodyGuardModel>
  _bodyguardsPaginationController;
  late final PaginationController<CompanyModel> _companiesPaginationController;

  @override
  void initState() {
    super.initState();
    _quickFilterTabController = TabController(
      length: _quickFilters.length,
      vsync: this,
    );

    final bodyguardsBloc = context.read<BodyguardsBloc>();
    _bodyguardsPaginationController = PaginationController<BodyGuardModel>(
      initialState: bodyguardsBloc.state.pagination,
      onRefresh: () async =>
          bodyguardsBloc.add(const PaginationLoadRequested()),
      onLoadMore: () async =>
          bodyguardsBloc.add(const PaginationNextPageRequested()),
    );

    final companiesBloc = context.read<CompaniesBloc>();
    _companiesPaginationController = PaginationController<CompanyModel>(
      initialState: companiesBloc.state.pagination,
      onRefresh: () async => companiesBloc.add(const PaginationLoadRequested()),
      onLoadMore: () async =>
          companiesBloc.add(const PaginationNextPageRequested()),
    );
  }

  @override
  void dispose() {
    _quickFilterTabController.dispose();
    _serviceCategoryNotifier.dispose();
    _bodyguardsPaginationController.dispose();
    _companiesPaginationController.dispose();
    super.dispose();
  }

  void _navigateToSearch() {
    context.push(
      BodyguardsListScreen.route,
      extra: const {'focusSearch': true},
    );
  }

  void _navigateToAllServices() {
    context.push(AllServicesScreen.route);
  }

  void _navigateToAllBodyguards() {
    context.push(BodyguardsListScreen.route);
  }

  void _navigateToAllCompanies() {
    context.push(BodyguardsListScreen.route, extra: {'initialTab': 1});
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BodyguardsBloc, BodyguardsState>(
          listenWhen: (previous, current) =>
              previous.pagination != current.pagination,
          listener: (context, state) =>
              _bodyguardsPaginationController.updateState(state.pagination),
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
        appBar: AppAppBar(
          titleWidget: BlocBuilder<AuthBloc, AuthState>(
            bloc: sl<AuthBloc>(),
            builder: (context, state) {
              final name = state.user?.name ?? '';
              return CustomerHeaderWidget(
                userName: name.isNotEmpty ? name : 'Member',
                avatarUrl: state.user?.profileImageUrl ?? '',
              );
            },
          ),
          alignTitle: .left,
          showBackIcon: false,
          showNotificationIcon: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: context.horizontalEdgeInsets,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.lg.h,

                // 2. Search Input Bar (Tapping navigates to Search Bodyguards)
                AppTextField.search(
                  size: AppInputSize.small,
                  readOnly: true,
                  onTap: _navigateToSearch,
                  decoration: InputDecoration(
                    hintText: 'Search bodyguards near you...',
                    suffixIcon: Padding(
                      padding: AppSpacing.sm.allPadding,
                      child: QuickContainer(
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
                AppSpacing.md.h,

                // 3. Quick Filter Tabs (Near By, Rated, Available)
                // AppTabBar.pill(
                //   controller: _quickFilterTabController,
                //   tabNames: _quickFilters,
                //   radius: AppRadius.sm,
                //   height: 38,
                //   onTap: (index) {
                //     // Handle filter selection
                //   },
                // ),
                // AppSpacing.lg.h,

                // 4. GUARDUP ELITE Promo Banner
                CustomerPromoBannerWidget(
                  // onBookNow: _navigateToAllBodyguards
                ),
                AppSpacing.xxl.h,

                // 5. SERVICES Row (Shows up to 10 items with 'View all' opening AllServicesScreen)
                CustomerServicesRowWidget(
                  selectedCategoryIdNotifier: _serviceCategoryNotifier,
                  onViewAll: _navigateToAllServices,
                  onCategorySelected: (catId) {
                    final filters = catId == 'all'
                        ? BodyguardFilters.customerDefault.copyWith(
                            ownership: BodyguardOwnership.solo,
                          )
                        : BodyguardFilters.customerDefault.copyWith(
                            ownership: BodyguardOwnership.solo,
                            serviceIds: [catId],
                          );
                    context.push(BodyguardsListScreen.route, extra: filters);
                  },
                ),
                AppSpacing.xxl.h,

                // 6. TOP COMPANY Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOP COMPANY',
                      style: context.textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.2,
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToAllCompanies,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'View All >',
                        style: context.textTheme.labelSmall?.colour(
                          context.colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.sm.h,

                // Dynamic Company Cards
                AppPagination<CompanyModel>.list(
                  controller: _companiesPaginationController,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  enablePullToRefresh: false,
                  separatorBuilder: (context, index) => AppSpacing.md.h,
                  itemBuilder: (context, company, index) {
                    return CompanyCard(
                      company: company,
                      onTap: () {
                        context.push(
                          CompanyDetailsScreen.route,
                          extra: company,
                        );
                      },
                      onBookNow: () {
                        AppSnackbar.show(message: "Coming soon");
                        return;
                        context.push(BookingScreen.route, extra: company);
                      },
                    );
                  },
                  emptyBuilder: (context) => Padding(
                    padding: AppSpacing.md.yPadding,
                    child: Center(
                      child: Text(
                        'No security companies available right now.',
                        style: context.textTheme.bodyMedium?.colour(
                          context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                AppSpacing.xxl.h,

                // 7. TOP BODYGUARDS Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOP BODYGUARDS',
                      style: context.textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.2,
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToAllBodyguards,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'View All >',
                        style: context.textTheme.labelSmall?.colour(
                          context.colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.sm.h,

                // Dynamic Bodyguards Roster (Home Spotlight)
                AppPagination<BodyGuardModel>.list(
                  controller: _bodyguardsPaginationController,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  enablePullToRefresh: false,
                  separatorBuilder: (context, index) => AppSpacing.sm.h,
                  itemBuilder: (context, guard, index) {
                    return BodyGuardCard(
                      bodyguard: guard,
                      isCompact: true,
                      role: UserRole.customer,
                      onTap: () {
                        context.push(GuardDetailScreen.route, extra: guard);
                      },
                      onBookNow: () {
                        AppSnackbar.show(message: "Coming soon");
                        return;
                        context.push(GuardDetailScreen.route, extra: guard);
                      },
                    );
                  },
                  emptyBuilder: (context) => Padding(
                    padding: AppSpacing.md.yPadding,
                    child: Center(
                      child: Text(
                        'No active bodyguards available right now.',
                        style: context.textTheme.bodyMedium?.colour(
                          context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),

                AppSpacing.xxl.h,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
