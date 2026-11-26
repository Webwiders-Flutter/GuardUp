import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/auth.dart';
import '/features/body_guard/body_guard.dart';
import '/features/company/company.dart';
import '/features/customer/presentation/screens/bodyguards_list_screen.dart';
import '/features/services/services.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../widgets/customer_promo_banner.widget.dart';
import '../widgets/sheets/company_picker_sheet.dart';
import '../widgets/sheets/services_picker_sheet.dart';

/// Screen 2: Search & Filter Bodyguards screen allowing customers to filter
/// by location/address, gender, hourly rate, rating, service type, availability, and company.
class SearchBodyguardsScreen extends StatefulWidget {
  static const route = '/search-bodyguards';

  final BodyguardFilters? initialFilters;
  final bool? returnResult;
  final bool? lockCompany;

  const SearchBodyguardsScreen({
    super.key,
    this.initialFilters,
    this.returnResult = false,
    this.lockCompany = false,
  });

  @override
  State<SearchBodyguardsScreen> createState() => _SearchBodyguardsScreenState();
}

class _SearchBodyguardsScreenState extends State<SearchBodyguardsScreen> {
  static const double _minRate = 0;
  static const double _maxRate = 300;

  late final TextEditingController _locationController;
  final ValueNotifier<GenderType?> _genderFilterNotifier =
      ValueNotifier<GenderType?>(null);
  late final ValueNotifier<RangeValues> _rateRangeNotifier;
  late final ValueNotifier<double?> _selectedRatingNotifier;
  final ValueNotifier<List<ServiceModel>> _selectedServicesNotifier =
      ValueNotifier<List<ServiceModel>>([]);
  late final ValueNotifier<BodyguardAvailabilityStatus?>
  _selectedAvailabilityNotifier;
  final ValueNotifier<CompanyModel?> _selectedCompanyNotifier =
      ValueNotifier<CompanyModel?>(null);
  String? _selectedCompanyId;
  List<String> _selectedServiceIds = const [];

  static const List<GenderType?> _genderOptions = [null, ...GenderType.values];

  static const List<({String label, double? value})> _ratingOptions = [
    (label: 'All Ratings', value: null),
    (label: '4.5 & Above', value: 4.5),
    (label: '4.0 & Above', value: 4.0),
    (label: '3.5 & Above', value: 3.5),
  ];

  static const List<BodyguardAvailabilityStatus?> _availabilityOptions = [
    null,
    ...BodyguardAvailabilityStatus.values,
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFilters;
    _locationController = TextEditingController(text: initial?.address ?? '');
    _genderFilterNotifier.value = initial?.gender;
    _rateRangeNotifier = ValueNotifier<RangeValues>(
      RangeValues(
        (initial?.minHourlyRate ?? _minRate).clamp(_minRate, _maxRate),
        (initial?.maxHourlyRate ?? _maxRate).clamp(_minRate, _maxRate),
      ),
    );
    _selectedRatingNotifier = ValueNotifier<double?>(initial?.minRating);
    _selectedAvailabilityNotifier = ValueNotifier<BodyguardAvailabilityStatus?>(
      initial?.availability,
    );
    _selectedCompanyId = initial?.companyId;
    _selectedServiceIds = initial?.serviceIds ?? const [];
    _hydrateInitialSelections(initial);
  }

