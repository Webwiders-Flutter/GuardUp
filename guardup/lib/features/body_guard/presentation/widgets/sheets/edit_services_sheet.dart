import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/api_error.extension.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/services/services.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_dropdown.dart';
import '/shared/widgets/selection/app_removable_chip.dart';
import '/shared/widgets/selection/selection.controller.dart';
import '../../../bloc/guard_profile/guard_profile_bloc.dart';

/// Modal bottom sheet for viewing, adding, and removing bodyguard services in-place.
class EditServicesSheet extends StatefulWidget {
  final List<ServiceModel> currentServices;
  final ValueChanged<List<ServiceModel>>? onServicesUpdated;

  const EditServicesSheet({
    super.key,
    required this.currentServices,
    this.onServicesUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    GuardProfileBloc? bloc,
    required List<ServiceModel> currentServices,
    ValueChanged<List<ServiceModel>>? onServicesUpdated,
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
        child: EditServicesSheet(
          currentServices: currentServices,
          onServicesUpdated: onServicesUpdated,
        ),
      ),
    );
  }

  @override
  State<EditServicesSheet> createState() => _EditServicesSheetState();
}

class _EditServicesSheetState extends State<EditServicesSheet> {
  late final List<ServiceModel> _selectedServices;
  late final SelectionController<ServiceModel> _dropdownController;
  bool _syncedInitialServices = false;

  @override
  void initState() {
    super.initState();
    _selectedServices = List.from(widget.currentServices);
    _dropdownController = SelectionController<ServiceModel>.multi(
      initial: _selectedServices,
      onChanged: (selected) {
        setState(() {
          _selectedServices
            ..clear()
            ..addAll(selected);
        });
      },
    );
    _syncSelectionWithCatalog(
      context.read<GuardProfileBloc>().state.activeServices,
    );
  }

  void _syncSelectionWithCatalog(List<ServiceModel> activeServices) {
    if (_syncedInitialServices || activeServices.isEmpty) return;
    _syncedInitialServices = true;

    final matchedSelected = activeServices
        .where((active) => _selectedServices.any((s) => s.id == active.id))
        .toList();
    if (matchedSelected.isNotEmpty) {
      _selectedServices
        ..clear()
        ..addAll(matchedSelected);
      _dropdownController.setSelection(matchedSelected);
    }
  }

  @override
  void dispose() {
    _dropdownController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final targetServiceIds = _selectedServices.map((s) => s.id).toList();
    context.read<GuardProfileBloc>().add(
      GuardProfileServicesSaved(targetServiceIds),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GuardProfileBloc, GuardProfileState>(
      listenWhen: (prev, curr) =>
          prev.editStatus != curr.editStatus ||
          prev.activeServices != curr.activeServices,
      listener: (context, state) {
        _syncSelectionWithCatalog(state.activeServices);

        if (state.editStatus.isSuccess &&
            state.editStatus.dataOrNull == GuardProfileEditKind.services) {
          widget.onServicesUpdated?.call(_selectedServices);
          Navigator.pop(context);
          AppSnackbar.success('Services updated successfully');
        } else if (state.editStatus.isFailure) {
          AppSnackbar.error(
            context.apiErrorText(
              state.editStatus.errorOrNull,
              fallback: 'Failed to update services',
            ),
          );
        }
      },
      builder: (context, state) {
        final activeServices = state.activeServices;
        final isSaving = state.editStatus.isLoading;

        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
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
                'Manage Services',
                style: context.textTheme.titleMedium?.bold().colour(
                  context.colors.onSurface,
                ),
              ),
              AppSpacing.xs.h,
              Text(
                'Select the security specialties and services you offer to clients.',
                style: context.textTheme.bodySmall?.colour(
                  context.colors.onSurfaceVariant,
                ),
              ),
              AppSpacing.lg.h,

              // Selected Chips with Remove button
              if (_selectedServices.isNotEmpty) ...[
                Wrap(
                  spacing: AppSpacing.smd,
                  runSpacing: AppSpacing.smd,
                  children: _selectedServices.map((service) {
                    return AppRemovableChip(
                      text: service.name,
                      onRemove: () {
                        setState(() {
                          _selectedServices.removeWhere(
                            (s) => s.id == service.id,
                          );
                          _dropdownController.deselect(service);
                        });
                      },
                    );
                  }).toList(),
                ),
                AppSpacing.md.h,
              ],

              // Multi-select dropdown for services
              if (activeServices.isNotEmpty)
                AppDropdown<ServiceModel>(
                  controller: _dropdownController,
                  hintText: 'Select services...',
                  okButtonText: 'OK',
                  items: activeServices
                      .map(
                        (s) => SelectableItem<ServiceModel, String>(
                          id: s,
                          data: s.name,
                        ),
                      )
                      .toList(),
                )
              else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: CircularProgressIndicator.adaptive(),
                  ),
                ),
              AppSpacing.xl.h,

              // Save Services Button
              AppButton(
                text: isSaving ? 'Saving...' : 'Save Services',
                isLoading: isSaving,
                onPressed: isSaving ? null : _handleSave,
              ),
              AppSpacing.sm.h,
            ],
          ),
        );
      },
    );
  }
}
