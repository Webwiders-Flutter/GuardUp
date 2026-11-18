import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/api/json_keys.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/riverpod.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/utils/validators.dart';
import '/features/document-type/data/models/document_type.model.dart';
import '/features/document-type/di/document_type.providers.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/shared/controllers/selection.controller.dart';
import '/shared/states/pagination.state.dart';
import '/shared/widgets/admin_layout/app_side_panel.dart';
import '/shared/widgets/inputs/app_input_label.dart';
import '/shared/widgets/inputs/app_radio.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '../controllers/document_type.controller.dart';

class DocumentTypeFormScreen extends ConsumerStatefulWidget {
  final DocumentTypeModel? documentType;

  /// Pre-selected target role when creating a new document type.
  final UserRoleType? initialTargetRole;

  const DocumentTypeFormScreen({
    super.key,
    this.documentType,
    this.initialTargetRole,
  });

  /// Opens the form inside an enterprise right-side slide-in panel.
  static Future<bool?> showAsSidebar({
    required BuildContext context,
    DocumentTypeModel? documentType,
    UserRoleType? initialTargetRole,
  }) {
    final formKey = GlobalKey<DocumentTypeFormScreenState>();
    final isEditing = documentType != null;

    return AppSidePanel.show<bool>(
      context: context,
      title: isEditing ? 'Edit Document Type' : 'Add Document Type',
      subtitle: isEditing
          ? 'Update document requirements, target role and active status'
          : 'Configure a new verification document for platform onboarding',
      width: 520,
      body: DocumentTypeFormScreen(
        key: formKey,
        documentType: documentType,
        initialTargetRole: initialTargetRole,
      ),
      saveLabel: isEditing ? 'Save Changes' : 'Create Document Type',
      onSave: (panelContext) async {
        return await formKey.currentState?.submit() ?? false;
      },
    );
  }

  @override
  ConsumerState<DocumentTypeFormScreen> createState() =>
      DocumentTypeFormScreenState();
}

class DocumentTypeFormScreenState
    extends ConsumerState<DocumentTypeFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  ProviderListenable<AsyncValue<PaginationState<DocumentTypeModel>>>
  get provider => documentTypeControllerProvider;
  DocumentTypeController get controller =>
      ref.read(documentTypeControllerProvider.notifier);

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final SelectionController<UserRoleType> _targetRoleController;
  late final SelectionController<String> _complianceController;

  bool get _isEditing => widget.documentType != null;

  @override
  void initState() {
    super.initState();
    final item = widget.documentType;

    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _targetRoleController = SelectionController<UserRoleType>([
      item?.targetRole ?? widget.initialTargetRole ?? UserRoleType.guard,
    ], isSingleSelection: true);
    _complianceController = SelectionController<String>([
      if (item?.isRequired ?? true) JsonKeys.isRequired,
      if (item?.isActive ?? true) JsonKeys.isActive,
    ]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetRoleController.dispose();
    _complianceController.dispose();
    super.dispose();
  }

  /// Submits the form. Returns `true` if successful, `false` otherwise.
  Future<bool> submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;

    final request = DocumentTypeRequest(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      targetRole: _targetRoleController.value.firstOrNull ?? UserRoleType.guard,
      isRequired: _complianceController.isSelected(JsonKeys.isRequired),
      isActive: _complianceController.isSelected(JsonKeys.isActive),
      displayOrder: widget.documentType?.displayOrder,
    );

    if (_isEditing) {
      await controller.updateRecord(request, widget.documentType!.id);
    } else {
      await controller.createRecord(request);
    }

    if (!mounted) return false;

    return ref
        .read(provider)
        .handleResult(
          successMessage: _isEditing
              ? 'Document type updated successfully'
              : 'Document type created successfully',
          fallbackErrorMessage: _isEditing
              ? 'Failed to update document type'
              : 'Failed to create document type',
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
          // ── Document Name ──────────────────────────────────────────
          const AppFieldLabel(text: 'Document Name', isRequired: true),
          AppSpacing.xs.h,
          AppTextField(
            controller: _nameController,
            validator: (value) =>
                Validators.required(context, value, fieldName: 'Document name'),
            decoration: const InputDecoration(
              hintText:
                  'e.g. Security License, Government ID, Company Registration',
            ),
          ),
          AppSpacing.lg.h,

          // ── Description ────────────────────────────────────────────
          const AppFieldLabel(
            text: 'Description & Upload Instructions',
            isRequired: false,
          ),
          AppSpacing.xs.h,
          AppTextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Explain what this document is and how it should be uploaded for verification.',
            ),
          ),

          AppSpacing.xl.h,
          Divider(height: 1, color: colors.borderLight.withValues(alpha: 0.6)),
          AppSpacing.xl.h,

          // ── Target Role ────────────────────────────────────────────
          const AppFieldLabel(text: 'Required From', isRequired: true),
          AppSpacing.xs.h,
          AppRadio<UserRoleType>(
            controller: _targetRoleController,
            type: AppRadioType.radio,
            isRow: false,
            spacing: AppSpacing.md,
            optionsList: UserRoleType.platformRoles
                .map(
                  (role) => AppRadioOption(
                    value: role,
                    label: role.label(),
                    subtitle: role.description(),
                  ),
                )
                .toList(),
          ),

          AppSpacing.xl.h,
          Divider(height: 1, color: colors.borderLight.withValues(alpha: 0.6)),
          AppSpacing.xl.h,

          // ── Compliance & Status Configuration ──────────────────────
          const AppFieldLabel(
            text: 'Compliance & Verification',
            isRequired: false,
          ),
          AppSpacing.xs.h,
          QuickContainer(
            p: AppSpacing.sm,
            radius: AppRadius.md,
            color: colors.surface,
            border: Border.all(
              color: colors.borderLight.withValues(alpha: 0.8),
            ),
            child: AppRadio<String>(
              controller: _complianceController,
              type: AppRadioType.checkbox,
              size: AppRadioSize.medium,
              showDivider: true,
              optionsList: const [
                AppRadioOption(
                  value: JsonKeys.isRequired,
                  label: 'Mandatory Document',
                  subtitle: 'Users of the selected role must upload this document before their account can be verified.',
                ),
                AppRadioOption(
                  value: JsonKeys.isActive,
                  label: 'Active in Onboarding',
                  subtitle: 'Show this document type in registration and verification flows.',
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
