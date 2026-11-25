import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/di/injection_container.dart';
import 'package:guardup/features/auth/auth.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/spacing.extension.dart';
import '/shared/widgets/navigation/app_tab_bar.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../../data/model/company.model.dart';
import '../widgets/company_card.dart';
import '../widgets/tabs/company_about_tab.dart';
import '../widgets/tabs/company_bodyguards_tab.dart';
import '../widgets/tabs/company_reviews_tab.dart';
import '/features/customer/presentation/screens/booking_screen.dart';

/// Company operational profile and details screen.
///
/// Presents:
/// - Transparent [AppAppBar] with right-aligned "Company Profile" title
/// - Header [CompanyCard] with live presence and operative count
/// - Underline navigation [AppTabBar] switching between:
///   1. About (joined tenure, overview, and verified documents)
///   2. Bodyguards (deployed operative roster)
///   3. Reviews (client feedback and ratings)
class CompanyDetailsScreen extends StatefulWidget {
  static const route = '/company-details';

  final CompanyModel? company;

  const CompanyDetailsScreen({super.key, this.company});

  @override
  State<CompanyDetailsScreen> createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  late final List<String> _tabNames;

  @override
  void initState() {
    super.initState();
    final effectiveCompany = widget.company ?? CompanyModel.fakeData.first;
    final reviewsCountLabel = '${effectiveCompany.reviewCount}';

    _tabNames = ['About', 'Bodyguards', 'Reviews ($reviewsCountLabel)'];

    _tabController = TabController(length: _tabNames.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleBookNow(CompanyModel company) {
    context.push(BookingScreen.route, extra: company);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveCompany = widget.company ?? CompanyModel.fakeData.first;

    return Scaffold(
      appBar: const AppAppBar.transparent(
        title: 'Company Profile',
        showBackIcon: true,
        alignTitle: AlignTitle.right,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -----------------------------------------------------------------
            // 1. Company Profile Header Card
            // -----------------------------------------------------------------
            Padding(
              padding: context.horizontalEdgeInsets,
              child: CompanyCard(
                company: effectiveCompany,
                onBookNow: () => _handleBookNow(effectiveCompany),
              ),
            ),
            AppSpacing.md.h,

            // -----------------------------------------------------------------
            // 2. Underline Tab Bar Navigation
            // -----------------------------------------------------------------
            AppTabBar.underline(
              controller: _tabController,
              tabNames: _tabNames,
              isScrollable: true,
              padding: context.horizontalEdgeInsets,
            ),
            AppSpacing.md.h,

            // -----------------------------------------------------------------
            // 3. Tab Content Views
            // -----------------------------------------------------------------
            Expanded(
              child: TabBarView(
                controller: _tabController,

                children: [
                  // Tab 1: About, tenure, description, and verified documents
                  CompanyAboutTab(company: effectiveCompany),

                  // Tab 2: Company bodyguard operatives
                  CompanyBodyguardsTab(role: sl<AuthBloc>().state.sessionRole),

                  // Tab 3: Customer reviews and ratings
                  const CompanyReviewsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
