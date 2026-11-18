import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_constants.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_regx.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/riverpod.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/shared/controllers/selection.controller.dart';
import '/shared/widgets/admin_layout/app_side_panel.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_input_label.dart';
import '/shared/widgets/inputs/app_radio.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '../../data/models/membership_plan.model.dart';
import '../../di/membership_plan.providers.dart';
import '../controllers/membership_plan.controller.dart';

/// Keys for the visibility checkboxes.
enum _PlanFlag { active, popular }

class MembershipPlanFormScreen extends ConsumerStatefulWidget {
  final MembershipPlan? plan;

  const MembershipPlanFormScreen({super.key, this.plan});

  /// Opens the form in the right-side slide-in panel.
  /// Resolves to `true` when the plan was saved.
  static Future<bool?> showAsSidebar({
    required BuildContext context,
    MembershipPlan? plan,
  }) {
    final formKey = GlobalKey<MembershipPlanFormScreenState>();
    final isEditing = plan != null;

    return AppSidePanel.show<bool>(
      context: context,
      title: isEditing ? 'Edit Membership Plan' : 'Add Membership Plan',
      subtitle: isEditing
          ? 'Update pricing, booking discount and benefits'
          : 'Create a new membership tier for customers',
      width: 560,
      body: MembershipPlanFormScreen(key: formKey, plan: plan),
      saveLabel: isEditing ? 'Save Changes' : 'Create Plan',
      onSave: (panelContext) async {
        return await formKey.currentState?.submit() ?? false;
      },
    );
  }

  @override
  ConsumerState<MembershipPlanFormScreen> createState() =>
      MembershipPlanFormScreenState();
}

