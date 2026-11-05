import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
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

class _BodyguardsListScreenState extends State<BodyguardsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');
  final ValueNotifier<String> _rosterTypeNotifier = ValueNotifier<String>('Solo');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _searchQueryNotifier.value = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    _rosterTypeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allBodyguards = CustomerBodyguardItem.sampleBodyguards;
    final allCompanies = CustomerCompanyItem.sampleCompanies;

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppAppBar.transparent(
        title: 'Bodyguards',
        showBackIcon: true,
        alignTitle: AlignTitle.center,
        onBackTap: () => context.pop(),
      ),
      body: Stack(
        children: [
          // Ambient decorative top-right glow
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.colors.primary.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
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

                      // Solo vs Company Toggle Tabs
                      ValueListenableBuilder<String>(
                        valueListenable: _rosterTypeNotifier,
                        builder: (context, activeType, _) {
                          return Container(
                            height: 44,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: context.colors.outlineVariant
                                    .withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: ['Solo', 'Company'].map((type) {
                                final isSelected = type == activeType;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => _rosterTypeNotifier.value = type,
                                    behavior: HitTestBehavior.opaque,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? context.colors.primaryGradient
                                            : null,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.sm,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: context.colors.primary
                                                      .withValues(alpha: 0.25),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        type,
                                        style: context.textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            )
                                            .colour(
                                              isSelected
                                                  ? context.colors.onPrimary
                                                  : context.colors.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                      AppSpacing.md.h,
                    ],
                  ),
                ),

                // Dynamic Bodyguard / Company List View
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _rosterTypeNotifier,
                    builder: (context, rosterType, _) {
                      if (rosterType == 'Company') {
                        return ListView.separated(
                          padding: context.horizontalEdgeInsets.add(
                            const EdgeInsets.only(bottom: AppSpacing.xxl),
                          ),
                          itemCount: allCompanies.length,
                          separatorBuilder: (context, index) => AppSpacing.md.h,
                          itemBuilder: (context, index) {
                            final comp = allCompanies[index];
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

                      // Solo Bodyguards List filtered by search query
                      return ValueListenableBuilder<String>(
                        valueListenable: _searchQueryNotifier,
                        builder: (context, query, _) {
                          final filteredGuards = allBodyguards.where((bg) {
                            if (query.isEmpty) return true;
                            final nameMatch = bg.model.user.name
                                .toLowerCase()
                                .contains(query);
                            final skillMatch = bg.tagLabels.any(
                              (t) => t.toLowerCase().contains(query),
                            );
                            return nameMatch || skillMatch;
                          }).toList();

                          if (filteredGuards.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 48,
                                    color: context.colors.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                  AppSpacing.sm.h,
                                  Text(
                                    'No operatives match your criteria',
                                    style: context.textTheme.bodyMedium?.colour(
                                      context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: context.horizontalEdgeInsets.add(
                              const EdgeInsets.only(bottom: AppSpacing.xxl),
                            ),
                            itemCount: filteredGuards.length,
                            separatorBuilder: (context, index) =>
                                AppSpacing.md.h,
                            itemBuilder: (context, index) {
                              final guardItem = filteredGuards[index];
                              return CustomerBodyguardCardWidget(
                                item: guardItem,
                                isCompact: false,
                                onTap: () {
                                  context.push(
                                    AppRoutes.bodyguardInformation,
                                    extra: guardItem.model,
                                  );
                                },
                                onBookNow: () {
                                  context.push(
                                    AppRoutes.bodyguardInformation,
                                    extra: guardItem.model,
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

