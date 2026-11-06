import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/app/routes/app_routes.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/state/api_state.dart';
import '/features/auth/auth.dart';
import '/features/body_guard/body_guard.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.state.dart';

/// Tab content rendering the list of active bodyguard operatives deployed by the company.
class CompanyBodyguardsTab extends StatelessWidget {
  final List<BodyGuardModel>? bodyguards;
  final UserRole role;
  final _searchController = TextEditingController();
  CompanyBodyguardsTab({super.key, this.bodyguards, required this.role});

  @override
  Widget build(BuildContext context) {
    final effectiveGuards = bodyguards ?? BodyGuardModel.fakeData;

    return AppPagination<BodyGuardModel>.list(
      state: PaginationState<BodyGuardModel>(
        items: effectiveGuards,
        total: effectiveGuards.length,
        status: const ApiState.success(null),
      ),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField.search(
            controller: _searchController,
            size: AppInputSize.small,
            decoration: InputDecoration(
              hintText: 'Search by name, clearance, or skill...',
              suffixIcon: Padding(
                padding: AppSpacing.sm.allPadding,
                child: QuickContainer(
                  w: 36,
                  h: 36,
                  radius: AppRadius.md,
                  color: context.colors.primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: context.colors.primary.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.tune_rounded,
                    color: context.colors.primary,
                    size: AppSizes.iconSm,
                  ),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.xl.toBorderRadius,
                borderSide: BorderSide(color: context.colors.outlineVariant),
              ),
              fillColor: context.colors.onPrimary,
            ),
            style: TextStyle(color: context.colors.onSurface),
          ),
          AppSpacing.lg.h,
        ],
      ),
      padding: context.horizontalEdgeInsets + AppSpacing.md.yPadding,
      separatorBuilder: (context, index) => AppSpacing.md.h,
      emptyBuilder: (context) => Padding(
        padding: AppSpacing.xxl.allPadding,
        child: Center(
          child: Text(
            'No bodyguards found for this company.',
            style: context.textTheme.bodyMedium?.colour(
              context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
      itemBuilder: (context, guard, index) {
        return BodyGuardCard(
          bodyguard: guard,
          role: role,
          onTap: () =>
              context.push(AppRoutes.customerBodyguardProfile, extra: guard),
          onBookNow: () => context.push(AppRoutes.customerBookingDetails),
        );
      },
    );
  }
}
