import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_event.dart';
import '/features/auth/domain/repositories/user_repository.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_address_picker_sheet.dart';
import '/shared/widgets/inputs/app_text_field.dart';

typedef KeyDetailsUpdatedCallback = void Function({
  int? experienceYears,
  num? hourlyRate,
  String? languages,
  String? certifications,
  String? address,
  double? latitude,
  double? longitude,
});

/// Modal bottom sheet for viewing and updating key bodyguard operational details.
class EditKeyDetailsSheet extends StatefulWidget {
  final String? bodyguardId;
  final int experienceYears;
  final num hourlyRate;
  final String address;
  final double? latitude;
  final double? longitude;
  final String languages;
  final String certifications;
  final KeyDetailsUpdatedCallback? onKeyDetailsUpdated;

  const EditKeyDetailsSheet({
    super.key,
    this.bodyguardId,
    required this.experienceYears,
    required this.hourlyRate,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.languages,
    required this.certifications,
    this.onKeyDetailsUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    String? bodyguardId,
    required int experienceYears,
    required num hourlyRate,
    required String address,
    required double? latitude,
    required double? longitude,
    required String languages,
    required String certifications,
    KeyDetailsUpdatedCallback? onKeyDetailsUpdated,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => EditKeyDetailsSheet(
        bodyguardId: bodyguardId,
        experienceYears: experienceYears,
        hourlyRate: hourlyRate,
        address: address,
        latitude: latitude,
        longitude: longitude,
        languages: languages,
        certifications: certifications,
        onKeyDetailsUpdated: onKeyDetailsUpdated,
      ),
    );
  }

  @override
  State<EditKeyDetailsSheet> createState() => _EditKeyDetailsSheetState();
}

class _EditKeyDetailsSheetState extends State<EditKeyDetailsSheet> {
  late final TextEditingController _expController;
  late final TextEditingController _rateController;
  late final TextEditingController _addressController;
  late final TextEditingController _languagesController;
  late final TextEditingController _certificationsController;

