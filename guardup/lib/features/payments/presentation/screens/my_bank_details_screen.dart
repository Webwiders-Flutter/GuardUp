import 'package:flutter/material.dart';
import 'package:guardup/core/extensions/string.extension.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/model/bank_account.model.dart';

/// Screen allowing bodyguards and companies to manage their bank account details.
class MyBankDetailsScreen extends StatefulWidget {
  const MyBankDetailsScreen({super.key});

  @override
  State<MyBankDetailsScreen> createState() => _MyBankDetailsScreenState();
}

class _MyBankDetailsScreenState extends State<MyBankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _accountNumberController;
  late final TextEditingController _accountHolderController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _branchController;
  late final TextEditingController _ifscCodeController;

  final ValueNotifier<List<BankAccount>> _accountsNotifier =
      ValueNotifier<List<BankAccount>>([
        const BankAccount(
          id: '1',
          accountNumber: '1234567890129875',
          accountHolder: 'Rock Smith',
          bankName: 'Bank Name',
          branch: 'indore',
          ifscCode: 'WORD6589',
          branchAddress: 'indore',
        ),
      ]);

  @override
  void initState() {
    super.initState();
    _accountNumberController = TextEditingController();
    _accountHolderController = TextEditingController();
    _bankNameController = TextEditingController();
    _branchController = TextEditingController();
    _ifscCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    _ifscCodeController.dispose();
    _accountsNotifier.dispose();
    super.dispose();
  }

  void _handleAddAccount() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newAccount = BankAccount(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      accountNumber: _accountNumberController.text.trim(),
      accountHolder: _accountHolderController.text.trim(),
      bankName: _bankNameController.text.trim(),
      branch: _branchController.text.trim(),
      ifscCode: _ifscCodeController.text.trim().toUpperCase(),
      branchAddress: _branchController.text.trim(),
    );

    _accountsNotifier.value = [..._accountsNotifier.value, newAccount];

    _accountNumberController.clear();
    _accountHolderController.clear();
    _bankNameController.clear();
    _branchController.clear();
    _ifscCodeController.clear();

    AppSnackbar.success('Bank account added successfully', context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar.transparent(title: context.l10n.myBankDetailsTitle),
      body: SingleChildScrollView(
        padding: context.horizontalEdgeInsets,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.xl.h,

              // 1. Saved Bank Account Section
              ValueListenableBuilder<List<BankAccount>>(
                valueListenable: _accountsNotifier,
                builder: (context, accounts, _) {
                  if (accounts.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.savedBankAccount,
                        style: context.textTheme.titleMedium?.bold(),
                      ),
                      AppSpacing.sm.h,
                      ...accounts.map(
                        (account) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: BankAccountCard(account: account),
                        ),
                      ),
                      AppSpacing.lg.h,
                    ],
                  );
                },
              ),

              // 2. Add New Bank Account Section
              Text(
                context.l10n.addNewBankAccount,
                style: context.textTheme.titleMedium?.bold(),
              ),
              AppSpacing.md.h,

              // Form fields
              AppTextField(
                controller: _accountNumberController,
                decoration: InputDecoration(
                  hintText: context.l10n.accountNumber,
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) => Validators.required(context, value),
              ),
              AppSpacing.md.h,

              AppTextField(
                controller: _accountHolderController,
                decoration: InputDecoration(
                  hintText: context.l10n.accountHolder,
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) => Validators.required(context, value),
              ),
              AppSpacing.md.h,

              AppTextField(
                controller: _bankNameController,
                decoration: InputDecoration(hintText: context.l10n.bankName),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) => Validators.required(context, value),
              ),
              AppSpacing.md.h,

              AppTextField(
                controller: _branchController,
                decoration: InputDecoration(hintText: context.l10n.branch),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) => Validators.required(context, value),
              ),
              AppSpacing.md.h,

              AppTextField(
                controller: _ifscCodeController,
                decoration: InputDecoration(
                  hintText: context.l10n.ifscCode,
                ),
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                validator: (value) => Validators.ifsc(context, value),
              ),
              AppSpacing.xl.h,

              // Add Button
              AppButton(
                text: context.l10n.add,
                size: ButtonSize.large,
                onPressed: _handleAddAccount,
              ),
              AppSpacing.xxl.h,
            ],
          ),
        ),
      ),
    );
  }
}

class BankAccountCard extends StatelessWidget {
  final BankAccount account;
  const BankAccountCard({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return WrapperCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: Masked Account Number & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                account.accountNumber.masked(
                  showLast: 4,
                  type: MaskType.card,
                  maskChar: 'x',
                ),
                style: context.textTheme.titleMedium?.bold(),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit Button
                  QuickContainer(
                    w: 28,
                    h: 28,
                    shape: QuickContainerShape.circle,
                    color: context.colors.primaryContainer.withValues(
                      alpha: 0.5,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: context.colors.primary,
                    ),
                  ),
                  AppSpacing.xs.w,

                  // Delete Button
                  QuickContainer(
                    w: 28,
                    h: 28,
                    shape: QuickContainerShape.circle,
                    color: context.colors.errorContainer.withValues(alpha: 0.3),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 14,
                      color: context.colors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AppSpacing.sm.h,

          // Details row: Bank info & Account holder
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.bankName,
                      style: context.textTheme.bodySmall?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.xxs.h,
                    Text(
                      '${context.l10n.ifscCode}: ${account.ifscCode}',
                      style: context.textTheme.bodySmall?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.xxs.h,
                    Text(
                      '${context.l10n.branchAddress}: ${account.branchAddress ?? account.branch}',
                      style: context.textTheme.bodySmall?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                account.accountHolder,
                style: context.textTheme.bodyMedium?.semiBold(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
