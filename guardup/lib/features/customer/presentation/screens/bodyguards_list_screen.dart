import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/shared/widgets/navigation/app_tab_bar.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../../data/model/customer_home_data.dart';
import '../widgets/customer_bodyguard_card.widget.dart';
import '../widgets/customer_company_card.widget.dart';
import '../widgets/customer_search_bar.widget.dart';

/// Screen 3: All Bodyguards & Security Roster listing screen with search,
/// Solo vs Company mode toggling, and complete operative credentials.
class BodyguardsListScreen extends StatefulWidget {
  const BodyguardsListScreen({super.key});

  @override
  State<BodyguardsListScreen> createState() => _BodyguardsListScreenState();
}

class _BodyguardsListScreenState extends State<BodyguardsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _quickFilterTabController;

  static const List<String> _quickFilters = ['Solo', 'Company'];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quickFilterTabController = TabController(
      length: _quickFilters.length,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final allBodyguards = CustomerBodyguardItem.sampleBodyguards;
    final allCompanies = CustomerCompanyItem.sampleCompanies;

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
          // Top Fixed Search and Toggle Bar
          Padding(
            padding: context.horizontalEdgeInsets,
            child: Column(
              children: [
                AppSpacing.sm.h,

                // Search Input
                CustomerSearchBarWidget(
                  controller: _searchController,
                  hintText: 'Search by name, clearance, or skill...',
                  onFilterTap: () {
                    context.push(AppRoutes.searchBodyguards);
                  },
                ),
                AppSpacing.md.h,
                AppTabBar.pill(
                  controller: _quickFilterTabController,
                  tabNames: _quickFilters,
                  radius: AppRadius.sm,
                  height: 38,
                  onTap: (index) {
                    // Handle filter selection
                  },
                ),
                AppSpacing.md.h,
              ],
            ),
          ),

          // Dynamic Bodyguard / Company List View
          Expanded(
            child: TabBarView(
              controller: _quickFilterTabController,
              children: [
                soloGuardsList(allBodyguards),
                companiesList(allCompanies),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget companiesList(List<CustomerCompanyItem> companies) {
    return ListView.separated(
      padding: context.horizontalEdgeInsets.add(
        const EdgeInsets.only(bottom: AppSpacing.xxl),
      ),
      itemCount: companies.length,
      separatorBuilder: (context, index) => AppSpacing.md.h,
      itemBuilder: (context, index) {
        final comp = companies[index];
        return CustomerCompanyCardWidget(
          company: comp,
          onTap: () {
            context.push(AppRoutes.companyInformation);
          },
          onBookNow: () {
            context.push(AppRoutes.companyInformation);
          },
        );
      },
    );
  }

  Widget soloGuardsList(List<CustomerBodyguardItem> guards) {
    return ListView.separated(
      padding: context.horizontalEdgeInsets.add(
        const EdgeInsets.only(bottom: AppSpacing.xxl),
      ),
      itemCount: guards.length,
      separatorBuilder: (context, index) => AppSpacing.md.h,
      itemBuilder: (context, index) {
        final guardItem = guards[index];
        return CustomerBodyguardCardWidget(
          item: guardItem,
          isCompact: false,
          onTap: () {
            context.push(
              AppRoutes.customerBodyguardProfile,
              extra: guardItem.model,
            );
          },
          onBookNow: () {
            context.push(
              AppRoutes.customerBodyguardProfile,
              extra: guardItem.model,
            );
          },
        );
      },
    );
  }
}
