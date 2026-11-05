import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/gen/assets.gen.dart';
import 'package:guardup/shared/widgets/navigation/app_tab_bar.dart';
import 'package:guardup/shared/widgets/sections/app_appbar.dart';
import 'package:guardup/shared/widgets/sections/app_image.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '../../data/model/customer_home_data.dart';
import '../widgets/customer_company_card.widget.dart';
import '../widgets/customer_header.widget.dart';
import '../widgets/customer_search_bar.widget.dart';
import '../widgets/customer_services_row.widget.dart';

/// Screen 1: Primary Customer Home Screen displaying greeting, search bar,
/// quick filters, elite promo banner, services, top security companies,
/// and top bodyguards.
class CustomerHomeScreen extends StatefulWidget {
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
    context.push(AppRoutes.searchBodyguards);
  }

  void _navigateToAllBodyguards() {
    context.push(AppRoutes.allBodyguards);
  }

  @override
  Widget build(BuildContext context) {
    final companies = CustomerCompanyItem.sampleCompanies;
    final topBodyguard = CustomerBodyguardItem.sampleBodyguards.first;

    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar(
        titleWidget: CustomerHeaderWidget(),
        alignTitle: .left,
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
              CustomerSearchBarWidget(
                readOnly: true,
                borderColor: context.colors.primary,
                onTap: _navigateToSearch,
                onFilterTap: _navigateToSearch,
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
              customerPromoBannerWidget(),
              AppSpacing.xl.h,

              // 5. SERVICES Row
              CustomerServicesRowWidget(
                selectedCategoryIdNotifier: _serviceCategoryNotifier,
                onViewAll: _navigateToSearch,
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
                    style: context.textTheme.labelMedium
                        ?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        )
                        .colour(context.colors.onSurfaceVariant),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.push(AppRoutes.companyInformation);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'View All >',
                      style: context.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w600)
                          .colour(context.colors.gold),
                    ),
                  ),
                ],
              ),
              AppSpacing.sm.h,

              // Company Cards
              ...companies.map((company) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: CustomerCompanyCardWidget(
                    company: company,
                    onTap: () {
                      context.push(AppRoutes.companyInformation);
                    },
                    onBookNow: () {
                      context.push(AppRoutes.companyInformation);
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
                    style: context.textTheme.labelMedium
                        ?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        )
                        .colour(context.colors.onSurfaceVariant),
                  ),
                  GestureDetector(
                    onTap: _navigateToAllBodyguards,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'View All >',
                      style: context.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w600)
                          .colour(context.colors.gold),
                    ),
                  ),
                ],
              ),
              AppSpacing.sm.h,

              // Top Bodyguard Card (Home Spotlight)
              customerBodyguardCard(item: topBodyguard),

              AppSpacing.xxl.h,
            ],
          ),
        ),
      ),
    );
  }

  Widget customerPromoBannerWidget() {
    return QuickContainer(
      w: double.infinity,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      gradient: LinearGradient(
        colors: [
          Color(0xFF1A202D).withValues(alpha: 0.85),
          Color(0xFF0F131C).withValues(alpha: 0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(
        color: context.colors.primary.withValues(alpha: 0.25),
        width: 1,
      ),
      pt: 16,
      pl: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left Column: Texts and Button
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: context.colors.gold.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: context.colors.gold,
                      ),
                      AppSpacing.xxs.w,
                      Text(
                        'GUARDUP ELITE',
                        style: context.textTheme.labelSmall
                            ?.copyWith(
                              fontSize: 9.5,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w400,
                            )
                            .colour(context.colors.gold),
                      ),
                    ],
                  ),
                ),
                AppSpacing.xs.h,

                // Title
                Text(
                  'Premium Security',
                  style: context.textTheme.titleMedium
                      ?.colour(context.colors.onSurface)
                      .copyWith(fontWeight: .w400),
                ),
                Text(
                  'For Every Occasion',
                  style: context.textTheme.titleMedium
                      ?.colour(context.colors.primary)
                      .copyWith(fontWeight: .w400),
                ),

                AppSpacing.xxs.h,
                Text(
                  'Armed & executive protectionoperatives ready for immediate',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall
                      ?.copyWith(fontSize: 11)
                      .colour(
                        context.colors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                ),

                AppSpacing.sm.h,

                // Book Now Button
                GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      gradient: context.colors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Book Now',
                          style: context.textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              )
                              .colour(context.colors.onPrimary),
                        ),
                        AppSpacing.xxs.w,
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: context.colors.onPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
                20.h,
              ],
            ),
          ),

          AppSpacing.sm.w,

          // Right: Bodyguard Photo
          Expanded(
            flex: 2,
            child: AppImage.asset(
              height: 140,
              assetPath: Assets.images.profilePicture2.path,
              fit: BoxFit.cover,
            ),
          ),
          08.w,
        ],
      ),
    );
  }

  Widget customerBodyguardCard({required CustomerBodyguardItem item}) {
    final guard = item.model;
    final rateInt = guard.hourlyRate.toInt();
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: QuickContainer(
        w: double.infinity,
        p: AppSpacing.md,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        // color: Color(0xFF161B26).withValues(alpha: 0.9),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A202D).withValues(alpha: 0.8),
            Color(0xFF0F131C).withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(
          color: context.colors.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bodyguard Image
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: AppImage.asset(
                          assetPath:
                              guard.user.profileImageUrl ??
                              Assets.images.profilePicture.path,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    QuickContainer(
                      radius: 100,
                      p: 2,
                      color: context.colors.primary,
                      child: Icon(
                        Icons.done,
                        size: 12,
                        color: context.colors.onPrimary,
                      ),
                    ),
                  ],
                ),
                AppSpacing.md.w,

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                guard.user.name,
                                style: context.textTheme.titleSmall
                                    ?.bold()
                                    .colour(context.colors.onSurface),
                              ),
                              AppSpacing.xxs.w,
                              Assets.svg.verifiedShieldBadge.svg(
                                width: 14,
                                height: 14,
                                colorFilter: ColorFilter.mode(
                                  context.colors.primary,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ],
                          ),
                          // Rating Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.gold.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.ssm,
                              ),
                              border: Border.all(
                                color: context.colors.gold.withValues(
                                  alpha: 0.4,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: context.colors.gold,
                                ),
                                AppSpacing.xxs.w,
                                Text(
                                  guard.rating.toStringAsFixed(1),
                                  style: context.textTheme.labelSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      )
                                      .colour(context.colors.gold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.xxs.h,

                      Text(
                        'Licensed armed, Corporate visits',
                        style: context.textTheme.bodySmall
                            ?.copyWith(fontSize: 11)
                            .colour(context.colors.onSurfaceVariant),
                      ),
                      8.h,
                      // Tags
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: item.tagLabels.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceDim,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                              border: Border.all(
                                color: context.colors.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: context.textTheme.labelSmall
                                  ?.copyWith(fontSize: 9.5, height: 1)
                                  .colour(context.colors.onSurfaceVariant),
                            ),
                          );
                        }).toList(),
                      ),

                      // Price & Book Now Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '\$$rateInt',
                                style: context.textTheme.titleMedium
                                    ?.bold()
                                    .colour(context.colors.onSurface),
                              ),
                              AppSpacing.xxs.w,
                              Text(
                                '/hr',
                                style: context.textTheme.bodySmall?.colour(
                                  context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {},
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: context.colors.primaryGradient,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.colors.primary.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Book Now',
                                style: context.textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    )
                                    .colour(context.colors.onPrimary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
