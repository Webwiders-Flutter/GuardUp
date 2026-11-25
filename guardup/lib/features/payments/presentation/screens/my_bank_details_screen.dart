import 'package:flutter/material.dart';
import 'package:guardup/core/constants/api/database_tables.dart';
import 'package:guardup/core/constants/app_radius.dart';
import 'package:guardup/core/di/injection_container.dart';
import 'package:guardup/core/extensions/string.extension.dart';
import 'package:guardup/core/logger/app_logger.dart';
import 'package:guardup/features/auth/auth.dart';
import 'package:quick_container/quick_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/app_sizes.dart';
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

/// Screen allowing bodyguards and companies to manage their live bank account details.
class MyBankDetailsScreen extends StatefulWidget {
  static const route = '/my-bank-details';

  const MyBankDetailsScreen({super.key});

  @override
  State<MyBankDetailsScreen> createState() => _MyBankDetailsScreenState();
}

class _MyBankDetailsScreenState extends State<MyBankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchController = TextEditingController();
  final _ifscCodeController = TextEditingController();

  final ValueNotifier<List<BankAccount>> _accountsNotifier =
      ValueNotifier<List<BankAccount>>([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isSubmittingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<AuthBloc>()) {
      final authState = sl<AuthBloc>().state;
      final name = authState.displayName;
      if (name.isNotEmpty && name != 'User') {
        _accountHolderController.text = name;
      }
    }
    _loadBankAccounts();
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    _ifscCodeController.dispose();
    _accountsNotifier.dispose();
    _isLoadingNotifier.dispose();
    _isSubmittingNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadBankAccounts() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      if (mounted) _isLoadingNotifier.value = false;
      return;
    }

    try {
      final rows = await Supabase.instance.client
          .from(DatabaseTables.userBankAccounts)
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      final accounts = (rows as List<dynamic>)
          .map((r) => BankAccount.fromSupabase(r as Map<String, dynamic>))
          .toList();

      if (mounted) {
        _accountsNotifier.value = accounts;
      }
    } catch (e, st) {
      AppLogger.d('Error loading bank accounts: $e', tag: 'MyBankDetailsScreen', error: e, stackTrace: st);
    } finally {
      if (mounted) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  Future<void> _handleAddAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSubmittingNotifier.value) return;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    _isSubmittingNotifier.value = true;

    try {
      final payload = {
        'user_id': currentUserId,
        'account_number': _accountNumberController.text.trim(),
        'account_holder': _accountHolderController.text.trim(),
        'bank_name': _bankNameController.text.trim(),
        'branch': _branchController.text.trim(),
        'ifsc_code': _ifscCodeController.text.trim().toUpperCase(),
        'branch_address': _branchController.text.trim(),
        'is_primary': _accountsNotifier.value.isEmpty,
      };

      final inserted = await Supabase.instance.client
          .from(DatabaseTables.userBankAccounts)
          .insert(payload)
          .select()
          .single();

      final newAccount = BankAccount.fromSupabase(inserted);
      _accountsNotifier.value = [newAccount, ..._accountsNotifier.value];

      _accountNumberController.clear();
      _accountHolderController.clear();
      _bankNameController.clear();
      _branchController.clear();
      _ifscCodeController.clear();
      _formKey.currentState?.reset();

      if (mounted) {
        AppSnackbar.success('Bank account added successfully');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error('Failed to add bank account: $e');
      }
    } finally {
      if (mounted) {
        _isSubmittingNotifier.value = false;
      }
    }
  }

  Future<void> _handleDeleteAccount(BankAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Remove Bank Account',
          style: context.textTheme.titleMedium?.bold(),
        ),
        content: Text(
          'Are you sure you want to remove the bank account ending in ${account.accountNumber.length >= 4 ? account.accountNumber.substring(account.accountNumber.length - 4) : account.accountNumber}?',
          style: context.textTheme.bodyMedium?.colour(
            context.colors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colors.outline),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Remove',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client
            .from(DatabaseTables.userBankAccounts)
            .delete()
            .eq('id', account.id);

        _accountsNotifier.value = _accountsNotifier.value
            .where((a) => a.id != account.id)
            .toList();

        if (mounted) {
          AppSnackbar.success('Bank account removed');
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.error('Failed to remove account: $e');
        }
      }
    }
  }

  void _showEditAccountSheet(BankAccount account) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _EditBankAccountSheet(
        account: account,
        onAccountUpdated: (updated) {
          _accountsNotifier.value = _accountsNotifier.value
              .map((a) => a.id == updated.id ? updated : a)
              .toList();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(title: context.l10n.myBankDetailsTitle),
      body: SingleChildScrollView(
        padding: context.horizontalEdgeInsets,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.xl.h,

              // 1. Saved Bank Accounts Section
              ValueListenableBuilder<bool>(
                valueListenable: _isLoadingNotifier,
                builder: (context, isLoading, _) {
                  if (isLoading) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxl,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: context.colors.primary,
                        ),
                      ),
                    );
                  }

                  return ValueListenableBuilder<List<BankAccount>>(
                    valueListenable: _accountsNotifier,
                    builder: (context, accounts, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.l10n.savedBankAccount,
                                style: context.textTheme.titleMedium?.bold(),
                              ),
                              if (accounts.isNotEmpty)
                                Text(
                                  '${accounts.length} Saved',
                                  style: context.textTheme.labelSmall
                                      ?.bold()
                                      .colour(context.colors.primary),
                                ),
                            ],
                          ),
                          AppSpacing.sm.h,
                          if (accounts.isEmpty) ...[
                            WrapperCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_outlined,
                                    color: context.colors.outline,
                                    size: AppSizes.iconLg,
                                  ),
                                  AppSpacing.md.w,
                                  Expanded(
                                    child: Text(
                                      'No bank accounts saved yet. Add your details below for withdrawals and deposits.',
                                      style: context.textTheme.bodySmall
                                          ?.colour(
                                            context.colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            ...accounts.map(
                              (account) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: BankAccountCard(
                                  account: account,
                                  onEdit: () => _showEditAccountSheet(account),
                                  onDelete: () => _handleDeleteAccount(account),
                                ),
                              ),
                            ),
                          ],
                          AppSpacing.lg.h,
                        ],
                      );
                    },
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
                decoration: InputDecoration(hintText: context.l10n.ifscCode),
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                validator: (value) => Validators.ifsc(context, value),
              ),
              AppSpacing.xl.h,

              // Add Button
              ValueListenableBuilder<bool>(
                valueListenable: _isSubmittingNotifier,
                builder: (context, isSubmitting, _) {
                  return AppButton(
                    text: isSubmitting ? 'Adding...' : context.l10n.add,
                    isLoading: isSubmitting,
                    onPressed: isSubmitting ? null : _handleAddAccount,
                  );
                },
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
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BankAccountCard({
    super.key,
    required this.account,
    this.onEdit,
    this.onDelete,
  });

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
                  GestureDetector(
                    onTap: onEdit,
                    child: QuickContainer(
                      w: AppSizes.iconMdl,
                      h: AppSizes.iconMdl,
                      shape: QuickContainerShape.circle,
                      color: context.colors.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.edit_rounded,
                        size: AppSizes.iconXs,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                  AppSpacing.xs.w,

                  // Delete Button
                  GestureDetector(
                    onTap: onDelete,
                    child: QuickContainer(
                      w: AppSizes.iconMdl,
                      h: AppSizes.iconMdl,
                      shape: QuickContainerShape.circle,
                      color: context.colors.errorContainer.withValues(
                        alpha: 0.3,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: AppSizes.iconXs,
                        color: context.colors.error,
                      ),
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

/// Modal bottom sheet for editing an existing saved bank account.
class _EditBankAccountSheet extends StatefulWidget {
  final BankAccount account;
  final ValueChanged<BankAccount>? onAccountUpdated;

  const _EditBankAccountSheet({required this.account, this.onAccountUpdated});

  @override
  State<_EditBankAccountSheet> createState() => _EditBankAccountSheetState();
}

class _EditBankAccountSheetState extends State<_EditBankAccountSheet> {
  final _sheetFormKey = GlobalKey<FormState>();

  late final TextEditingController _accountNumberController;
  late final TextEditingController _accountHolderController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _branchController;
  late final TextEditingController _ifscCodeController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _accountNumberController = TextEditingController(
      text: widget.account.accountNumber,
    );
    _accountHolderController = TextEditingController(
      text: widget.account.accountHolder,
    );
    _bankNameController = TextEditingController(text: widget.account.bankName);
    _branchController = TextEditingController(text: widget.account.branch);
    _ifscCodeController = TextEditingController(text: widget.account.ifscCode);
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    _ifscCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!(_sheetFormKey.currentState?.validate() ?? false)) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final updatedPayload = {
        'account_number': _accountNumberController.text.trim(),
        'account_holder': _accountHolderController.text.trim(),
        'bank_name': _bankNameController.text.trim(),
        'branch': _branchController.text.trim(),
        'ifsc_code': _ifscCodeController.text.trim().toUpperCase(),
        'branch_address': _branchController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final updatedRow = await Supabase.instance.client
          .from(DatabaseTables.userBankAccounts)
          .update(updatedPayload)
          .eq('id', widget.account.id)
          .select()
          .single();

      final updatedAccount = BankAccount.fromSupabase(updatedRow);

      if (mounted) {
        widget.onAccountUpdated?.call(updatedAccount);
        Navigator.pop(context);
        AppSnackbar.success('Bank account updated successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackbar.error('Failed to update bank account: $e');
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
        child: Form(
          key: _sheetFormKey,
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
                'Edit Bank Account',
                style: context.textTheme.titleMedium?.bold().colour(
                  context.colors.onSurface,
                ),
              ),
              AppSpacing.xs.h,
              Text(
                'Update your account credentials for withdrawals and payouts.',
                style: context.textTheme.bodySmall?.colour(
                  context.colors.onSurfaceVariant,
                ),
              ),
              AppSpacing.lg.h,

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
                decoration: InputDecoration(hintText: context.l10n.ifscCode),
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                validator: (value) => Validators.ifsc(context, value),
              ),
              AppSpacing.xl.h,

              AppButton(
                text: _isSaving ? 'Saving...' : 'Save Changes',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _handleUpdate,
              ),
              AppSpacing.sm.h,
            ],
          ),
        ),
      ),
    );
  }
}
