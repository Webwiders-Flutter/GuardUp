import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/api_error.extension.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_address_picker_sheet.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '../../../bloc/guard_profile/guard_profile_bloc.dart';

typedef KeyDetailsUpdatedCallback = void Function({
  int? experienceYears,
  num? hourlyRate,
  String? languages,
  String? certifications,
  String? qualifications,
  String? address,
  double? latitude,
  double? longitude,
});

/// Modal bottom sheet for viewing and updating key bodyguard operational details.
class EditKeyDetailsSheet extends StatefulWidget {
  final int experienceYears;
  final num hourlyRate;
  final String address;
  final double? latitude;
  final double? longitude;
  final String languages;
  final String certifications;
  final String qualifications;
  final KeyDetailsUpdatedCallback? onKeyDetailsUpdated;

  const EditKeyDetailsSheet({
    super.key,
    required this.experienceYears,
    required this.hourlyRate,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.languages,
    required this.certifications,
    this.qualifications = '',
    this.onKeyDetailsUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    GuardProfileBloc? bloc,
    required int experienceYears,
    required num hourlyRate,
    required String address,
    required double? latitude,
    required double? longitude,
    required String languages,
    required String certifications,
    String qualifications = '',
    KeyDetailsUpdatedCallback? onKeyDetailsUpdated,
  }) {
    final profileBloc = bloc ?? context.read<GuardProfileBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => BlocProvider.value(
        value: profileBloc,
        child: EditKeyDetailsSheet(
          experienceYears: experienceYears,
          hourlyRate: hourlyRate,
          address: address,
          latitude: latitude,
          longitude: longitude,
          languages: languages,
          certifications: certifications,
          qualifications: qualifications,
          onKeyDetailsUpdated: onKeyDetailsUpdated,
        ),
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
  late final TextEditingController _qualificationsController;

  double? _selectedLat;
  double? _selectedLng;

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
    _qualificationsController = TextEditingController(
      text: widget.qualifications,
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
    _qualificationsController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final exp = int.tryParse(_expController.text.trim()) ?? 0;
    final rate = num.tryParse(_rateController.text.trim()) ?? 0;
    context.read<GuardProfileBloc>().add(
      GuardProfileKeyDetailsSaved(
        experienceYears: exp,
        hourlyRate: rate,
        address: _addressController.text.trim(),
        latitude: _selectedLat,
        longitude: _selectedLng,
        languages: _languagesController.text.trim(),
        certifications: _certificationsController.text.trim(),
        qualifications: _qualificationsController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GuardProfileBloc, GuardProfileState>(
      listenWhen: (prev, curr) => prev.editStatus != curr.editStatus,
      listener: (context, state) {
        if (state.editStatus.isSuccess &&
            state.editStatus.dataOrNull == GuardProfileEditKind.keyDetails) {
          widget.onKeyDetailsUpdated?.call(
            experienceYears: int.tryParse(_expController.text.trim()) ?? 0,
            hourlyRate: num.tryParse(_rateController.text.trim()) ?? 0,
            languages: _languagesController.text.trim(),
            certifications: _certificationsController.text.trim(),
            qualifications: _qualificationsController.text.trim(),
            address: _addressController.text.trim(),
            latitude: _selectedLat,
            longitude: _selectedLng,
          );
          Navigator.pop(context);
          AppSnackbar.success('Key details updated successfully');
        } else if (state.editStatus.isFailure) {
          AppSnackbar.error(
            context.apiErrorText(
              state.editStatus.errorOrNull,
              fallback: 'Failed to update details',
            ),
          );
        }
      },
      buildWhen: (prev, curr) => prev.editStatus != curr.editStatus,
      builder: (context, state) {
        final isSaving = state.editStatus.isLoading;
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
                Text(
                  'Languages',
                  style: context.textTheme.labelMedium?.semiBold(),
                ),
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
                AppSpacing.md.h,

                // 6. Qualifications
                Text(
                  'Qualifications',
                  style: context.textTheme.labelMedium?.semiBold(),
                ),
                AppSpacing.xs.h,
                AppTextField(
                  controller: _qualificationsController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Certified Close Protection, Ex-Military',
                  ),
                ),
                AppSpacing.xl.h,

                // Save Button
                AppButton(
                  text: isSaving ? 'Saving...' : 'Save Details',
                  isLoading: isSaving,
                  onPressed: isSaving ? null : _handleSave,
                ),
                AppSpacing.md.h,
              ],
            ),
          ),
        );
      },
    );
  }
}
