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
import '/features/services/services.dart';
import '/shared/bloc/pagination/pagination_event.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';

/// Paginated, searchable modal bottom sheet for multi-selecting security services.
class ServicesPickerSheet extends StatelessWidget {
  final List<ServiceModel> selectedServices;
  final List<String> selectedServiceIds;

  const ServicesPickerSheet({
    super.key,
    this.selectedServices = const [],
    this.selectedServiceIds = const [],
  });

  static Future<List<ServiceModel>?> show(
    BuildContext context, {
    List<ServiceModel> selectedServices = const [],
    List<String> selectedServiceIds = const [],
  }) {
    return showModalBottomSheet<List<ServiceModel>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => BlocProvider(
        create: (_) =>
            (sl.isRegistered<ServicesBloc>()
                    ? sl<ServicesBloc>()
                    : ServicesBloc(sl<ServicesRepository>()))
                ..add(const PaginationLoadRequested()),
        child: _ServicesPickerView(
          selectedServices: selectedServices,
          selectedServiceIds: selectedServiceIds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          (sl.isRegistered<ServicesBloc>()
                  ? sl<ServicesBloc>()
                  : ServicesBloc(sl<ServicesRepository>()))
              ..add(const PaginationLoadRequested()),
      child: _ServicesPickerView(
        selectedServices: selectedServices,
        selectedServiceIds: selectedServiceIds,
      ),
    );
  }
}

class _ServicesPickerView extends StatefulWidget {
  final List<ServiceModel> selectedServices;
  final List<String> selectedServiceIds;

  const _ServicesPickerView({
    required this.selectedServices,
    this.selectedServiceIds = const [],
  });

  @override
  State<_ServicesPickerView> createState() => _ServicesPickerViewState();
}

class _ServicesPickerViewState extends State<_ServicesPickerView> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  late final PaginationController<ServiceModel> _paginationController;
  late final Map<String, ServiceModel> _selectedById;
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedById = {
      for (final service in widget.selectedServices) service.id: service,
    };
    _selectedIds = {
      ...widget.selectedServiceIds,
      ...widget.selectedServices.map((s) => s.id),
    };

    final bloc = context.read<ServicesBloc>();
    _paginationController = PaginationController<ServiceModel>(
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
      context.read<ServicesBloc>().add(PaginationSearchChanged(query));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _paginationController.dispose();
    super.dispose();
  }

  void _toggleService(ServiceModel service) {
    setState(() {
      if (_selectedIds.contains(service.id)) {
        _selectedIds.remove(service.id);
        _selectedById.remove(service.id);
      } else {
        _selectedIds.add(service.id);
        _selectedById[service.id] = service;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.72;

    return BlocListener<ServicesBloc, ServicesState>(
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
                        'Select Services',
                        style: context.textTheme.titleMedium?.bold().colour(
                          context.colors.onSurface,
                        ),
                      ),
                    ),
                    if (_selectedIds.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedIds.clear();
                            _selectedById.clear();
                          });
                        },
                        child: Text(
                          'Clear (${_selectedIds.length})',
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
                    hintText: 'Search services...',
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
                child: AppPagination<ServiceModel>.list(
                  controller: _paginationController,
                  padding:
                      context.horizontalEdgeInsets + AppSpacing.sm.yPadding,
                  separatorBuilder: (_, _) => AppSpacing.xs.h,
                  emptyBuilder: (context) => Center(
                    child: Padding(
                      padding: AppSpacing.xl.allPadding,
                      child: Text(
                        'No services found.',
                        style: context.textTheme.bodyMedium?.colour(
                          context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  itemBuilder: (context, service, _) {
                    final isSelected = _selectedIds.contains(service.id);
                    if (isSelected && !_selectedById.containsKey(service.id)) {
                      _selectedById[service.id] = service;
                    }
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
                          Icons.verified_outlined,
                          size: AppSizes.iconSm,
                          color: context.colors.primary,
                        ),
                      ),
                      title: Text(
                        service.name,
                        style: context.textTheme.bodyMedium?.medium().colour(
                          context.colors.onSurface,
                        ),
                      ),
                      subtitle: service.description?.isNotEmpty == true
                          ? Text(
                              service.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodySmall?.colour(
                                context.colors.onSurfaceVariant,
                              ),
                            )
                          : null,
                      trailing: Icon(
                        isSelected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        color: isSelected
                            ? context.colors.primary
                            : context.colors.onSurfaceVariant,
                      ),
                      onTap: () => _toggleService(service),
                    );
                  },
                ),
              ),
              Padding(
                padding: context.horizontalEdgeInsets.add(
                  const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: AppButton(
                  text: 'Apply',
                  height: 45,
                  size: ButtonSize.large,
                  onPressed: () =>
                      Navigator.pop(context, _selectedById.values.toList()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
