import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/riverpod.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '../../../users/data/enums/user_role.enum.dart';
import '../../data/models/faq.model.dart';
import '../../di/faq.providers.dart';
import '../controllers/faq.controller.dart';
import '/core/constants/api/json_keys.dart';
import '/shared/controllers/selection.controller.dart';
import '../../../../shared/widgets/admin_layout/app_side_panel.dart';
import '/shared/widgets/inputs/app_input_label.dart';
import '/shared/widgets/inputs/app_radio.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/states/pagination.state.dart';

class FaqFormScreen extends ConsumerStatefulWidget {
  final Faq? faq;

  const FaqFormScreen({super.key, this.faq});

  /// Opens the form inside an enterprise right-side slide-in panel (Linear/Supabase style).
  static Future<bool?> showAsSidebar({
    required BuildContext context,
    Faq? faq,
  }) {
    final formKey = GlobalKey<FaqFormScreenState>();
    final isEditing = faq != null;

    return AppSidePanel.show<bool>(
      context: context,
      title: isEditing ? 'Edit FAQ' : 'Add FAQ',
      subtitle: isEditing
          ? 'Update question, answer, Hindi localization, and target audience'
          : 'Create a new frequently asked question and answer guide',
      width: 540,
      body: FaqFormScreen(key: formKey, faq: faq),
      saveLabel: isEditing ? 'Save Changes' : 'Create FAQ',
      onSave: (panelContext) async {
        return await formKey.currentState?.submit() ?? false;
      },
    );
  }

  @override
  ConsumerState<FaqFormScreen> createState() => FaqFormScreenState();
}

class FaqFormScreenState extends ConsumerState<FaqFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  ProviderListenable<AsyncValue<PaginationState<Faq>>> get provider =>
      faqControllerProvider;
  FaqController get controller => ref.read(faqControllerProvider.notifier);

  late final TextEditingController _questionController;
  late final TextEditingController _questionHiController;
  late final TextEditingController _answerController;
  late final TextEditingController _answerHiController;

  late final SelectionController<String> _roleController;
  late final SelectionController<String> _statusController;

  bool get _isEditing => widget.faq != null;

  @override
  void initState() {
    super.initState();
    final item = widget.faq;

    _questionController = TextEditingController(text: item?.question ?? '');
    _questionHiController = TextEditingController(text: item?.questionHi ?? '');
    _answerController = TextEditingController(text: item?.answer ?? '');
    _answerHiController = TextEditingController(text: item?.answerHi ?? '');

    final initialRole = item?.role?.apiValue ?? 'ALL';
    _roleController = SelectionController<String>([
      initialRole,
    ], isSingleSelection: true);

    _statusController = SelectionController<String>([
      if (item?.isActive ?? true) JsonKeys.isActive,
    ]);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _questionHiController.dispose();
    _answerController.dispose();
    _answerHiController.dispose();
    _roleController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  /// Submits the form. Returns `true` if successful, `false` otherwise.
  Future<bool> submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;

    final selectedRoleValue = _roleController.value.firstOrNull;
    final request = FaqRequest(
      question: _questionController.text,
      questionHi: _questionHiController.text,
      answer: _answerController.text,
      answerHi: _answerHiController.text,
      role: selectedRoleValue,
      sortOrder: widget.faq?.sortOrder,
      isActive: _statusController.isSelected(JsonKeys.isActive),
    );

    if (_isEditing) {
      await controller.updateRecord(request, widget.faq!.id);
    } else {
      await controller.createRecord(request);
    }

    if (!mounted) return false;

    return ref
        .read(provider)
        .handleResult(
          successMessage: _isEditing
              ? 'FAQ updated successfully'
              : 'FAQ created successfully',
          fallbackErrorMessage: _isEditing
              ? 'Failed to update FAQ'
              : 'Failed to create FAQ',
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
          // ── Question English ─────────────────────────────────────────
          const AppFieldLabel(text: 'Question (English)', isRequired: true),
          AppSpacing.xs.h,
          AppTextField(
            controller: _questionController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g. How do I request an advance payment for a trip?',
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Question is required';
              }
              return null;
            },
          ),
          AppSpacing.lg.h,

          // ── Question Hindi ───────────────────────────────────────────
          const AppFieldLabel(text: 'Question (Hindi)', isOptional: true),
          AppSpacing.xs.h,
          AppTextField(
            controller: _questionHiController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'उदा. ट्रिप के लिए अग्रिम भुगतान का अनुरोध कैसे करें?',
            ),
          ),
          AppSpacing.lg.h,

          // ── Answer English ───────────────────────────────────────────
          const AppFieldLabel(text: 'Answer (English)', isRequired: true),
          AppSpacing.xs.h,
          AppTextField(
            controller: _answerController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Provide a detailed, step-by-step resolution or explanation...',
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Answer is required';
              }
              return null;
            },
          ),
          AppSpacing.lg.h,

          // ── Answer Hindi ─────────────────────────────────────────────
          const AppFieldLabel(text: 'Answer (Hindi)', isOptional: true),
          AppSpacing.xs.h,
          AppTextField(
            controller: _answerHiController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'विस्तृत उत्तर और समाधान हिंदी में दर्ज करें...',
            ),
          ),
          AppSpacing.xl.h,
          Divider(height: 1, color: colors.borderLight.withValues(alpha: 0.6)),
          AppSpacing.xl.h,

          // ── Role Audience ────────────────────────────────────────────
          const AppFieldLabel(
            text: 'Target Audience (Role)',
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
              controller: _roleController,
              type: AppRadioType.radio,
              isRow: false,
              spacing: AppSpacing.xs,
              showDivider: true,
              optionsList: [
                const AppRadioOption(
                  value: 'ALL',
                  label: 'All Users (General FAQ)',
                  subtitle:
                      'Visible to everyone across all mobile apps and portals',
                ),
                ...UserRoleType.values.map(
                  (role) => AppRadioOption(
                    value: role.apiValue,
                    label: role.label(context.l10n),
                    subtitle: role.description(context.l10n),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.xl.h,
          Divider(height: 1, color: colors.borderLight.withValues(alpha: 0.6)),
          AppSpacing.xl.h,

          // ── Status Configuration ───────────────────────────────────
          const AppFieldLabel(text: 'Status Configuration', isRequired: false),
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
                  label: 'Active Status',
                  subtitle: 'Display this FAQ in customer help centers, in-app support, and knowledge bases',
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
