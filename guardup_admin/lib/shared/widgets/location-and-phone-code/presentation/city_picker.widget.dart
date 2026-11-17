import 'package:guardup_admin/shared/widgets/location-and-phone-code/services/phone_code_picker.services.dart';
import 'package:csc_picker_plus/model/select_status_model.dart';
import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/feedbacks/widgets/app_dialog.dart';
import '/shared/widgets/feedbacks/widgets/app_sheet.dart';
import '/shared/widgets/inputs/app_text_field.dart';

/// Reusable searchable list content for city selection.
class CityPickerContent extends StatefulWidget {
  final int countryId;
  final int stateId;
  final int? selectedCityId;

  const CityPickerContent({
    super.key,
    required this.countryId,
    required this.stateId,
    this.selectedCityId,
  });

  static Future<City?> showSheet({
    required BuildContext context,
    required int countryId,
    required int stateId,
    int? selectedCityId,
  }) {
    return AppSheet.show<City?>(
      context: context,
      child: CityPickerContent(
        countryId: countryId,
        stateId: stateId,
        selectedCityId: selectedCityId,
      ),
    );
  }

  static Future<City?> showDialog({
    required BuildContext context,
    required int countryId,
    required int stateId,
    int? selectedCityId,
  }) {
    return AppDialogs.show<City?>(
      context: context,
      child: CityPickerContent(
        countryId: countryId,
        stateId: stateId,
        selectedCityId: selectedCityId,
      ),
    );
  }

  @override
  State<CityPickerContent> createState() => _CityPickerContentState();
}

class _CityPickerContentState extends State<CityPickerContent> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _queryNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _queryNotifier.value = _searchController.text;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _queryNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select City',
                    style: context.textTheme.titleMedium?.bold().colour(
                      colors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: AppSpacing.xl,
                    color: colors.onSurfaceSecondary,
                  ),
                  splashRadius: AppRadius.lg,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: AppTextField.search(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search city...',
                filled: true,
                fillColor: colors.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),

          Divider(height: 1, color: colors.borderLight),

          // City List
          Expanded(
            child: FutureBuilder<void>(
              future: LocationPhoneCodeServices.init(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator.adaptive(
                      valueColor: AlwaysStoppedAnimation(colors.primary),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildError(context);
                }

                return _buildFilteredList(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredList(BuildContext context) {
    final colors = context.colors;

    return ValueListenableBuilder<String>(
      valueListenable: _queryNotifier,
      builder: (context, query, _) {
        final list = LocationPhoneCodeServices.filterCities(
          widget.countryId,
          widget.stateId,
          query,
        );

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: AppSpacing.xxxl,
                  color: colors.onSurfaceSecondary.withValues(alpha: 0.5),
                ),
                AppSpacing.sm.h,
                Text(
                  'No cities found',
                  style: context.textTheme.bodyMedium?.colour(
                    colors.onSurfaceSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: list.length,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          itemBuilder: (context, index) {
            final city = list[index];

            final isSelected = city.id == widget.selectedCityId;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Material(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.08)
                    : colors.transparent,
                borderRadius: AppRadius.mdRadius,
                child: InkWell(
                  borderRadius: AppRadius.mdRadius,
                  onTap: () => Navigator.of(context).pop(city),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 2,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            city.name ?? '-',
                            style: context.textTheme.bodyMedium
                                ?.colour(
                                  isSelected
                                      ? colors.primary
                                      : colors.onSurface,
                                )
                                .weight(
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected) ...[
                          AppSpacing.sm.w,
                          Icon(
                            Icons.check_rounded,
                            size: AppSpacing.lg,
                            color: colors.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildError(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Text(
        'Unable to load cities',
        style: context.textTheme.bodyMedium?.colour(colors.onSurfaceSecondary),
      ),
    );
  }
}
