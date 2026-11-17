import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/riverpod.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/shared/states/pagination.state.dart';
import '/shared/widgets/admin_layout/app_side_panel.dart';
import '../../data/models/{{feature_name.snakeCase()}}.model.dart';
import '../../di/{{feature_name.snakeCase()}}.providers.dart';
import '../controllers/{{feature_name.snakeCase()}}.controller.dart';

class {{feature_name.pascalCase()}}FormScreen extends ConsumerStatefulWidget {
  final {{feature_name.pascalCase()}}? {{feature_name.camelCase()}};

  const {{feature_name.pascalCase()}}FormScreen({super.key, this.{{feature_name.camelCase()}}});

  /// Opens the form inside an enterprise right-side slide-in panel (Linear/Supabase style).
  static Future<bool?> showAsSidebar({
    required BuildContext context,
    {{feature_name.pascalCase()}}? {{feature_name.camelCase()}},
  }) {
    final formKey = GlobalKey<{{feature_name.pascalCase()}}FormScreenState>();
    final isEditing = {{feature_name.camelCase()}} != null;

    return AppSidePanel.show<bool>(
      context: context,
      title: isEditing ? 'Edit {{entity_name.titleCase()}}' : 'Add {{entity_name.titleCase()}}',
      subtitle: isEditing
          ? 'Update {{entity_name.lowerCase()}} details'
          : 'Configure new {{entity_name.lowerCase()}}',
      width: 520,
      body: {{feature_name.pascalCase()}}FormScreen(
        key: formKey,
        {{feature_name.camelCase()}}: {{feature_name.camelCase()}},
      ),
      saveLabel: isEditing ? 'Save Changes' : 'Create {{entity_name.titleCase()}}',
      onSave: (panelContext) async {
        return await formKey.currentState?.submit() ?? false;
      },
    );
  }

  @override
  ConsumerState<{{feature_name.pascalCase()}}FormScreen> createState() =>
      {{feature_name.pascalCase()}}FormScreenState();
}

class {{feature_name.pascalCase()}}FormScreenState
    extends ConsumerState<{{feature_name.pascalCase()}}FormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  ProviderListenable<AsyncValue<PaginationState<{{feature_name.pascalCase()}}>>> get provider =>
      {{feature_name.camelCase()}}ControllerProvider;
  {{feature_name.pascalCase()}}Controller get controller =>
      ref.read({{feature_name.camelCase()}}ControllerProvider.notifier);

  bool get _isEditing => widget.{{feature_name.camelCase()}} != null;

  @override
  void initState() {
    super.initState();
    // Initialize form controllers here
  }

  @override
  void dispose() {
    // Dispose form controllers here
    super.dispose();
  }

  /// Submits the form. Returns `true` if successful, `false` otherwise.
  Future<bool> submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;

    final request = {{feature_name.pascalCase()}}Request(
      sortOrder: widget.{{feature_name.camelCase()}}?.sortOrder,
    );

    if (_isEditing) {
      await controller.updateRecord(request, widget.{{feature_name.camelCase()}}!.id);
    } else {
      await controller.createRecord(request);
    }

    if (!mounted) return false;

    return ref
        .read(provider)
        .handleResult(
          successMessage: _isEditing
              ? '{{entity_name.titleCase()}} updated successfully'
              : '{{entity_name.titleCase()}} created successfully',
          fallbackErrorMessage: _isEditing
              ? 'Failed to update {{entity_name.lowerCase()}}'
              : 'Failed to create {{entity_name.lowerCase()}}',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Add form input fields here
          AppSpacing.xl.h,
        ],
      ),
    );
  }
}
