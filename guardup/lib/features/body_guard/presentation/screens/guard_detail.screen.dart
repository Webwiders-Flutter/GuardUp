import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/company/company.dart';
import 'package:guardup/shared/widgets/buttons/app_button.dart';
import 'package:guardup/shared/widgets/sections/app_image.dart';
import 'package:quick_container/quick_container.dart';

import '../../../guard_detail/guard_detail.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/features/body_guard/data/model/body_guard.model.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/navigation/app_tab_bar.dart';
import '/shared/widgets/sections/app_appbar.dart';

class GuardDetailScreen extends StatefulWidget {
  final BodyGuardModel? bodyguard;

  const GuardDetailScreen({super.key, this.bodyguard});

  @override
  State<GuardDetailScreen> createState() => _GuardDetailScreenState();
}

class _GuardDetailScreenState extends State<GuardDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<String> _tabs = ['Overview', 'Document', 'Booking'];

  double get _hourlyRate => widget.bodyguard?.hourlyRate ?? 60.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guardName = widget.bodyguard?.user.name ?? 'Vikram Singh';
    final photoPath =
        widget.bodyguard?.user.profileImageUrl ??
        Assets.images.onboardingImage01.path;

    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar.transparent(
        title: guardName,
        fontSize: 14,
        showBackIcon: true,
        alignTitle: AlignTitle.right,
        onBackTap: () => context.pop(),
      ),
      bottomNavigationBar: AppButton(
        text: 'Edit',
        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 20),

        size: ButtonSize.large,
        onPressed: () {},
      ),

      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                padding: context.horizontalEdgeInsets,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpacing.sm.h,

                    // 1. Operative Hero Profile Card
                    GuardProfileHeaderWidget(
                      name: guardName,
                      specialization: 'Licensed armed, Corporate visits',
                      hourlyRate: _hourlyRate,
                      imagePath: photoPath,
                      isVerified: true,
                    ),
                    AppSpacing.xlg.h,
                    CompanyCard(
                      company: CompanyModel(
                        id: '2',
                        name: 'SecurePro Security Ltd.',
                        initials: 'SP',
                        activeGuards: 12,
                        rating: 4.6,
                        bookingsCount: '340+ Bookings',
                        experienceYears: '15+ Yrs Exp',
                      ),
                    ),

                    AppSpacing.xlg.h,

                    // 3. Three Metrics Summary Row
                    const GuardMetricsRowWidget(
                      experience: '5+ yrs',
                      qualifications: 'Certified Spec',
                      status: 'Available',
                      isAvailable: true,
                    ),
                    AppSpacing.md.h,
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 4. Underline Tab Navigation
            AppTabBar.underline(
              controller: _tabController,
              tabNames: _tabs,
              indicatorColor: context.colors.primary,
              dividerColor: context.colors.outlineVariant,
              height: 40,
            ),
            AppSpacing.lg.h,

            // 5. Dynamic Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [overviewTab(), Container(), Container()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget overviewTab() {
    return SingleChildScrollView(
      padding: context.horizontalEdgeInsets,
      child: Column(
        children: [
          QuickContainer(
            px: 14,
            py: 14,
            radius: 15,
            color: context.colors.onPrimary.withValues(alpha: 0.6),
            borderColor: context.colors.borderColor.withValues(alpha: 0.7),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: context.colors.primary,
                  size: 16,
                ),
                12.w,
                Text(
                  'Joined 25 aug , 2024',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          20.h,
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text('Documents', style: context.textTheme.titleMedium),

              QuickContainer(
                px: 8,
                py: 2,
                radius: 15,
                color: context.colors.primary.withValues(alpha: 0.1),
                borderColor: context.colors.primary,
                borderWidth: 0.2,
                child: Text(
                  '4 Audited',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.colors.primary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          ...List.generate(2, (index) {
            return QuickContainer(
              p: 10,

              radius: 15,
              my: 10,
              color: context.colors.onPrimary.withValues(alpha: 0.6),
              borderColor: context.colors.onSurface.withValues(alpha: 0.15),
              child: Row(
                children: [
                  QuickContainer(
                    px: 10,
                    py: 10,
                    radius: 15,
                    color: context.colors.onPrimary.withValues(alpha: 0.6),
                    borderColor: context.colors.borderColor,
                    child: AppImage.svgAsset(
                      assetPath: Assets.svg.verified.path,
                      width: 19,
                    ),
                  ),
                  12.w,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'SIA Close Protection License',
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.check_circle_sharp,
                              color: context.colors.primary,
                              size: 13,
                            ),
                            02.w,
                            Text(
                              'Verified',
                              style: context.textTheme.bodySmall?.copyWith(
                                // fontWeight: FontWeight.w600,
                                color: context.colors.primary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        05.h,
                        Text(
                          'Security Industry Authority',
                          style: context.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: context.colors.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        05.h,
                        Text(
                          'Security Industry Authority',
                          style: context.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: context.colors.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
