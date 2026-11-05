import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/shared/widgets/sections/app_image.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/sections/app_appbar.dart';

/// Screen 2: Search & Filter Bodyguards screen allowing customers to filter
/// by location, category, hourly rate, rating, service type, and company.
class SearchBodyguardsScreen extends StatefulWidget {
  const SearchBodyguardsScreen({super.key});

  @override
  State<SearchBodyguardsScreen> createState() => _SearchBodyguardsScreenState();
}

class _SearchBodyguardsScreenState extends State<SearchBodyguardsScreen> {
  final ValueNotifier<String> _genderFilterNotifier = ValueNotifier<String>(
    'All',
  );
  final ValueNotifier<RangeValues> _rateRangeNotifier =
      ValueNotifier<RangeValues>(const RangeValues(50, 150));
  final ValueNotifier<String> _selectedRatingNotifier = ValueNotifier<String>(
    '4.5 & Above',
  );
  final ValueNotifier<String> _selectedServicesNotifier = ValueNotifier<String>(
    'Licensed armed, Corporate visits',
  );
  final ValueNotifier<String> _selectedAvailabilityNotifier =
      ValueNotifier<String>('Anytime / Immediate');
  final ValueNotifier<String> _selectedCompanyNotifier = ValueNotifier<String>(
    'SecurePro Security Ltd.',
  );

  static const List<String> _genderTabs = ['All', 'Male', 'Female'];

  @override
  void dispose() {
    _genderFilterNotifier.dispose();
    _rateRangeNotifier.dispose();
    _selectedRatingNotifier.dispose();
    _selectedServicesNotifier.dispose();
    _selectedAvailabilityNotifier.dispose();
    _selectedCompanyNotifier.dispose();
    super.dispose();
  }

