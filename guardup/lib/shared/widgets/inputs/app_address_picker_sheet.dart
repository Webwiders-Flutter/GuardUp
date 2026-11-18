import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/services/location/address_search_service.dart';
import '/shared/widgets/inputs/app_text_field.dart';

class AppAddressPickerSheet extends StatefulWidget {
  const AppAddressPickerSheet({super.key});

  static Future<PlaceSuggestion?> show(BuildContext context) {
    return showModalBottomSheet<PlaceSuggestion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (_) => const AppAddressPickerSheet(),
    );
  }

  @override
  State<AppAddressPickerSheet> createState() => _AppAddressPickerSheetState();
}

class _AppAddressPickerSheetState extends State<AppAddressPickerSheet> {
  final _searchController = TextEditingController();
  final _service = sl.isRegistered<AddressSearchService>()
      ? sl<AddressSearchService>()
      : AddressSearchService();

  Timer? _debounce;
  bool _isLoading = false;
  List<PlaceSuggestion> _suggestions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isLoading = true);
      final results = await _service.searchPlaces(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _handleSelect(PlaceSuggestion suggestion) async {
    setState(() => _isLoading = true);
    final detailed = await _service.getPlaceDetails(suggestion);
    if (mounted) {
      context.pop(detailed ?? suggestion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: QuickContainer(
                w: 40,
                h: 4,
                radius: AppRadius.full,
                color: context.colors.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            AppSpacing.md.h,

            // Header Row
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: context.colors.primary,
                  size: AppSizes.iconMd,
                ),
                AppSpacing.xs.w,
                Expanded(
                  child: Text(
                    'Select Company Address',
                    style: context.textTheme.titleMedium?.bold(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
            AppSpacing.sm.h,

            // Search text field
            AppTextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search street, building, city...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.colors.primary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
            AppSpacing.md.h,

            // Results / Loading / Empty state
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              )
            else if (_suggestions.isNotEmpty)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: context.colors.outlineVariant.withValues(alpha: 0.2),
                  ),
                  itemBuilder: (context, index) {
                    final item = _suggestions[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      leading: QuickContainer(
                        w: 36,
                        h: 36,
                        shape: QuickContainerShape.circle,
                        color: context.colors.primary.withValues(alpha: 0.12),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.location_pin,
                          color: context.colors.primary,
                          size: AppSizes.iconSm,
                        ),
                      ),
                      title: Text(
                        item.mainText ?? item.description,
                        style: context.textTheme.bodyMedium?.bold(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: item.secondaryText != null
                          ? Text(
                              item.secondaryText!,
                              style: context.textTheme.bodySmall?.colour(
                                context.colors.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      onTap: () => _handleSelect(item),
                    );
                  },
                ),
              )
            else if (_searchController.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Center(
                  child: Text(
                    'No addresses found for "${_searchController.text.trim()}".',
                    style: context.textTheme.bodyMedium?.colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 40,
                        color: context.colors.onSurfaceVariant
                            .withValues(alpha: 0.4),
                      ),
                      AppSpacing.xs.h,
                      Text(
                        'Type your business address to search',
                        style: context.textTheme.bodySmall?.colour(
                          context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
