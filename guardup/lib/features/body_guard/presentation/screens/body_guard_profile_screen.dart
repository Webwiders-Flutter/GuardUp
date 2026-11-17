import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/app/routes/app_routes.dart';
import 'package:guardup/features/rating_and_reviews/data/model/review.model.dart';

import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/spacing.extension.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_state.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/navigation/app_tab_bar.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../../data/enum/guard_service.enum.dart';
import '../../data/model/body_guard.model.dart';
import '../widgets/body_guard_header_card.dart';
import '../widgets/tabs/bodyguard_about.widget.dart';
import '../widgets/tabs/bodyguard_availability.widget.dart';
import '../widgets/tabs/bodyguard_documents.widget.dart';
import '../widgets/tabs/bodyguard_reviews.widget.dart';

/// Bodyguard operational profile screen featuring the profile header card,
/// underline tabs navigation, and modular tab widgets.
class BodyGuardProfileScreen extends StatefulWidget {
  static const route = '/bodyguard-information';

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
    return BlocBuilder<AuthBloc, AuthState>(
      bloc: sl<AuthBloc>(),
      builder: (context, state) {
        final guard = widget.bodyguard;
        final servicesList = state.services;
        final dynamicServices = servicesList.isNotEmpty
            ? servicesList
                .map((s) => GuardService.fromApiValue(s))
                .toList()
            : null;

        final userServicesSummary = servicesList.isNotEmpty
            ? servicesList.map((s) => s.replaceAll('_', ' ')).join(', ')
            : 'Executive & VIP Protection';

        final name = guard?.user.name ??
            (state.user?.name ?? state.displayName);
        final specialization = guard?.clearanceLevel ?? userServicesSummary;
        final rating = guard?.rating ?? state.rating;
        final hourlyRate = guard?.hourlyRate ??
            (state.hourlyRate > 0 ? state.hourlyRate : 60.0);
        final avatar = guard?.user.profileImageUrl ??
            (state.avatarUrl.isNotEmpty
                ? state.avatarUrl
                : Assets.images.profilePicture.path);
        final bio = guard?.bio ?? (state.bio.isNotEmpty ? state.bio : null);

        return Scaffold(
          appBar: const AppAppBar.transparent(
            title: 'My Profile',
            showBackIcon: true,
            fontSize: 14,
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
                    name: name.isNotEmpty ? name : 'Michael Carter',
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
                        padding: context.horizontalEdgeInsets +
                            AppSpacing.md.yPadding,
                        child: BodyguardAboutWidget(
                          bodyguard: guard,
                          bio: bio,
                          hourlyRate: hourlyRate,
                          services: dynamicServices,
                          onEditBio: () => context.push(AppRoutes.editProfile),
                          onEditKeyDetails: () =>
                              context.push(AppRoutes.editProfile),
                        ),
                      ),

                      // Tab 2: My Availability
                      SingleChildScrollView(
                        padding: context.horizontalEdgeInsets +
                            AppSpacing.md.yPadding,
                        child: const BodyguardAvailabilityWidget(),
                      ),

                      // Tab 3: My Documents
                      SingleChildScrollView(
                        padding: context.horizontalEdgeInsets +
                            AppSpacing.md.yPadding,
                        child: BodyguardDocumentsWidget(
                          licenses: guard?.licensesAndBadges.isNotEmpty == true
                              ? guard!.licensesAndBadges
                              : null,
                        ),
                      ),

                      // Tab 4: Reviews
                      Padding(
                        padding: context.horizontalEdgeInsets +
                            AppSpacing.md.yPadding,
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
      },
    );
  }
}