  Future<void> _hydrateInitialSelections(BodyguardFilters? initial) async {
    if (initial == null) return;

    if (initial.serviceIds != null && initial.serviceIds!.isNotEmpty) {
      if (sl.isRegistered<ServicesCatalogCubit>()) {
        final cubit = sl<ServicesCatalogCubit>();
        if (cubit.state.dataOrNull == null) {
          await cubit.load();
        }
        final catalog = cubit.state.dataOrNull;
        if (catalog != null && mounted) {
          final idSet = initial.serviceIds!.toSet();
          _selectedServicesNotifier.value = catalog
              .where((s) => idSet.contains(s.id))
              .toList();
        }
      }
    }

    final companyId = initial.companyId;
    if (companyId != null &&
        companyId.isNotEmpty &&
        sl.isRegistered<CompanyRepository>()) {
      try {
        final company = await sl<CompanyRepository>().getDetails(companyId);
        if (mounted && _selectedCompanyId == companyId) {
          _selectedCompanyNotifier.value = company;
        }
      } catch (_) {
        // Ignore hydration errors; _selectedCompanyId still preserves selection.
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _genderFilterNotifier.dispose();
    _rateRangeNotifier.dispose();
    _selectedRatingNotifier.dispose();
    _selectedServicesNotifier.dispose();
    _selectedAvailabilityNotifier.dispose();
    _selectedCompanyNotifier.dispose();
    super.dispose();
  }

  BodyguardFilters _buildFilters() {
    final addressText = _locationController.text.trim();
    final range = _rateRangeNotifier.value;
    final companyId = _selectedCompanyNotifier.value?.id ?? _selectedCompanyId;
    final selectedServices = _selectedServicesNotifier.value;
    final serviceIds = selectedServices.isNotEmpty
        ? selectedServices.map((s) => s.id).toList()
        : (_selectedServiceIds.isNotEmpty ? _selectedServiceIds : null);

    return BodyguardFilters(
      statuses: const [UserStatus.active],
      ownership: companyId != null
          ? BodyguardOwnership.companyManaged
          : BodyguardOwnership.solo,
      companyId: companyId,
      availability: _selectedAvailabilityNotifier.value,
      minHourlyRate: range.start > _minRate ? range.start : null,
      maxHourlyRate: range.end < _maxRate ? range.end : null,
      minRating: _selectedRatingNotifier.value,
      serviceIds: serviceIds,
      address: addressText.isNotEmpty ? addressText : null,
      gender: _genderFilterNotifier.value,
    );
  }

  void _onSearchPressed() {
    final filters = _buildFilters();
    if (widget.returnResult ?? false) {
      context.pop(filters);
      return;
    }
    context.push(BodyguardsListScreen.route, extra: filters);
  }

  Future<void> _pickCompany() async {
    if (widget.lockCompany ?? false) return;
    final result = await CompanyPickerSheet.show(
      context,
      selectedCompanyId:
          _selectedCompanyNotifier.value?.id ?? _selectedCompanyId,
    );
    if (result != null && mounted) {
      _selectedCompanyId = result.company?.id;
      _selectedCompanyNotifier.value = result.company;
    }
  }

  Future<void> _pickServices() async {
    final result = await ServicesPickerSheet.show(
      context,
      selectedServices: _selectedServicesNotifier.value,
      selectedServiceIds: _selectedServiceIds,
    );
    if (result != null && mounted) {
      _selectedServiceIds = result.map((s) => s.id).toList();
      _selectedServicesNotifier.value = result;
    }
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
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _locationController,
                      builder: (context, value, _) {
                        final hasAddress = value.text.trim().isNotEmpty;
                        return AppTextField.search(
                          controller: _locationController,
                          size: AppInputSize.small,
                          decoration: InputDecoration(
                            hintText: 'Search by location or address...',
                            prefixIcon: Icon(
                              Icons.location_on,
                              color: context.colors.primary,
                              size: 19,
                            ),
                            suffixIcon: hasAddress
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                      right: AppSpacing.md,
                                    ),
                                    child: _buildFilterDot(context),
                                  )
                                : null,
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.colors.borderColor,
                              ),
                            ),
                            fillColor: context.colors.surface,
                          ),
                          style: TextStyle(color: context.colors.onSurface),
                        );
                      },
                    ),
                    AppSpacing.md.h,

                    // 2. Gender / Category Filter Tabs (All, Male, Female, Other)
                    ValueListenableBuilder<GenderType?>(
                      valueListenable: _genderFilterNotifier,
                      builder: (context, activeGender, _) {
                        return Row(
                          children: _genderOptions.map((gender) {
                            final isSelected = gender == activeGender;
                            final label = gender == null
                                ? 'All'
                                : gender.label(context.l10n);
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xxs,
                                ),
                                child: GestureDetector(
                                  onTap: () =>
                                      _genderFilterNotifier.value = gender,
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
                                          : const Color(0xFF141824),
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
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                    const CustomerPromoBannerWidget(
                      badgeText: 'VIP PROTECTION',
                      isCompact: true,
                    ),
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
                              ValueListenableBuilder<RangeValues>(
                                valueListenable: _rateRangeNotifier,
                                builder: (context, range, _) {
                                  final isRateActive =
                                      range.start > _minRate ||
                                      range.end < _maxRate;
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Hourly Rate',
                                        style: context.textTheme.bodyMedium
                                            ?.medium()
                                            .colour(context.colors.onSurface),
                                      ),
                                      if (isRateActive) ...[
                                        AppSpacing.xs.w,
                                        _buildFilterDot(context),
                                      ],
                                    ],
                                  );
                                },
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
                                      color: context.colors.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm,
                                      ),
                                      border: Border.all(
                                        color: context.colors.primary
                                            .withValues(alpha: 0.4),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      '\$${range.start.round()} - \$${range.end.round()}',
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(fontSize: 11)
                                          .colour(context.colors.primary),
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
                                  min: _minRate,
                                  max: _maxRate,
                                  divisions: 30,
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
                                '\$0/hr',
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
                    ValueListenableBuilder<double?>(
                      valueListenable: _selectedRatingNotifier,
                      builder: (context, rating, _) {
                        final label = _ratingOptions
                            .firstWhere(
                              (opt) => opt.value == rating,
                              orElse: () => _ratingOptions.first,
                            )
                            .label;
                        return _buildFilterTile(
                          context,
                          icon: Icons.star_rounded,
                          title: 'Rating',
                          displayValue: label,
                          isActive: rating != null,
                          onTap: () => _showRatingPicker(context),
                        );
                      },
                    ),
                    AppSpacing.md.h,

                    // 6. Services Selector Tile (Paginated Sheet)
                    ValueListenableBuilder<List<ServiceModel>>(
                      valueListenable: _selectedServicesNotifier,
                      builder: (context, services, _) {
                        final isServicesActive =
                            services.isNotEmpty ||
                            _selectedServiceIds.isNotEmpty;
                        final label = services.isEmpty
                            ? (_selectedServiceIds.isNotEmpty
                                  ? '${_selectedServiceIds.length} Selected'
                                  : 'All Services')
                            : services.map((s) => s.name).join(', ');
                        return _buildFilterTile(
                          context,
                          icon: Icons.verified_outlined,
                          title: 'Services',
                          displayValue: label,
                          isActive: isServicesActive,
                          onTap: _pickServices,
                        );
                      },
                    ),
                    AppSpacing.md.h,

                    // 7. Availability Selector Tile (Enum + Any)
                    ValueListenableBuilder<BodyguardAvailabilityStatus?>(
                      valueListenable: _selectedAvailabilityNotifier,
                      builder: (context, availability, _) {
                        final label = availability?.label ?? 'Any';
                        return _buildFilterTile(
                          context,
                          icon: Icons.schedule_rounded,
                          title: 'Availability',
                          displayValue: label,
                          isActive: availability != null,
                          onTap: () => _showAvailabilityPicker(context),
                        );
                      },
                    ),
                    AppSpacing.md.h,

                    // 8. Company Selector Tile (Paginated Sheet, locked on Company Detail)
                    ValueListenableBuilder<CompanyModel?>(
                      valueListenable: _selectedCompanyNotifier,
                      builder: (context, company, _) {
                        final isLocked = widget.lockCompany ?? false;
                        final hasCompany =
                            company != null || _selectedCompanyId != null;
                        final label =
                            company?.displayName ??
                            (isLocked ? 'Current Company' : 'All Companies');
                        return _buildFilterTile(
                          context,
                          icon: Icons.business_rounded,
                          title: 'Company',
                          displayValue: label,
                          isActive: hasCompany && !isLocked,
                          isLocked: isLocked,
                          onTap: _pickCompany,
                        );
                      },
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
                height: 45,
                size: ButtonSize.large,
                onPressed: _onSearchPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDot(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: context.colors.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildFilterTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String displayValue,
    required VoidCallback onTap,
    bool isActive = false,
    bool isLocked = false,
  }) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: QuickContainer(
        w: double.infinity,
        p: AppSpacing.md,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: context.colors.onPrimary.withValues(
          alpha: isLocked ? 0.55 : 0.85,
        ),
        border: Border.all(
          color: context.colors.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.colors.primary),
            AppSpacing.sm.w,
            Text(title, style: context.textTheme.bodyMedium?.medium()),
            if (isActive) ...[AppSpacing.xs.w, _buildFilterDot(context)],
            AppSpacing.md.w,
            Expanded(
              child: Text(
                displayValue,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.regular().colour(
                  context.colors.onSurfaceVariant,
                ),
              ),
            ),
            AppSpacing.xs.w,
            Icon(
              isLocked
                  ? Icons.lock_outline_rounded
                  : Icons.chevron_right_rounded,
              size: isLocked ? 18 : 20,
              color: context.colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingPicker(BuildContext context) {
    _showGenericPicker<double?>(
      context,
      title: 'Select Rating',
      currentValue: _selectedRatingNotifier.value,
      options: _ratingOptions
          .map((opt) => (label: opt.label, value: opt.value))
          .toList(),
      onSelected: (val) => _selectedRatingNotifier.value = val,
    );
  }

  void _showAvailabilityPicker(BuildContext context) {
    _showGenericPicker<BodyguardAvailabilityStatus?>(
      context,
      title: 'Select Availability',
      currentValue: _selectedAvailabilityNotifier.value,
      options: _availabilityOptions
          .map((opt) => (label: opt?.label ?? 'Any', value: opt))
          .toList(),
      onSelected: (val) => _selectedAvailabilityNotifier.value = val,
    );
  }

  void _showGenericPicker<T>(
    BuildContext context, {
    required String title,
    required T currentValue,
    required List<({String label, T value})> options,
    required ValueChanged<T> onSelected,
  }) {
    showModalBottomSheet<void>(
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
                  title,
                  style: context.textTheme.titleMedium?.bold().colour(
                    context.colors.onSurface,
                  ),
                ),
                AppSpacing.sm.h,
                ...options.map((opt) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      opt.label,
                      style: context.textTheme.bodyMedium?.colour(
                        context.colors.onSurface,
                      ),
                    ),
                    trailing: currentValue == opt.value
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: context.colors.primary,
                          )
                        : null,
                    onTap: () {
                      onSelected(opt.value);
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
}
