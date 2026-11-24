import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '/core/constants/api/database_tables.dart';
import '/core/constants/app_radius.dart';
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
import '/shared/widgets/inputs/app_dropdown.dart';
import '/shared/widgets/selection/app_removable_chip.dart';
import '/shared/widgets/selection/selection.controller.dart';
import '../../../bloc/services/services_cubit.dart';
import '../../../data/model/service_item.model.dart';
import '../../../data/repositories/bodyguard.repository.dart';

/// Modal bottom sheet for viewing, adding, and removing bodyguard services in-place.
class EditServicesSheet extends StatefulWidget {
  final List<ServiceItemModel> currentServices;
  final String? bodyguardId;
  final ValueChanged<List<ServiceItemModel>>? onServicesUpdated;

  const EditServicesSheet({
    super.key,
    required this.currentServices,
    this.bodyguardId,
    this.onServicesUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required List<ServiceItemModel> currentServices,
    String? bodyguardId,
    ValueChanged<List<ServiceItemModel>>? onServicesUpdated,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => EditServicesSheet(
        currentServices: currentServices,
        bodyguardId: bodyguardId,
        onServicesUpdated: onServicesUpdated,
      ),
    );
  }

  @override
  State<EditServicesSheet> createState() => _EditServicesSheetState();
}

class _EditServicesSheetState extends State<EditServicesSheet> {
  late final List<ServiceItemModel> _selectedServices;
  List<ServiceItemModel> _activeServices = [];
  late final SelectionController<ServiceItemModel> _dropdownController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedServices = List.from(widget.currentServices);
    _dropdownController = SelectionController<ServiceItemModel>.multi(
      initial: _selectedServices,
      onChanged: (selected) {
        setState(() {
          _selectedServices
            ..clear()
            ..addAll(selected);
        });
      },
    );
    _loadActiveServices();
  }

  Future<void> _loadActiveServices() async {
    try {
      final services = await sl<ServicesCubit>().loadServices();

      if (mounted) {
        setState(() {
          _activeServices = services;

          // Sync initial selected items with fetched instances so IDs and objects match
          final matchedSelected = _activeServices
              .where((active) => _selectedServices.any((s) => s.id == active.id))
              .toList();
          if (matchedSelected.isNotEmpty) {
            _selectedServices
              ..clear()
              ..addAll(matchedSelected);
            _dropdownController.setSelection(matchedSelected);
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _dropdownController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final targetServiceIds = _selectedServices.map((s) => s.id).toList();

      if (widget.bodyguardId != null && widget.bodyguardId!.isNotEmpty) {
        await sl<BodyguardRepository>().setServices(
          widget.bodyguardId!,
          targetServiceIds,
        );
      } else {
        final authState = sl<AuthBloc>().state;
        final userId = authState.user?.id ?? '';
        if (userId.isNotEmpty) {
          // 1. Persist strictly to public.user_services (matching signup flow)
          try {
            await Supabase.instance.client.rpc(
              'set_user_services',
              params: {'p_user_id': userId, 'p_service_ids': targetServiceIds},
            );
          } catch (_) {
            await Supabase.instance.client
                .from(DatabaseTables.userServices)
                .delete()
                .eq('user_id', userId);

            if (targetServiceIds.isNotEmpty) {
              final inserts = targetServiceIds
                  .map((sId) => {'user_id': userId, 'service_id': sId})
                  .toList();

              await Supabase.instance.client
                  .from(DatabaseTables.userServices)
                  .insert(inserts);
            }
          }

          // 2. Remove obsolete 'services' key from metadata if it was previously present
          try {
            final userRow = await sl<UserRepository>().getUserData(userId);
            if (userRow?['metadata'] is Map &&
                (userRow!['metadata'] as Map).containsKey('services')) {
              final cleanMeta = Map<String, dynamic>.from(
                userRow['metadata'] as Map,
              );
              cleanMeta.remove('services');
              await sl<UserRepository>().updateProfileFields(
                userId: userId,
                data: {'metadata': cleanMeta},
              );
            }
          } catch (_) {}

          sl<AuthBloc>().add(AuthUpdateUserServices(_selectedServices));
          sl<AuthBloc>().add(const AuthReloadRoleDataRequested());
        }
      }

      if (mounted) {
        widget.onServicesUpdated?.call(_selectedServices);
        Navigator.pop(context);
        AppSnackbar.success('Services updated successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackbar.error('Failed to update services: $e');
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
                      _selectedServices.removeWhere((s) => s.id == service.id);
                      _dropdownController.deselect(service);
                    });
                  },
                );
              }).toList(),
            ),
            AppSpacing.md.h,
          ],

          // Multi-select dropdown for services
          if (_activeServices.isNotEmpty)
            AppDropdown<ServiceItemModel>(
              controller: _dropdownController,
              hintText: 'Select services...',
              okButtonText: 'OK',
              items: _activeServices
                  .map(
                    (s) => SelectableItem<ServiceItemModel, String>(
                      id: s,
                      data: s.name,
                      // icon: Icon(
                      //   s.icon,
                      //   size: AppSizes.iconSm,
                      //   color: context.colors.primary,
                      // ),
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
            text: _isSaving ? 'Saving...' : 'Save Services',
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _handleSave,
          ),
          AppSpacing.sm.h,
        ],
      ),
    );
  }
}
