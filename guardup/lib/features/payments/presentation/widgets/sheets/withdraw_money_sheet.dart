import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/payments/data/model/bank_account.model.dart';
import '/features/payments/presentation/screens/my_bank_details_screen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_sheet.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';

/// Modal bottom sheet allowing users to withdraw funds from their wallet
/// into a selected bank account.
class WithdrawMoneySheet extends StatefulWidget {
  /// Total available balance in the wallet.
  final double balance;

  const WithdrawMoneySheet({super.key, required this.balance});

  /// Presents the [WithdrawMoneySheet] using the standardized [AppSheet].
  static Future<void> show(BuildContext context, {required double balance}) {
    return AppSheet.show<void>(
      context: context,
      title: context.l10n.withdraw,
      subtitle: 'Transfer funds directly to your verified bank account',
      action: AppSheetHeaderAction.close,
      showHandle: true,
      showHeader: true,
      child: WithdrawMoneySheet(balance: balance),
    );
  }

  @override
  State<WithdrawMoneySheet> createState() => _WithdrawMoneySheetState();
}

class _WithdrawMoneySheetState extends State<WithdrawMoneySheet> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<BankAccount> _accounts = [];
  BankAccount? _selectedAccount;
  bool _isLoadingAccounts = true;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _loadBankAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBankAccounts() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      if (mounted) {
        setState(() {
          _accounts = BankAccount.fakeData;
          _selectedAccount = _accounts.isNotEmpty ? _accounts.first : null;
          _isLoadingAccounts = false;
        });
      }
      return;
    }

    try {
      final rows = await Supabase.instance.client
          .from(DatabaseTables.userBankAccounts)
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      final fetched = (rows as List<dynamic>)
          .map((r) => BankAccount.fromSupabase(r as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _accounts = fetched.isNotEmpty ? fetched : BankAccount.fakeData;
          _selectedAccount = _accounts.isNotEmpty ? _accounts.first : null;
          _isLoadingAccounts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _accounts = BankAccount.fakeData;
          _selectedAccount = _accounts.isNotEmpty ? _accounts.first : null;
          _isLoadingAccounts = false;
        });
      }
    }
  }

  void _applyPercentage(double fraction) {
    final target = widget.balance * fraction;
    _amountController.text = target.toStringAsFixed(2);
    _validateAmount();
  }

  void _validateAmount() {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      setState(() => _amountError = null);
      return;
    }

    final value = double.tryParse(text);
    if (value == null || value <= 0) {
      setState(
        () => _amountError = 'Please enter a valid amount greater than \$0',
      );
    } else if (value > widget.balance) {
      setState(
        () => _amountError =
            'Amount cannot exceed available balance (${widget.balance.toUsd} USD)',
      );
    } else {
      setState(() => _amountError = null);
    }
  }

  void _handleProceed() {
    _validateAmount();

    if (_selectedAccount == null) {
      AppSnackbar.show(
        context: context,
        type: SnackbarType.warning,
        title: 'Bank Account Required',
        message:
            'Please link or select a bank account to proceed with withdrawal.',
        useOverlay: true,
      );
      return;
    }

    final text = _amountController.text.trim();
    final value = double.tryParse(text);
    if (value == null || value <= 0 || value > widget.balance) {
      _validateAmount();
      return;
    }

    // Dismiss bottom sheet
    context.pop();

    // Display Coming Soon feedback notification
    AppSnackbar.show(
      context: context,
      type: SnackbarType.info,
      title: 'Coming Soon',
      message:
          'Withdrawal request for \$${value.toStringAsFixed(2)} to ${_selectedAccount?.bankName ?? 'Bank'} is under processing. Feature coming soon!',
      useOverlay: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Balance Display Card ──────────────────────────────────────────
          _buildBalanceCard(context),
          AppSpacing.lg.h,

          // ── Select Bank Account Section ───────────────────────────────────
          _buildBankSelectionSection(context),
          AppSpacing.lg.h,

          // ── Withdrawal Amount Input ───────────────────────────────────────
          _buildAmountInput(context),
          AppSpacing.sm.h,

          // ── Quick Percentage Shortcuts ───────────────────────────────────
          _buildQuickPercentageChips(context),
          AppSpacing.lg.h,

          // ── Fee & Delivery Breakdown ──────────────────────────────────────
          _buildTransferDetails(context),
          AppSpacing.xl.h,

          // ── Proceed Button ───────────────────────────────────────────────
          AppButton(
            text: 'Proceed to Withdraw',
            size: ButtonSize.large,
            onPressed: _handleProceed,
          ),
          AppSpacing.md.h,
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return QuickContainer(
      p: AppSpacing.md,
      radius: AppRadius.md,
      color: context.colors.surfaceContainer,
      border: Border.all(
        color: context.colors.outline.withValues(alpha: 0.25),
        width: 1,
      ),
      child: Row(
        children: [
          QuickContainer(
            w: 42,
            h: 42,
            shape: QuickContainerShape.circle,
            color: context.colors.primary.withValues(alpha: 0.15),
            alignment: Alignment.center,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: context.colors.primary,
              size: AppSizes.iconMd,
            ),
          ),
          AppSpacing.md.w,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Available Balance',
                  style: context.textTheme.labelMedium?.colour(
                    context.colors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '${widget.balance.toUsd} USD',
                  style: context.textTheme.titleLarge?.bold().colour(
                    context.colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          QuickContainer(
            px: AppSpacing.sm,
            py: AppSpacing.xs,
            radius: AppRadius.full,
            color: context.colors.successContainer.withValues(alpha: 0.4),
            child: Text(
              'Available',
              style: context.textTheme.labelSmall?.semiBold().colour(
                context.colors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankSelectionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Bank Account',
              style: context.textTheme.titleSmall?.bold(),
            ),
            GestureDetector(
              onTap: () {
                context.push(MyBankDetailsScreen.route);
              },
              child: Text(
                '+ Add Account',
                style: context.textTheme.labelMedium?.bold().colour(
                  context.colors.primary,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.sm.h,
        if (_isLoadingAccounts)
          Center(
            child: Padding(
              padding: AppSpacing.md.allPadding,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.primary,
                ),
              ),
            ),
          )
        else if (_accounts.isEmpty)
          QuickContainer(
            p: AppSpacing.md,
            radius: AppRadius.md,
            color: context.colors.surfaceContainer,
            border: Border.all(
              color: context.colors.outline.withValues(alpha: 0.25),
              width: 1,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  color: context.colors.onSurfaceVariant,
                ),
                AppSpacing.md.w,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No bank accounts linked',
                        style: context.textTheme.bodyMedium?.bold(),
                      ),
                      Text(
                        'Add a bank account to receive your payouts',
                        style: context.textTheme.bodySmall?.colour(
                          context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  text: 'Add',
                  size: ButtonSize.small,
                  onPressed: () => context.push(MyBankDetailsScreen.route),
                ),
              ],
            ),
          )
        else
          Column(
            children: _accounts.map((account) {
              final isSelected = _selectedAccount?.id == account.id;
              final maskedNumber = account.accountNumber.length > 4
                  ? '•••• •••• •••• ${account.accountNumber.substring(account.accountNumber.length - 4)}'
                  : account.accountNumber;

              return Padding(
                padding: AppSpacing.xs.bPadding,
                child: QuickContainer(
                  onTap: () {
                    setState(() => _selectedAccount = account);
                  },
                  p: AppSpacing.md,
                  radius: AppRadius.md,
                  color: isSelected
                      ? context.colors.surfaceContainer
                      : context.colors.surfaceContainer,
                  border: Border.all(
                    color: isSelected
                        ? context.colors.primary
                        : context.colors.outline.withValues(alpha: 0.2),
                    width: isSelected ? 1.5 : 1,
                  ),
                  child: Row(
                    children: [
                      QuickContainer(
                        w: 36,
                        h: 36,
                        shape: QuickContainerShape.circle,
                        color: isSelected
                            ? context.colors.primary.withValues(alpha: 0.15)
                            : context.colors.surfaceContainerHigh,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.account_balance_rounded,
                          color: isSelected
                              ? context.colors.primary
                              : context.colors.onSurfaceVariant,
                          size: AppSizes.iconSm,
                        ),
                      ),
                      AppSpacing.md.w,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.bankName,
                              style: context.textTheme.titleSmall?.bold(),
                            ),
                            AppSpacing.xs.h,
                            Text(
                              '$maskedNumber • ${account.accountHolder}',
                              style: context.textTheme.bodySmall?.colour(
                                context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected
                            ? context.colors.primary
                            : context.colors.outline,
                        size: AppSizes.iconMd,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAmountInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Withdraw Amount', style: context.textTheme.titleSmall?.bold()),
        AppSpacing.xs.h,
        AppTextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: '0.00',
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                '\$',
                style: context.textTheme.titleMedium?.bold().colour(
                  context.colors.onSurface,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixText: 'USD',
            suffixStyle: context.textTheme.labelMedium?.bold().colour(
              context.colors.onSurfaceVariant,
            ),
            errorText: _amountError,
          ),
          onChanged: (_) => _validateAmount(),
        ),
      ],
    );
  }

  Widget _buildQuickPercentageChips(BuildContext context) {
    final chips = [('25%', 0.25), ('50%', 0.50), ('75%', 0.75), ('Max', 1.0)];

    return Row(
      children: chips.map((chip) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
            child: QuickContainer(
              onTap: () => _applyPercentage(chip.$2),
              py: AppSpacing.xs,
              radius: AppRadius.sm,
              alignment: Alignment.center,
              color: context.colors.surfaceContainer,
              border: Border.all(
                color: context.colors.outline.withValues(alpha: 0.25),
              ),
              child: Text(
                chip.$1,
                style: context.textTheme.labelSmall?.semiBold().colour(
                  context.colors.onSurface,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransferDetails(BuildContext context) {
    return QuickContainer(
      p: AppSpacing.md,
      radius: AppRadius.md,
      color: context.colors.surfaceContainer,
      border: Border.all(
        color: context.colors.outline.withValues(alpha: 0.2),
        width: 1,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transfer Fee',
                style: context.textTheme.bodySmall?.colour(
                  context.colors.onSurfaceVariant,
                ),
              ),
              Text(
                'Free (\$0.00)',
                style: context.textTheme.bodySmall?.semiBold().colour(
                  context.colors.success,
                ),
              ),
            ],
          ),
          AppSpacing.xs.h,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated Arrival',
                style: context.textTheme.bodySmall?.colour(
                  context.colors.onSurfaceVariant,
                ),
              ),
              Text(
                '1 - 3 Business Days',
                style: context.textTheme.bodySmall?.semiBold().colour(
                  context.colors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