  double? _selectedLat;
  double? _selectedLng;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _expController = TextEditingController(
      text: widget.experienceYears > 0 ? widget.experienceYears.toString() : '',
    );
    _rateController = TextEditingController(
      text: widget.hourlyRate > 0 ? widget.hourlyRate.toStringAsFixed(0) : '',
    );
    _addressController = TextEditingController(text: widget.address);
    _languagesController = TextEditingController(text: widget.languages);
    _certificationsController = TextEditingController(
      text: widget.certifications,
    );
    _selectedLat = widget.latitude;
    _selectedLng = widget.longitude;
  }

  @override
  void dispose() {
    _expController.dispose();
    _rateController.dispose();
    _addressController.dispose();
    _languagesController.dispose();
    _certificationsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final exp = int.tryParse(_expController.text.trim()) ?? 0;
      final rate = num.tryParse(_rateController.text.trim()) ?? 0;
      final addr = _addressController.text.trim();
      final langs = _languagesController.text.trim();
      final certs = _certificationsController.text.trim();

      if (widget.bodyguardId != null && widget.bodyguardId!.isNotEmpty) {
        await Supabase.instance.client
            .from(DatabaseTables.bodyguards)
            .update({
              'experience_years': exp,
              'hourly_rate': rate,
              'languages': langs,
              'certifications': certs,
              'address': addr,
              if (_selectedLat != null) 'latitude': _selectedLat,
              if (_selectedLng != null) 'longitude': _selectedLng,
            })
            .eq('id', widget.bodyguardId!);
      } else {
        final authState = sl<AuthBloc>().state;
        final userId = authState.user?.id ?? '';
        if (userId.isNotEmpty) {
          try {
            await sl<UserRepository>().updateProfileFields(
              userId: userId,
              data: {
                'experience_years': exp,
                'hourly_rate': rate,
                'address': addr,
                if (_selectedLat != null) 'latitude': _selectedLat,
                if (_selectedLng != null) 'longitude': _selectedLng,
                'languages': langs,
                'certifications': certs,
              },
            );
          } catch (_) {
            // Fallback if migration is still pending on remote DB
            final userRow = await sl<UserRepository>().getUserData(userId);
            final meta = (userRow?['metadata'] is Map)
                ? Map<String, dynamic>.from(userRow!['metadata'] as Map)
                : <String, dynamic>{};
            meta['languages'] = langs;
            meta['certifications'] = certs;
            await sl<UserRepository>().updateProfileFields(
              userId: userId,
              data: {
                'experience_years': exp,
                'hourly_rate': rate,
                'address': addr,
                if (_selectedLat != null) 'latitude': _selectedLat,
                if (_selectedLng != null) 'longitude': _selectedLng,
                'metadata': meta,
              },
            );
          }

          sl<AuthBloc>().add(const AuthCheckStatusRequested());
        }
      }

      widget.onKeyDetailsUpdated?.call(
        experienceYears: exp,
        hourlyRate: rate,
        languages: langs,
        certifications: certs,
        address: addr,
        latitude: _selectedLat,
        longitude: _selectedLng,
      );

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.success('Key details updated successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackbar.error('Failed to update details: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            AppSpacing.md.h,
            Text(
              'Edit Key Details',
              style: context.textTheme.titleMedium?.bold().colour(
                context.colors.onSurface,
              ),
            ),
            AppSpacing.xs.h,
            Text(
              'Update your operational rates, experience, location, and credentials.',
              style: context.textTheme.bodySmall?.colour(
                context.colors.onSurfaceVariant,
              ),
            ),
            AppSpacing.lg.h,

            // 1. Experience Years
            Text(
              'Experience (Years)',
              style: context.textTheme.labelMedium?.semiBold(),
            ),
            AppSpacing.xs.h,
            AppTextField(
              controller: _expController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'e.g. 5'),
            ),
            AppSpacing.md.h,

            // 2. Hourly Rate
            Text(
              'Hourly Rate (\$/hr)',
              style: context.textTheme.labelMedium?.semiBold(),
            ),
            AppSpacing.xs.h,
            AppTextField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(hintText: 'e.g. 60'),
            ),
            AppSpacing.md.h,

            // 3. Service Area Location (Google Places API)
            Text(
              'Service Area / Location',
              style: context.textTheme.labelMedium?.semiBold(),
            ),
            AppSpacing.xs.h,
            AppTextField(
              controller: _addressController,
              readOnly: true,
              onTap: () async {
                final place = await AppAddressPickerSheet.show(context);
                if (place != null && mounted) {
                  setState(() {
                    _addressController.text = place.description;
                    _selectedLat = place.latitude;
                    _selectedLng = place.longitude;
                  });
                }
              },
              decoration: InputDecoration(
                hintText: 'Search preferred service area...',
                suffixIcon: Icon(
                  Icons.location_searching_rounded,
                  color: context.colors.primary,
                  size: AppSizes.iconSm,
                ),
              ),
            ),
            AppSpacing.md.h,

            // 4. Languages
            Text('Languages', style: context.textTheme.labelMedium?.semiBold()),
            AppSpacing.xs.h,
            AppTextField(
              controller: _languagesController,
              decoration: const InputDecoration(
                hintText: 'e.g. English, French, Spanish',
              ),
            ),
            AppSpacing.md.h,

            // 5. Certifications
            Text(
              'Certifications',
              style: context.textTheme.labelMedium?.semiBold(),
            ),
            AppSpacing.xs.h,
            AppTextField(
              controller: _certificationsController,
              decoration: const InputDecoration(
                hintText: 'e.g. CPR, First Aid, Close Protection',
              ),
            ),
            AppSpacing.xl.h,

            // Save Button
            AppButton(
              text: _isSaving ? 'Saving...' : 'Save Details',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _handleSave,
            ),
            AppSpacing.md.h,
          ],
        ),
      ),
    );
  }
}

