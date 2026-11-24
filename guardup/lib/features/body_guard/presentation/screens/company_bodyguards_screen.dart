import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/body_guard/presentation/screens/guard_detail.screen.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/state/api_state.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../../data/model/body_guard.model.dart';
import '../widgets/body_guard_card.dart';
import '/features/body_guard/presentation/screens/body_guard_complete_profile_screen.dart';

/// Screen presenting all company or platform bodyguards with search,
/// pagination, and management actions (Add, Edit, Delete).
class CompanyBodyguardsScreen extends StatefulWidget {
  static const route = '/all-bodyguards';

  const CompanyBodyguardsScreen({super.key});

  @override
  State<CompanyBodyguardsScreen> createState() =>
      _CompanyBodyguardsScreenState();
}

class _CompanyBodyguardsScreenState extends State<CompanyBodyguardsScreen> {
  final _searchController = TextEditingController();
  late final PaginationController<BodyGuardModel> _paginationController;

  @override
  void initState() {
    super.initState();
    _paginationController = PaginationController<BodyGuardModel>(
      initialState: PaginationState<BodyGuardModel>(
        items: BodyGuardModel.fakeData,
        total: 3,
        status: const ApiState.success(null),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _paginationController.dispose();
    super.dispose();
  }

  // ── Clickflow Action Handlers ──────────────────────────────────────────────

  void _handleAddBodyguard() {
    context.push(BodyGuardCompleteProfileScreen.route);
  }

  void _handleEditBodyguard(BodyGuardModel bodyguard) {
    context.push(
      BodyGuardCompleteProfileScreen.route,
      extra: bodyguard,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar.transparent(
        title: 'All Bodyguards',
        fontSize: 14,
        showBackIcon: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.md.h,
            // -----------------------------------------------------------------
            // 1. Search Bar & Add Bodyguard CTA Row
            // -----------------------------------------------------------------
            Padding(
              padding: context.horizontalEdgeInsets,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppTextField.search(
                      controller: _searchController,
                      size: AppInputSize.small,
                      decoration: InputDecoration(
                        hintText: 'Search bodyguards near you...',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.xl.toBorderRadius,
                          borderSide: BorderSide(
                            color: context.colors.outlineVariant,
                          ),
                        ),
                        fillColor: context.colors.onPrimary,
                      ),
                      style: TextStyle(color: context.colors.onSurface),
                    ),
                  ),
                  AppSpacing.sm.w,
                  Expanded(
                    child: AppButton(
                      text: 'Add',
                      isFlexible: true,
                      leading: Icon(
                        Icons.add_rounded,
                        size: AppSizes.iconMd,
                        color: context.colors.onPrimary,
                      ),
                      type: ButtonType.primary,
                      size: ButtonSize.normal,
                      onPressed: _handleAddBodyguard,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.md.h,

            // -----------------------------------------------------------------
            // 2. Paginated Bodyguards List using AppPagination.list
            // -----------------------------------------------------------------
            Expanded(
              child: AppPagination<BodyGuardModel>.list(
                controller: _paginationController,
                padding: context.horizontalEdgeInsets + AppSpacing.lg.bPadding,
                separatorBuilder: (context, index) => AppSpacing.md.h,
                emptyBuilder: (context) => Center(
                  child: Padding(
                    padding: AppSpacing.xxl.allPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.security_rounded,
                          size: AppSizes.icon2Xl,
                          color: context.colors.outline,
                        ),
                        AppSpacing.md.h,
                        Text(
                          'No bodyguards found',
                          style: context.textTheme.titleSmall?.semiBold(),
                        ),
                        AppSpacing.xs.h,
                        Text(
                          'Try adjusting your search criteria.',
                          style: context.textTheme.bodySmall?.colour(
                            context.colors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                itemBuilder: (context, guard, index) {
                  return BodyGuardCard(
                    bodyguard: guard,
                    onTap: () {
                      context.push(GuardDetailScreen.route, extra: guard);
                    },
                    // onTap: () => _handleEditBodyguard(guard),
                    onEdit: () => _handleEditBodyguard(guard),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