class MembershipPlanFormScreenState
    extends ConsumerState<MembershipPlanFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  MembershipPlanController get _controller =>
      ref.read(membershipPlanControllerProvider.notifier);

  late final TextEditingController _nameController;
  late final TextEditingController _monthlyPriceController;
  late final TextEditingController _yearlyPriceController;
  late final TextEditingController _discountController;
  late final TextEditingController _discountUptoController;
  late final SelectionController<DiscountType> _discountTypeController;
  late final SelectionController<_PlanFlag> _flagsController;
  late final ValueNotifier<List<TextEditingController>> _benefitsNotifier;

  bool get _isEditing => widget.plan != null;

  DiscountType get _discountType =>
      _discountTypeController.value.firstOrNull ?? DiscountType.percentage;

  static final _amountFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(AppRegex.amountInput),
  ];

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;

    _nameController = TextEditingController(text: plan?.name ?? '');
    _monthlyPriceController = TextEditingController(
      text: _formatAmount(plan?.pricePerMonth),
    );
    _yearlyPriceController = TextEditingController(
      text: _formatAmount(plan?.pricePerYear),
    );
    _discountController = TextEditingController(
      text: _formatAmount(plan?.discount),
    );
    _discountUptoController = TextEditingController(
      text: _formatAmount(plan?.discountUpto),
    );
    _discountTypeController = SelectionController<DiscountType>([
      plan?.discountType ?? DiscountType.percentage,
    ], isSingleSelection: true);
    _flagsController = SelectionController<_PlanFlag>([
      if (plan?.isActive ?? true) _PlanFlag.active,
      if (plan?.isPopular ?? false) _PlanFlag.popular,
    ]);

    final benefits = plan?.description ?? const <String>[];
    _benefitsNotifier = ValueNotifier([
      for (final line in benefits) TextEditingController(text: line),
      if (benefits.isEmpty) TextEditingController(),
    ]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _monthlyPriceController.dispose();
    _yearlyPriceController.dispose();
    _discountController.dispose();
    _discountUptoController.dispose();
    _discountTypeController.dispose();
    _flagsController.dispose();
    for (final controller in _benefitsNotifier.value) {
      controller.dispose();
    }
    _benefitsNotifier.dispose();
    super.dispose();
  }

  static String _formatAmount(double? value) {
    if (value == null) return '';
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }

  static double? _parseAmount(String text) => double.tryParse(text.trim());

  void _addBenefit() {
    _benefitsNotifier.value = [
      ..._benefitsNotifier.value,
      TextEditingController(),
    ];
  }

  void _removeBenefit(TextEditingController controller) {
    _benefitsNotifier.value = [..._benefitsNotifier.value]..remove(controller);
    // Dispose after the field using it has been removed from the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  }

  /// Submits the form. Returns `true` if the plan was saved.
  Future<bool> submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;

    final request = MembershipPlanRequest(
      name: _nameController.text,
      description: _benefitsNotifier.value.map((c) => c.text).toList(),
      pricePerMonth: _parseAmount(_monthlyPriceController.text) ?? 0,
      pricePerYear: _parseAmount(_yearlyPriceController.text),
      discount: _parseAmount(_discountController.text) ?? 0,
      discountType: _discountType,
      discountUpto: _parseAmount(_discountUptoController.text),
      isActive: _flagsController.isSelected(_PlanFlag.active),
      isPopular: _flagsController.isSelected(_PlanFlag.popular),
    );

    final plan = widget.plan;
    if (plan != null) {
      await _controller.updateRecord(request, plan.id);
    } else {
      await _controller.createRecord(request);
    }

    if (!mounted) return false;

    final saved = ref
        .read(membershipPlanControllerProvider)
        .handleResult(
          successMessage: _isEditing
              ? 'Membership plan updated successfully'
              : 'Membership plan created successfully',
          fallbackErrorMessage: _isEditing
              ? 'Failed to update membership plan'
              : 'Failed to create membership plan',
        );

    if (saved && plan != null) {
      ref.invalidate(membershipPlanDetailsProvider(plan.id));
    }
    return saved;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Plan Name ──────────────────────────────────────────────
          const AppFieldLabel(text: 'Plan Name', isRequired: true),
          AppSpacing.xs.h,
          AppTextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            validator: (value) =>
                Validators.required(context, value, fieldName: 'Plan name'),
            decoration: const InputDecoration(
              hintText: 'e.g. Silver Shield, Gold Sentinel, Platinum Elite',
            ),
          ),
          AppSpacing.xl.h,

          // ── Pricing ────────────────────────────────────────────────
          const _SectionTitle(
            title: 'Pricing',
            subtitle: 'What the customer pays for the membership',
          ),
          AppSpacing.md.h,
          _buildPricingFields(context),
          AppSpacing.xl.h,

          // ── Booking Discount ───────────────────────────────────────
          const _SectionTitle(
            title: 'Booking Discount',
            subtitle: 'Applied to every booking made while the plan is active',
          ),
          AppSpacing.md.h,
          _buildDiscountFields(context),
          AppSpacing.xl.h,

          // ── Benefits ───────────────────────────────────────────────
          const _SectionTitle(
            title: 'Benefits',
            subtitle: 'Shown as a bullet list on the plan card, one per line',
          ),
          AppSpacing.md.h,
          _buildBenefitFields(context),
          AppSpacing.xl.h,

          // ── Visibility ─────────────────────────────────────────────
          const AppFieldLabel(text: 'Visibility', isRequired: false),
          AppSpacing.xs.h,
          _OutlinedBox(
            child: AppRadio<_PlanFlag>(
              controller: _flagsController,
              type: AppRadioType.checkbox,
              size: AppRadioSize.medium,
              showDivider: false,
              optionsList: const [
                AppRadioOption(
                  value: _PlanFlag.active,
                  label: 'Active',
                  subtitle: 'Customers can see and buy this plan in the app.',
                ),
                AppRadioOption(
                  value: _PlanFlag.popular,
                  label: 'Mark as Most Popular',
                  subtitle: 'Highlights this plan on the plan comparison screen.',
                ),
              ],
            ),
          ),
          AppSpacing.xl.h,
        ],
      ),
    );
  }

  Widget _buildPricingFields(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppFieldLabel(text: 'Price / Month', isRequired: true),
                  AppSpacing.xs.h,
                  AppTextField(
                    controller: _monthlyPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _amountFormatters,
                    validator: (value) => Validators.number(
                      context,
                      value,
                      min: 0,
                      fieldName: 'Monthly price',
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixText: '${AppConstants.currencySymbol} ',
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.md.w,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppFieldLabel(text: 'Price / Year', isRequired: false),
                  AppSpacing.xs.h,
                  AppTextField(
                    controller: _yearlyPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _amountFormatters,
                    validator: (value) => Validators.number(
                      context,
                      value,
                      min: 0,
                      isRequired: false,
                      fieldName: 'Yearly price',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Leave empty for monthly only',
                      prefixText: '${AppConstants.currencySymbol} ',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Live hint comparing the yearly price to 12 monthly payments.
        ListenableBuilder(
          listenable: Listenable.merge([
            _monthlyPriceController,
            _yearlyPriceController,
          ]),
          builder: (context, _) {
            final monthly = _parseAmount(_monthlyPriceController.text);
            if (monthly == null || monthly <= 0) return const SizedBox.shrink();

            final atMonthlyRate = monthly * 12;
            final yearly = _parseAmount(_yearlyPriceController.text);
            final savings = yearly != null ? atMonthlyRate - yearly : null;

            final String hint;
            Color hintColor = colors.onSurfaceSecondary;
            if (savings == null) {
              hint = '12 months at the monthly price: ${atMonthlyRate.toUsdAmount}';
            } else if (savings > 0) {
              final percent = (savings / atMonthlyRate * 100).round();
              hint =
                  'Yearly saves ${savings.toUsdAmount} ($percent%) vs. ${atMonthlyRate.toUsdAmount} paid monthly';
              hintColor = colors.success;
            } else {
              hint =
                  'Yearly costs the same or more than 12 monthly payments (${atMonthlyRate.toUsdAmount})';
              hintColor = colors.warning;
            }

            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                hint,
                style: context.textTheme.bodySmall?.medium().colour(hintColor),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDiscountFields(BuildContext context) {
    return ValueListenableBuilder<List<DiscountType>>(
      valueListenable: _discountTypeController,
      builder: (context, _, _) {
        final type = _discountType;
        final isPercentage = type.isPercentage;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppFieldLabel(text: 'Discount Type', isRequired: true),
            AppSpacing.xs.h,
            _OutlinedBox(
              child: AppRadio<DiscountType>(
                controller: _discountTypeController,
                type: AppRadioType.radio,
                size: AppRadioSize.medium,
                showDivider: false,
                optionsList: [
                  for (final value in DiscountType.values)
                    AppRadioOption(
                      value: value,
                      label: value.label,
                      subtitle: value.subtitle,
                    ),
                ],
              ),
            ),
            AppSpacing.md.h,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppFieldLabel(
                        text: isPercentage ? 'Discount (%)' : 'Discount Amount',
                        isRequired: true,
                      ),
                      AppSpacing.xs.h,
                      AppTextField(
                        // Re-validate against the new bound when the type changes.
                        key: ValueKey(type),
                        controller: _discountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: _amountFormatters,
                        validator: (value) => Validators.number(
                          context,
                          value,
                          min: 0,
                          max: isPercentage ? 100 : null,
                          fieldName: 'Discount',
                        ),
                        decoration: InputDecoration(
                          hintText: isPercentage ? 'e.g. 20' : 'e.g. 200',
                          prefixText: isPercentage
                              ? null
                              : '${AppConstants.currencySymbol} ',
                          suffixText: isPercentage ? '%' : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPercentage) ...[
                  AppSpacing.md.w,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppFieldLabel(
                          text: 'Max Discount (Up To)',
                          isRequired: false,
                        ),
                        AppSpacing.xs.h,
                        AppTextField(
                          controller: _discountUptoController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: _amountFormatters,
                          validator: (value) => Validators.number(
                            context,
                            value,
                            min: 0,
                            minExclusive: true,
                            isRequired: false,
                            fieldName: 'Max discount',
                          ),
                          decoration: const InputDecoration(
                            hintText: 'No limit',
                            prefixText: '${AppConstants.currencySymbol} ',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildBenefitFields(BuildContext context) {
    final colors = context.colors;

    return ValueListenableBuilder<List<TextEditingController>>(
      valueListenable: _benefitsNotifier,
      builder: (context, benefits, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, controller) in benefits.indexed) ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: AppSpacing.lg,
                    color: colors.success,
                  ),
                  AppSpacing.sm.w,
                  Expanded(
                    child: AppTextField(
                      key: ObjectKey(controller),
                      controller: controller,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: index == 0
                            ? 'e.g. 20% off every booking'
                            : 'Benefit ${index + 1}',
                      ),
                    ),
                  ),
                  AppSpacing.xs.w,
                  IconButton(
                    tooltip: 'Remove benefit',
                    onPressed: benefits.length > 1
                        ? () => _removeBenefit(controller)
                        : null,
                    icon: Icon(
                      Icons.remove_circle_outline_rounded,
                      size: AppSpacing.lg,
                      color: benefits.length > 1
                          ? colors.error
                          : colors.onSurfaceSecondary.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              AppSpacing.sm.h,
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                text: 'Add Benefit',
                leading: Icon(
                  Icons.add_rounded,
                  size: AppSpacing.md + 2,
                  color: colors.primary,
                ),
                size: ButtonSize.small,
                type: ButtonType.secondaryPrimary,
                fullWidth: false,
                onPressed: _addBenefit,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.textTheme.titleSmall?.semiBold()),
        (AppSpacing.xs / 2).h,
        Text(
          subtitle,
          style: context.textTheme.bodySmall?.colour(colors.onSurfaceSecondary),
        ),
        AppSpacing.sm.h,
        Divider(height: 1, color: colors.borderLight.withValues(alpha: 0.6)),
      ],
    );
  }
}

class _OutlinedBox extends StatelessWidget {
  const _OutlinedBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return QuickContainer(
      p: AppSpacing.sm,
      radius: AppRadius.md,
      color: colors.surface,
      border: Border.all(color: colors.borderLight.withValues(alpha: 0.8)),
      child: child,
    );
  }
}
