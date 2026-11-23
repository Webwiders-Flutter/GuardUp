import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/body_guard/body_guard.dart';
import 'package:guardup/shared/widgets/sections/app_image.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '../screens/all_services_screen.dart';

/// Reusable icon widget for a service category.
/// Renders network SVG, network raster images, or fallback icon.
class ServiceIconWidget extends StatelessWidget {
  final String? iconUrl;
  final ServiceItemModel? service;
  final bool isSelected;
  final double size;

  const ServiceIconWidget({
    super.key,
    this.iconUrl,
    this.service,
    this.isSelected = false,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isSelected
        ? context.colors.onPrimary
        : context.colors.primary;

    if (iconUrl != null && iconUrl!.isNotEmpty) {
      if (iconUrl!.toLowerCase().endsWith('.svg')) {
        return AppImage.svgNetwork(
          imageUrl: iconUrl,
          width: size,
          height: size,
          color: activeColor,
          errorWidget: service != null
              ? Icon(service!.icon, size: size - 2, color: activeColor)
              : Icon(Icons.shield_outlined, size: size - 2, color: activeColor),
        );
      }
      return AppImage.network(
        imageUrl: iconUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: isSelected ? context.colors.onPrimary : null,
        errorWidget: service != null
            ? Icon(service!.icon, size: size - 2, color: activeColor)
            : Icon(Icons.shield_outlined, size: size - 2, color: activeColor),
      );
    }

    if (service != null) {
      return Icon(service!.icon, size: size, color: activeColor);
    }

    // Default 'All' Menu Icon
    return AppImage.svgAsset(
      assetPath: Assets.svg.menu.path,
      width: size - 2,
      height: size - 2,
      color: activeColor,
    );
  }
}

/// Horizontal dynamic row of service categories fetched from `public.services`.
/// Displays up to 10 items on the home screen with a 'View all' action to open
/// the full category grid screen.
class CustomerServicesRowWidget extends StatelessWidget {
  final ValueNotifier<String> selectedCategoryIdNotifier;
  final ValueChanged<String>? onCategorySelected;
  final VoidCallback? onViewAll;

  const CustomerServicesRowWidget({
    super.key,
    required this.selectedCategoryIdNotifier,
    this.onCategorySelected,
    this.onViewAll,
  });

  Widget _buildCategoryItem(
    BuildContext context, {
    required String id,
    required String title,
    required bool isSelected,
    String? iconUrl,
    ServiceItemModel? service,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            QuickContainer(
              w: 48,
              h: 48,
              alignment: .center,
              borderRadius: BorderRadius.circular(16),
              gradient: isSelected ? context.colors.primaryGradient : null,
              color: isSelected ? null : context.colors.surface,
              border: Border.all(
                color: isSelected
                    ? context.colors.primary
                    : context.colors.borderColor,
                width: 1,
              ),
              shadows: isSelected
                  ? [
                      BoxShadow(
                        color: context.colors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
              child: ServiceIconWidget(
                iconUrl: iconUrl,
                service: service,
                isSelected: isSelected,
                size: 22,
              ),
            ),
            AppSpacing.xs.h,
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall
                  ?.copyWith(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  )
                  .colour(
                    isSelected
                        ? context.colors.primary
                        : context.colors.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SERVICES',
              style: context.textTheme.labelMedium
                  ?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w400)
                  .colour(context.colors.onSurfaceVariant),
            ),
            GestureDetector(
              onTap: onViewAll ?? () => context.push(AllServicesScreen.route),
              behavior: HitTestBehavior.opaque,
              child: Text(
                'View all',
                style: context.textTheme.labelSmall?.colour(
                  context.colors.primary,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.sm.h,

        // Dynamic Services List (horizontally scrollable, up to 10 items)
        BlocBuilder<ServicesCubit, List<ServiceItemModel>>(
          builder: (context, services) {
            // Trigger load if empty
            if (services.isEmpty) {
              context.read<ServicesCubit>().loadServices();
            }

            // Show at most 10 service categories on the home screen row
            final displayedServices = services.take(10).toList();

            return ValueListenableBuilder<String>(
              valueListenable: selectedCategoryIdNotifier,
              builder: (context, selectedId, _) {
                final isAllSelected = selectedId == 'all';

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 'All' Category
                      _buildCategoryItem(
                        context,
                        id: 'all',
                        title: 'All',
                        isSelected: isAllSelected,
                        onTap: () {
                          selectedCategoryIdNotifier.value = 'all';
                          onCategorySelected?.call('all');
                        },
                      ),
                      AppSpacing.sm.w,

                      // 2. Dynamic Services (up to 10 items)
                      ...displayedServices.map((service) {
                        final isSelected = service.id == selectedId;
                        return Padding(
                          padding: EdgeInsets.only(right: AppSpacing.sm),
                          child: _buildCategoryItem(
                            context,
                            id: service.id,
                            title: service.name,
                            iconUrl: service.iconUrl,
                            service: service,
                            isSelected: isSelected,
                            onTap: () {
                              selectedCategoryIdNotifier.value = service.id;
                              onCategorySelected?.call(service.id);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