  void _onSearchPressed() {
    context.push(AppRoutes.allBodyguards);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar.transparent(
        title: 'Search Bodyguards',
        showBackIcon: true,
        alignTitle: AlignTitle.center,
        onBackTap: () => context.pop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: context.horizontalEdgeInsets,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpacing.sm.h,

                    // 1. Location Bar
                    QuickContainer(
                      px: 16,
                      py: 12,
                      radius: 12,
                      color: Color(0xFF141824),
                      borderColor: Color(0xFF262D3D),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: context.colors.gold,
                            size: 19,
                          ),
                          12.w,
                          Text(
                            'Indore, Madhya Pradesh',
                            style: context.textTheme.bodyMedium
                                ?.medium()
                                .colour(context.colors.onSurface),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.md.h,

                    // 2. Gender / Category Filter Tabs (All, Male, Female)
                    ValueListenableBuilder<String>(
                      valueListenable: _genderFilterNotifier,
                      builder: (context, activeGender, _) {
                        return Row(
                          children: _genderTabs.map((tab) {
                            final isSelected = tab == activeGender;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xxs,
                                ),
                                child: GestureDetector(
                                  onTap: () =>
                                      _genderFilterNotifier.value = tab,
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? context.colors.primaryGradient
                                          : null,
                                      color: isSelected
                                          ? null
                                          : Color(0xFF141824),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? context.colors.transparent
                                            : context.colors.outlineVariant
                                                  .withValues(alpha: 0.6),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        tab,
                                        style: context.textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            )
                                            .colour(
                                              isSelected
                                                  ? context.colors.onPrimary
                                                  : context
                                                        .colors
                                                        .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    AppSpacing.lg.h,

                    // 3. Compact VIP Protection Banner
                    customerPromoBannerWidget(),
                    AppSpacing.lg.h,

                    // 4. Hourly Rate Filter Card with RangeSlider
                    QuickContainer(
                      w: double.infinity,
                      p: AppSpacing.md,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      color: context.colors.onPrimary,
                      border: Border.all(
                        color: context.colors.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                        width: 1,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Hourly Rate',
                                style: context.textTheme.bodyMedium
                                    ?.medium()
                                    .colour(context.colors.onSurface),
                              ),
                              ValueListenableBuilder<RangeValues>(
                                valueListenable: _rateRangeNotifier,
                                builder: (context, range, _) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.colors.gold.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm,
                                      ),
                                      border: Border.all(
                                        color: context.colors.gold.withValues(
                                          alpha: 0.4,
                                        ),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      '\$${range.start.round()} - \$${range.end.round()}',
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          )
                                          .colour(context.colors.gold),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          AppSpacing.xs.h,

                          // Interactive Range Slider
                          Theme(
                            data: Theme.of(context).copyWith(
                              sliderTheme: SliderThemeData(
                                activeTrackColor: context.colors.primary,
                                inactiveTrackColor:
                                    context.colors.surfaceContainerHigh,
                                thumbColor: context.colors.primary,
                                overlayColor: context.colors.primary.withValues(
                                  alpha: 0.2,
                                ),
                                trackHeight: 3.5,
                                rangeThumbShape:
                                    const RoundRangeSliderThumbShape(
                                      enabledThumbRadius: 8,
                                    ),
                              ),
                            ),
                            child: ValueListenableBuilder<RangeValues>(
                              valueListenable: _rateRangeNotifier,
                              builder: (context, range, _) {
                                return RangeSlider(
                                  values: range,
                                  min: 50,
                                  max: 300,
                                  divisions: 25,

                                  onChanged: (newRange) {
                                    _rateRangeNotifier.value = newRange;
                                  },
                                );
                              },
                            ),
                          ),

                          // Min / Center / Max Rate Labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$50/hr',
                                style: context.textTheme.bodySmall
                                    ?.copyWith(fontSize: 10.5)
                                    .colour(
                                      context.colors.onSurfaceVariant
                                          .withValues(alpha: 0.6),
                                    ),
                              ),
                              Text(
                                '\$150/hr',
                                style: context.textTheme.bodySmall
                                    ?.copyWith(fontSize: 10.5)
                                    .colour(
                                      context.colors.onSurfaceVariant
                                          .withValues(alpha: 0.6),
                                    ),
                              ),
                              Text(
                                '\$300+/hr',
                                style: context.textTheme.bodySmall
                                    ?.copyWith(fontSize: 10.5)
                                    .colour(
                                      context.colors.onSurfaceVariant
                                          .withValues(alpha: 0.6),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.md.h,

                    // 5. Rating Selector Tile
                    _buildFilterOptionTile(
                      context,
                      icon: Icons.star_rounded,
                      title: 'Rating',
                      valueNotifier: _selectedRatingNotifier,
                      options: [
                        '4.5 & Above',
                        '4.0 & Above',
                        '3.5 & Above',
                        'All Ratings',
                      ],
                    ),
                    AppSpacing.md.h,

                    // 6. Services Selector Tile
                    _buildFilterOptionTile(
                      context,
                      icon: Icons.verified_outlined,
                      title: 'Services',
                      valueNotifier: _selectedServicesNotifier,
                      options: [
                        'Licensed armed, Corporate visits',
                        'VIP Close Protection',
                        'Tactical Convoy Driver',
                        'Residential Security',
                      ],
                    ),
                    AppSpacing.md.h,

                    // 7. Availability Selector Tile
                    _buildFilterOptionTile(
                      context,
                      icon: Icons.schedule_rounded,
                      title: 'Availability',
                      valueNotifier: _selectedAvailabilityNotifier,
                      options: [
                        'Anytime / Immediate',
                        'Available Today',
                        'Available This Weekend',
                        'Scheduled Booking',
                      ],
                    ),
                    AppSpacing.md.h,

                    // 8. Company Selector Tile
                    _buildFilterOptionTile(
                      context,
                      icon: Icons.business_rounded,
                      title: 'Company',
                      valueNotifier: _selectedCompanyNotifier,
                      options: [
                        'SecurePro Security Ltd.',
                        'Aegis Elite Tactical',
                        'Vanguard Defense Systems',
                        'Independent Solo Operatives',
                      ],
                    ),

                    AppSpacing.xl.h,
                  ],
                ),
              ),
            ),

            // Bottom Pinned Search Button
            Padding(
              padding: context.horizontalEdgeInsets.add(
                const EdgeInsets.only(bottom: AppSpacing.lg),
              ),
              child: AppButton(
                text: 'Search',
                size: ButtonSize.large,
                onPressed: _onSearchPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required ValueNotifier<String> valueNotifier,
    required List<String> options,
  }) {
    return GestureDetector(
      onTap: () {
        _showOptionPicker(context, title, valueNotifier, options);
      },
      behavior: HitTestBehavior.opaque,
      child: QuickContainer(
        w: double.infinity,
        p: AppSpacing.md,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: context.colors.onPrimary.withValues(alpha: 0.85),
        border: Border.all(
          color: context.colors.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.colors.gold),
            AppSpacing.sm.w,
            Text(
              title,
              style: context.textTheme.bodyMedium?.medium().colour(
                context.colors.onSurface,
              ),
            ),
            const Spacer(),
            ValueListenableBuilder<String>(
              valueListenable: valueNotifier,
              builder: (context, value, _) {
                return Text(
                  value,
                  style: context.textTheme.bodySmall?.regular().colour(
                    context.colors.onSurfaceVariant,
                  ),
                );
              },
            ),
            AppSpacing.xs.w,
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionPicker(
    BuildContext context,
    String title,
    ValueNotifier<String> notifier,
    List<String> options,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.outlineVariant,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
                AppSpacing.md.h,
                Text(
                  'Select $title',
                  style: context.textTheme.titleMedium?.bold().colour(
                    context.colors.onSurface,
                  ),
                ),
                AppSpacing.sm.h,
                ...options.map((opt) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      opt,
                      style: context.textTheme.bodyMedium?.colour(
                        context.colors.onSurface,
                      ),
                    ),
                    trailing: notifier.value == opt
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: context.colors.primary,
                          )
                        : null,
                    onTap: () {
                      notifier.value = opt;
                      Navigator.pop(sheetContext);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
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
      px: 16,
      py: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                        'VIP PROTECTION',
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
                  style: context.textTheme.titleSmall?.colour(
                    context.colors.onSurface,
                  ),
                ),
                03.h,
                Text(
                  'For Every Occasion',
                  style: context.textTheme.bodySmall?.colour(
                    context.colors.onSurface,
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
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: context.colors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
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
                          'Book now',
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
              ],
            ),
          ),

          // Right: Bodyguard Photo
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: AppImage.asset(
                height: 100,

                assetPath: Assets.images.profilePicture2.path,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
