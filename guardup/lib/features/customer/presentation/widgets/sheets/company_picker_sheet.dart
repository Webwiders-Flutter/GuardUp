import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '/features/company/company.dart';
import '/shared/bloc/pagination/pagination_event.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';

/// Result wrapper so callers can distinguish between "cancelled" (`null`)
/// and "cleared / Any company" (`CompanyPickerResult(company: null)`).
class CompanyPickerResult {
  final CompanyModel? company;

  const CompanyPickerResult(this.company);
}

/// Paginated, searchable modal bottom sheet for picking a security company.
class CompanyPickerSheet extends StatelessWidget {
  final String? selectedCompanyId;

  const CompanyPickerSheet({super.key, this.selectedCompanyId});

  static Future<CompanyPickerResult?> show(
    BuildContext context, {
    String? selectedCompanyId,
  }) {
    return showModalBottomSheet<CompanyPickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => BlocProvider(
        create: (_) =>
            sl<CompaniesBloc>()..add(const PaginationLoadRequested()),
        child: _CompanyPickerView(selectedCompanyId: selectedCompanyId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CompaniesBloc>()..add(const PaginationLoadRequested()),
      child: _CompanyPickerView(selectedCompanyId: selectedCompanyId),
    );
  }
}

class _CompanyPickerView extends StatefulWidget {
  final String? selectedCompanyId;

  const _CompanyPickerView({this.selectedCompanyId});

  @override
  State<_CompanyPickerView> createState() => _CompanyPickerViewState();
}

class _CompanyPickerViewState extends State<_CompanyPickerView> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  late final PaginationController<CompanyModel> _paginationController;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<CompaniesBloc>();
    _paginationController = PaginationController<CompanyModel>(
      initialState: bloc.state.pagination,
      onRefresh: () async => bloc.add(const PaginationLoadRequested()),
      onLoadMore: () async => bloc.add(const PaginationNextPageRequested()),
    );
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _debounce?.cancel();
    _debounce = Timer(AppDurations.slow, () {
      if (!mounted) return;
      context.read<CompaniesBloc>().add(PaginationSearchChanged(query));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _paginationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.72;

    return BlocListener<CompaniesBloc, CompaniesState>(
      listenWhen: (prev, curr) => prev.pagination != curr.pagination,
      listener: (_, state) =>
          _paginationController.updateState(state.pagination),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: maxHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.md.h,
              Center(
                child: QuickContainer(
                  w: 36,
                  h: 4,
                  color: context.colors.outlineVariant,
                  radius: AppRadius.full,
                ),
              ),
              AppSpacing.md.h,
              Padding(
                padding: context.horizontalEdgeInsets,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Company',
                        style: context.textTheme.titleMedium?.bold().colour(
                          context.colors.onSurface,
                        ),
                      ),
                    ),
                    if (widget.selectedCompanyId != null)
                      TextButton(
                        onPressed: () => Navigator.pop(
                          context,
                          const CompanyPickerResult(null),
                        ),
                        child: Text(
                          'All Companies',
                          style: context.textTheme.labelMedium?.colour(
                            context.colors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              AppSpacing.sm.h,
              Padding(
                padding: context.horizontalEdgeInsets,
                child: AppTextField.search(
                  controller: _searchController,
                  size: AppInputSize.small,
                  decoration: InputDecoration(
                    hintText: 'Search companies...',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.xl.toBorderRadius,
                      borderSide: BorderSide(
                        color: context.colors.outlineVariant,
                      ),
                    ),
                    fillColor: context.colors.surface,
                  ),
                ),
              ),
              AppSpacing.sm.h,
              Expanded(
                child: AppPagination<CompanyModel>.list(
                  controller: _paginationController,
                  padding: context.horizontalEdgeInsets + AppSpacing.sm.yPadding,
                  separatorBuilder: (_, _) => AppSpacing.xs.h,
                  emptyBuilder: (context) => Center(
                    child: Padding(
                      padding: AppSpacing.xl.allPadding,
                      child: Text(
                        'No companies found.',
                        style: context.textTheme.bodyMedium?.colour(
                          context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  itemBuilder: (context, company, _) {
                    final isSelected = company.id == widget.selectedCompanyId;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: BorderSide(
                          color: isSelected
                              ? context.colors.primary
                              : context.colors.outlineVariant.withValues(
                                  alpha: 0.4,
                                ),
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: context.colors.primary.withValues(
                          alpha: 0.12,
                        ),
                        child: Icon(
                          Icons.business_rounded,
                          size: AppSizes.iconSm,
                          color: context.colors.primary,
                        ),
                      ),
                      title: Text(
                        company.displayName,
                        style: context.textTheme.bodyMedium?.medium().colour(
                          context.colors.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        company.experienceYearsFormatted,
                        style: context.textTheme.bodySmall?.colour(
                          context.colors.onSurfaceVariant,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: context.colors.primary,
                            )
                          : null,
                      onTap: () =>
                          Navigator.pop(context, CompanyPickerResult(company)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
