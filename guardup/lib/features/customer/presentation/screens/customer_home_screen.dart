import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

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
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/navigation/app_tab_bar.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../widgets/customer_header.widget.dart';
import '../widgets/customer_promo_banner.widget.dart';
import '../widgets/customer_services_row.widget.dart';
import 'all_services_screen.dart';
import '/features/customer/presentation/screens/booking_screen.dart';
import '/features/customer/presentation/screens/search_bodyguards_screen.dart';

/// Screen 1: Primary Customer Home Screen displaying greeting, search bar,
/// quick filters, elite promo banner, services, top security companies,
/// and top bodyguards.
class CustomerHomeScreen extends StatefulWidget {
  /// Shared `/home` route: one shell tab whose builder in `app_router.dart`
  /// shows the customer, company or bodyguard home based on the session role.
  static const route = '/home';

  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _quickFilterTabController;
  final ValueNotifier<String> _serviceCategoryNotifier = ValueNotifier<String>(
    'all',
  );

  static const List<String> _quickFilters = ['Near By', 'Rated', 'Available'];

  @override
  void initState() {
    super.initState();
    _quickFilterTabController = TabController(
      length: _quickFilters.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _quickFilterTabController.dispose();
    _serviceCategoryNotifier.dispose();
    super.dispose();
  }

  void _navigateToSearch() {
    context.push(SearchBodyguardsScreen.route);
  }

  void _navigateToAllServices() {
    context.push(AllServicesScreen.route);
  }

  void _navigateToAllBodyguards() {
    context.push(CompanyBodyguardsScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    final companies = CompanyModel.fakeData;
    final topBodyguard = BodyGuardModel.fakeData.first;

    return Scaffold(
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
              AppTabBar.pill(
                controller: _quickFilterTabController,
                tabNames: _quickFilters,
                radius: AppRadius.sm,
                height: 38,
                onTap: (index) {
                  // Handle filter selection
                },
              ),
              AppSpacing.lg.h,

              // 4. GUARDUP ELITE Promo Banner
              CustomerPromoBannerWidget(
                // onBookNow: _navigateToAllBodyguards
              ),
              AppSpacing.xl.h,

              // 5. SERVICES Row (Shows up to 10 items with 'View all' opening AllServicesScreen)
              CustomerServicesRowWidget(
                selectedCategoryIdNotifier: _serviceCategoryNotifier,
                onViewAll: _navigateToAllServices,
                onCategorySelected: (catId) {
                  _navigateToAllBodyguards();
                },
              ),
              AppSpacing.xl.h,

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
                    onTap: () {
                      context.push(CompanyInformationScreen.route);
                    },
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

              // Company Cards
              ...companies.map((company) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: CompanyCard(
                    company: company,
                    onTap: () {
                      context.push(CompanyDetailsScreen.route, extra: company);
                    },
                    onBookNow: () {
                      context.push(BookingScreen.route, extra: company);
                    },
                  ),
                );
              }),
              AppSpacing.sm.h,

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

              // Top Bodyguard Card (Home Spotlight)
              BodyGuardCard(
                bodyguard: topBodyguard,
                isCompact: true,
                role: UserRole.customer,
                onTap: () {
                  context.push(
                    GuardDetailScreen.route,
                    extra: topBodyguard,
                  );
                },
                onBookNow: () {
                  context.push(
                    GuardDetailScreen.route,
                    extra: topBodyguard,
                  );
                },
              ),

              AppSpacing.xxl.h,
            ],
          ),
        ),
      ),
    );
  }
}
