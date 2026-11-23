import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/body_guard/body_guard.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../widgets/customer_services_row.widget.dart';

/// Full screen presenting all service categories in a responsive grid layout.
/// Allows searching through categories and selecting a service to view bodyguards.
class AllServicesScreen extends StatefulWidget {
  static const route = '/services';

  final ValueChanged<ServiceItemModel?>? onServiceSelected;

  const AllServicesScreen({
    super.key,
    this.onServiceSelected,
  });

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _searchQueryNotifier.value = _searchController.text.trim();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  void _onCategoryTapped(ServiceItemModel? service) {
    if (widget.onServiceSelected != null) {
      widget.onServiceSelected!(service);
      context.pop();
      return;
    }

    // Default action: navigate to company/platform bodyguards listing
    context.push(CompanyBodyguardsScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: const AppAppBar(
        title: 'All Services',
        showBackIcon: true,
        alignTitle: AlignTitle.left,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: AppTextField.search(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search services by name...',
                ),
                size: AppInputSize.small,
              ),
            ),

            // 2. Grid of Services
            Expanded(
              child: BlocBuilder<ServicesCubit, List<ServiceItemModel>>(
                builder: (context, services) {
                  // Trigger load if empty
                  if (services.isEmpty) {
                    context.read<ServicesCubit>().loadServices();
                    return Center(
                      child: CircularProgressIndicator.adaptive(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.colors.primary,
                        ),
                      ),
                    );
                  }

                  return ValueListenableBuilder<String>(
                    valueListenable: _searchQueryNotifier,
                    builder: (context, query, _) {
                      final filteredServices = query.isEmpty
                          ? services
                          : services.where((s) {
                              final nameMatch = s.name.toLowerCase().contains(
                                    query.toLowerCase(),
                                  );
                              final descMatch = s.description != null &&
                                  s.description!.toLowerCase().contains(
                                        query.toLowerCase(),
                                      );
                              return nameMatch || descMatch;
                            }).toList();

                      if (filteredServices.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 56,
                                color: context.colors.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                              AppSpacing.md.h,
                              Text(
                                'No services found',
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              AppSpacing.xs.h,
                              Text(
                                'Try a different search term',
                                style: context.textTheme.bodySmall?.colour(
                                  context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Total items = 1 ('All' tile when no query) + filtered services
                      final showAllTile = query.isEmpty;
                      final itemCount =
                          filteredServices.length + (showAllTile ? 1 : 0);

                      return RefreshIndicator(
                        onRefresh: () =>
                            context.read<ServicesCubit>().loadServices(
                                  forceRefresh: true,
                                ),
                        color: context.colors.primary,
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.82,
                            crossAxisSpacing: AppSpacing.sm,
                            mainAxisSpacing: AppSpacing.sm,
                          ),
                          itemCount: itemCount,
                          itemBuilder: (context, index) {
                            if (showAllTile && index == 0) {
                              return _buildServiceGridTile(
                                context,
                                title: 'All Services',
                                iconWidget: const ServiceIconWidget(
                                  isSelected: false,
                                  size: 24,
                                ),
                                onTap: () => _onCategoryTapped(null),
                              );
                            }

                            final serviceIndex =
                                showAllTile ? index - 1 : index;
                            final service = filteredServices[serviceIndex];

                            return _buildServiceGridTile(
                              context,
                              title: service.name,
                              iconWidget: ServiceIconWidget(
                                iconUrl: service.iconUrl,
                                service: service,
                                isSelected: false,
                                size: 24,
                              ),
                              onTap: () => _onCategoryTapped(service),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceGridTile(
    BuildContext context, {
    required String title,
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: QuickContainer(
        borderRadius: BorderRadius.circular(16),
        color: context.colors.surface,
        border: Border.all(
          color: context.colors.borderColor.withValues(alpha: 0.6),
          width: 1,
        ),
        px: AppSpacing.xs,
        py: AppSpacing.sm,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            QuickContainer(
              w: 52,
              h: 52,
              alignment: Alignment.center,
              borderRadius: BorderRadius.circular(14),
              color: context.colors.primary.withValues(alpha: 0.1),
              child: iconWidget,
            ),
            AppSpacing.xs.h,
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall
                  ?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  )
                  .colour(context.colors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
