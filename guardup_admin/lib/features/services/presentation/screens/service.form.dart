import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:quick_container/quick_container.dart';

import '/core/constants/api/json_keys.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/riverpod.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/utils/validators.dart';
import '/features/services/data/models/service.model.dart';
import '/features/services/di/services.providers.dart';
import '/shared/controllers/selection.controller.dart';
import '/shared/states/pagination.state.dart';
import '/shared/widgets/admin_layout/app_side_panel.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_input_label.dart';
import '/shared/widgets/inputs/app_media_picker_card.dart';
import '/shared/widgets/inputs/app_radio.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '../controllers/services.controller.dart';

class ServiceFormScreen extends ConsumerStatefulWidget {
  final ServiceModel? service;

  const ServiceFormScreen({super.key, this.service});

  /// Opens the form inside an enterprise right-side slide-in panel.
  static Future<bool?> showAsSidebar({
    required BuildContext context,
    ServiceModel? service,
  }) {
    final formKey = GlobalKey<ServiceFormScreenState>();
    final isEditing = service != null;

    return AppSidePanel.show<bool>(
      context: context,
      title: isEditing ? 'Edit Protection Service' : 'Add Protection Service',
      subtitle: isEditing
          ? 'Update service specifications and active status'
          : 'Configure new executive security offering in the master catalog',
      width: 520,
      body: ServiceFormScreen(key: formKey, service: service),
      saveLabel: isEditing ? 'Save Changes' : 'Create Service',
      onSave: (panelContext) async {
        return await formKey.currentState?.submit() ?? false;
      },
    );
  }

  @override
  ConsumerState<ServiceFormScreen> createState() => ServiceFormScreenState();
}

class ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  ProviderListenable<AsyncValue<PaginationState<ServiceModel>>> get provider =>
      servicesControllerProvider;
  ServicesController get controller =>
      ref.read(servicesControllerProvider.notifier);

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final SelectionController<String> _statusController;

  /// Newly picked icon file (not yet uploaded).
  XFile? _pickedIcon;

  /// Whether the user removed the existing icon without picking a new one.
  bool _iconRemoved = false;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final item = widget.service;

    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _statusController = SelectionController<String>([
      if (item?.isActive ?? true) JsonKeys.isActive,
    ]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  /// Submits the form. Returns `true` if successful, `false` otherwise.
  Future<bool> submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    if (!_isEditing && _pickedIcon == null) {
      AppSnackbar.error('Please select an icon for the service');
      return false;
    }

    final request = ServiceRequest(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      iconName: widget.service?.iconName,
      iconUrl: _iconRemoved ? null : widget.service?.iconUrl,
      displayOrder: widget.service?.displayOrder,
      isActive: _statusController.isSelected(JsonKeys.isActive),
    );

    if (_isEditing) {
      await controller.updateRecord(
        request,
        widget.service!.id,
        iconFile: _pickedIcon,
        oldIconUrl: widget.service!.iconUrl,
      );
    } else {
      await controller.createRecord(request, iconFile: _pickedIcon);
    }

    if (!mounted) return false;

    return ref
        .read(provider)
        .handleResult(
          successMessage: _isEditing
              ? 'Service updated successfully'
              : 'Service created successfully',
          fallbackErrorMessage: _isEditing
              ? 'Failed to update service'
              : 'Failed to create service',
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Service Icon ───────────────────────────────────────────
          AppMediaPickerCard(
            title: 'Service Icon',
            description: 'Shown next to the service in the app',
            initialUrl: widget.service?.iconUrl,
            allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'svg'],
            maxSize: '5 MB',
            isRequired: !_isEditing,
            onPicked: (file) {
              _pickedIcon = file;
              _iconRemoved = false;
            },
            onFileRemoved: () {
              _pickedIcon = null;
              _iconRemoved = true;
            },
          ),
          AppSpacing.lg.h,

          // ── Service Name ───────────────────────────────────────────
          const AppFieldLabel(text: 'Service Title / Name', isRequired: true),
          AppSpacing.xs.h,
          AppTextField(
            controller: _nameController,
            validator: (value) =>
                Validators.required(context, value, fieldName: 'Service title'),
            decoration: const InputDecoration(
              hintText:
                  'e.g. VIP Close Protection, Tactical Escort, Event Security',
            ),
          ),
          AppSpacing.lg.h,

          // ── Description ────────────────────────────────────────────
          const AppFieldLabel(
            text: 'Service Description & Coverage',
            isRequired: false,
          ),
          AppSpacing.xs.h,
          AppTextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe the scope, operational protocols, and target assignments for this service.',
            ),
          ),
          AppSpacing.xl.h,

          // ── Status Configuration ───────────────────────────────────
          const AppFieldLabel(text: 'Catalog Status', isRequired: false),
          AppSpacing.xs.h,
          QuickContainer(
            p: AppSpacing.sm,
            radius: AppRadius.md,
            color: colors.surface,
            border: Border.all(
              color: colors.borderLight.withValues(alpha: 0.8),
            ),
            child: AppRadio<String>(
              controller: _statusController,
              type: AppRadioType.checkbox,
              size: AppRadioSize.medium,
              showDivider: false,
              optionsList: const [
                AppRadioOption(
                  value: JsonKeys.isActive,
                  label: 'Active in Booking Flow',
                  subtitle: 'Enable clients and security companies to browse and book this protection tier.',
                ),
              ],
            ),
          ),

          AppSpacing.xl.h,
        ],
      ),
    );
  }
}
