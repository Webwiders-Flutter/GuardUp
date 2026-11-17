import 'package:guardup_admin/shared/widgets/location-and-phone-code/services/phone_code_picker.services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/feedbacks/widgets/app_dialog.dart';
import '/shared/widgets/feedbacks/widgets/app_sheet.dart';
import '/shared/widgets/inputs/app_text_field.dart';

/// Reusable searchable list content for country code selection.
class CountryPickerContent extends StatefulWidget {
  final String selectedCountryCode;

  const CountryPickerContent({super.key, required this.selectedCountryCode});

  static Future<CountryWithPhoneCode?> showSheet(
    String selectedCountryCode, {
    required BuildContext context,
  }) {
    return AppSheet.show<CountryWithPhoneCode?>(
      context: context,
      child: CountryPickerContent(selectedCountryCode: selectedCountryCode),
    );
  }

  static Future<CountryWithPhoneCode?> showDialog(
    String selectedCountryCode, {
    required BuildContext context,
  }) {
    return AppDialogs.show<CountryWithPhoneCode?>(
      context: context,
      child: CountryPickerContent(selectedCountryCode: selectedCountryCode),
    );
  }

  @override
  State<CountryPickerContent> createState() => _CountryPickerContentState();
}

class _CountryPickerContentState extends State<CountryPickerContent> {
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
      height: MediaQuery.sizeOf(context).height * 0.75,
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
                    'Select Country',
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
                hintText: 'Search country or dial code...',
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

          // Country List
          Expanded(
            child: ValueListenableBuilder<Map<String, CountryWithPhoneCode>>(
              valueListenable: LocationPhoneCodeServices.phoneCountries,
              builder: (context, allCountries, _) {
                if (allCountries.isEmpty) {
                  return FutureBuilder<void>(
                    future: LocationPhoneCodeServices.init(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator.adaptive(
                            valueColor: AlwaysStoppedAnimation(colors.primary),
                          ),
                        );
                      }

                      return _buildFilteredList(context);
                    },
                  );
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
        final list = LocationPhoneCodeServices.filterPhoneCountries(query);

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
                  'No countries found',
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
            final country = list[index];
            final isSelected =
                country.countryCode.toUpperCase() ==
                widget.selectedCountryCode.toUpperCase();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Material(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.08)
                    : colors.transparent,
                borderRadius: AppRadius.mdRadius,
                child: InkWell(
                  borderRadius: AppRadius.mdRadius,
                  onTap: () => Navigator.of(context).pop(country),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 2,
                    ),
                    child: Row(
                      children: [
                        Text(
                          LocationPhoneCodeServices.countryFlagEmoji(
                            country.countryCode,
                          ),
                          style: const TextStyle(fontSize: 20),
                        ),
                        AppSpacing.md.w,
                        Expanded(
                          child: Text(
                            country.countryName ?? '',
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
                        AppSpacing.sm.w,
                        Text(
                          '+${country.phoneCode}',
                          style: context.textTheme.bodyMedium
                              ?.semiBold()
                              .colour(
                                isSelected
                                    ? colors.primary
                                    : colors.onSurfaceSecondary,
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
}
