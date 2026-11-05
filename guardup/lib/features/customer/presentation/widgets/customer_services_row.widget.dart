import 'package:flutter/material.dart';
import 'package:guardup/gen/assets.gen.dart';
import 'package:guardup/shared/widgets/sections/app_image.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '../../data/model/customer_home_data.dart';

/// Horizontal row of service categories with interactive selection.
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

  @override
  Widget build(BuildContext context) {
    final categories = CustomerServiceCategory.defaultCategories;

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
              onTap: onViewAll,
              behavior: HitTestBehavior.opaque,
              child: Text(
                'View all',
                style: context.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w600)
                    .colour(context.colors.gold),
              ),
            ),
          ],
        ),
        AppSpacing.sm.h,

        // Items Row
        ValueListenableBuilder<String>(
          valueListenable: selectedCategoryIdNotifier,
          builder: (context, selectedId, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: categories.map((cat) {
                final isSelected = cat.id == selectedId;
                return GestureDetector(
                  onTap: () {
                    selectedCategoryIdNotifier.value = cat.id;
                    // onCategorySelected?.call(cat.id);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QuickContainer(
                        w: 45,
                        h: 45,
                        alignment: .center,
                        borderRadius: BorderRadius.circular(16),
                        gradient: isSelected
                            ? context.colors.primaryGradient
                            : null,
                        color: isSelected ? null : Color(0xff191B23),
                        border: Border.all(
                          color: isSelected
                              ? context.colors.primary
                              : Color(0xff32353D),
                          width: 1,
                        ),

                        shadows: isSelected
                            ? [
                                BoxShadow(
                                  color: context.colors.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                        child: AppImage.svgAsset(
                          assetPath: cat.icon,
                          width: 20,
                          height: 20,
                          color: isSelected
                              ? context.colors.onPrimary
                              : context.colors.primary,
                        ),
                      ),
                      AppSpacing.xs.h,
                      Text(
                        cat.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: context.textTheme.labelSmall
                            ?.copyWith(
                              fontSize: 10.5,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            )
                            .colour(
                              isSelected
                                  ? context.colors.primary
                                  : context.colors.onSurfaceVariant.withValues(
                                      alpha: 0.7,
                                    ),
                            ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
