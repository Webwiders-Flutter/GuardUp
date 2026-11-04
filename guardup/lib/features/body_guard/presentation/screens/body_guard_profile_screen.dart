import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/app/routes/app_routes.dart';
import 'package:guardup/features/rating_and_reviews/data/model/review.model.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/spacing.extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/navigation/app_tab_bar.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../../data/model/body_guard.model.dart';
import '../widgets/body_guard_header_card.dart';
import '../widgets/tabs/bodyguard_about.widget.dart';
import '../widgets/tabs/bodyguard_availability.widget.dart';
import '../widgets/tabs/bodyguard_documents.widget.dart';
import '../widgets/tabs/bodyguard_reviews.widget.dart';

/// Bodyguard operational profile screen featuring the profile header card,
/// underline tabs navigation, and modular tab widgets.
class BodyGuardProfileScreen extends StatefulWidget {
  final BodyGuardModel? bodyguard;

  const BodyGuardProfileScreen({super.key, this.bodyguard});

  @override
  State<BodyGuardProfileScreen> createState() => _BodyGuardProfileScreenState();
}

class _BodyGuardProfileScreenState extends State<BodyGuardProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<String> _tabNames = [
    'About',
    'My Availability',
    'My Documents',
    'Reviews',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabNames.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guard = widget.bodyguard;
    final name = guard?.user.name ?? 'Michael Carter';
    final specialization =
        guard?.clearanceLevel ?? 'Executive & VIP Protection';
    final rating = guard?.rating ?? 4.8;
    final hourlyRate = guard?.hourlyRate ?? 60.0;
    final avatar =
        guard?.user.profileImageUrl ?? Assets.images.profilePicture.path;

    return Scaffold(
      appBar: const AppAppBar.transparent(
        title: 'My Profile',
        showBackIcon: true,
        alignTitle: AlignTitle.right,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Profile Header Card
            Padding(
              padding: context.horizontalEdgeInsets,
              child: BodyGuardHeaderCard(
                name: name,
                specialization: specialization,
                rating: rating,
                location: 'Toronto, ON',
                hourlyRate: hourlyRate,
                avatarAssetPath: avatar,
                isVerified: true,
              ),
            ),
            AppSpacing.md.h,

            // Underline Navigation Tab Bar
            AppTabBar.underline(
              controller: _tabController,
              tabNames: _tabNames,
              isScrollable: true,
              padding: context.horizontalEdgeInsets,
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: About
                  SingleChildScrollView(
                    padding:
                        context.horizontalEdgeInsets + AppSpacing.md.yPadding,
                    child: BodyguardAboutWidget(
                      bodyguard: guard,
                      onEditBio: () => context.push(AppRoutes.editProfile),
                      onEditKeyDetails: () =>
                          context.push(AppRoutes.editProfile),
                    ),
                  ),

                  // Tab 2: My Availability
                  SingleChildScrollView(
                    padding:
                        context.horizontalEdgeInsets + AppSpacing.md.yPadding,
                    child: const BodyguardAvailabilityWidget(),
                  ),

                  // Tab 3: My Documents
                  SingleChildScrollView(
                    padding:
                        context.horizontalEdgeInsets + AppSpacing.md.yPadding,
                    child: BodyguardDocumentsWidget(
                      licenses: guard?.licensesAndBadges.isNotEmpty == true
                          ? guard!.licensesAndBadges
                          : null,
                    ),
                  ),

                  // Tab 4: Reviews
                  Padding(
                    padding:
                        context.horizontalEdgeInsets + AppSpacing.md.yPadding,
                    child: BodyguardReviewsWidget(
                      reviews: guard != null ? null : ReviewModel.fakeData,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
