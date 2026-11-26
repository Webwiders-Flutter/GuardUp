import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/auth.dart';
import '/features/body_guard/body_guard.dart';
import '/shared/bloc/pagination/pagination_event.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';

/// Tab content rendering the paginated list of active bodyguard operatives deployed by the company.
class CompanyBodyguardsTab extends StatelessWidget {
  final String? companyId;
  final UserRole role;

  const CompanyBodyguardsTab({
    super.key,
    this.companyId,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BodyguardsBloc>(
        param1: BodyguardFilters(
          companyId: companyId,
          statuses: const [UserStatus.active],
        ),
      )..add(const PaginationLoadRequested()),
      child: _CompanyBodyguardsTabView(role: role),
    );
  }
}

class _CompanyBodyguardsTabView extends StatefulWidget {
  final UserRole role;

  const _CompanyBodyguardsTabView({required this.role});

  @override
  State<_CompanyBodyguardsTabView> createState() =>
      _CompanyBodyguardsTabViewState();
}

class _CompanyBodyguardsTabViewState extends State<_CompanyBodyguardsTabView> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  late final PaginationController<BodyGuardModel> _paginationController;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<BodyguardsBloc>();
    _paginationController = PaginationController<BodyGuardModel>(
      initialState: bloc.state.pagination,
      onRefresh: () async => bloc.add(const PaginationLoadRequested()),
      onLoadMore: () async => bloc.add(const PaginationNextPageRequested()),
    );

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(AppDurations.slow, () {
      if (!mounted) return;
      context.read<BodyguardsBloc>().add(PaginationSearchChanged(query));
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _paginationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BodyguardsBloc, BodyguardsState>(
      listenWhen: (previous, current) =>
          previous.pagination != current.pagination,
      listener: (context, state) =>
          _paginationController.updateState(state.pagination),
      child: AppPagination<BodyGuardModel>.list(
        controller: _paginationController,
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
        initialLoaderBuilder: (context) =>
            const BodyGuardListSkeleton(itemCount: 4),
        emptyBuilder: (context) => Padding(
          padding: AppSpacing.xxl.allPadding,
          child: Center(
            child: Text(
              'No active bodyguards found for this company.',
              style: context.textTheme.bodyMedium?.colour(
                context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
        itemBuilder: (context, guard, index) {
          return BodyGuardCard(
            bodyguard: guard,
            role: widget.role,
            onTap: () => context.push(GuardDetailScreen.route, extra: guard),
            onBookNow: () =>
                context.push(CustomerBookingDetailsScreen.route, extra: guard),
          );
        },
      ),
    );
  }
}
