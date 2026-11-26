import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import 'my_bank_details_screen.dart';
import '../../data/fixtures/payments.fixtures.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/state/api_state.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../../data/model/transaction.model.dart';
import '../widgets/sheets/withdraw_money_sheet.dart';
import '../widgets/transaction_card.dart';
import '../widgets/transaction_date_filter.dart';
import '../widgets/wallet_balance_card.dart';

/// Screen displaying user's digital wallet, balance card, and paginated
/// transaction history.
class MyWalletScreen extends StatefulWidget {
  static const route = '/my-wallet';

  const MyWalletScreen({super.key});

  @override
  State<MyWalletScreen> createState() => _MyWalletScreenState();
}

class _MyWalletScreenState extends State<MyWalletScreen> {
  late final PaginationController<TransactionModel> _paginationController;
  String _selectedFilter = 'All';
  static const double _walletBalance = 250.50;

  @override
  void initState() {
    super.initState();

    _paginationController = PaginationController<TransactionModel>(
      initialState: PaginationState<TransactionModel>(
        items: transactionFixtures,
        total: transactionFixtures.length,
        status: const ApiState.success(null),
      ),
    );
  }

  @override
  void dispose() {
    _paginationController.dispose();
    super.dispose();
  }

  void _handleWithdraw() {
    WithdrawMoneySheet.show(context, balance: _walletBalance);
  }

  void _handleAddBankAccount() {
    context.push(MyBankDetailsScreen.route);
  }

  void _onFilterChanged(String filter) {
    if (_selectedFilter == filter) return;
    setState(() => _selectedFilter = filter);

    final all = transactionFixtures;
    final List<TransactionModel> filtered;
    if (filter == 'Withdrawals') {
      filtered = all.where((t) => t.type.isDebit).toList();
    } else if (filter == 'Earnings') {
      filtered = all.where((t) => t.type.isCredit).toList();
    } else {
      filtered = all;
    }

    _paginationController.updateState(
      PaginationState<TransactionModel>(
        items: filtered,
        total: filtered.length,
        status: const ApiState.success(null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(
        title: context.l10n.myWalletTitle,
        showBackIcon: true,
        fontSize: 14,
      ),
      body: SafeArea(
        child: AppPagination<TransactionModel>.list(
          controller: _paginationController,
          header: _buildHeader(context),
          separatorBuilder: (context, index) => Column(
            children: [
              AppSpacing.md.h,
              Divider(
                color: context.colors.outline.withValues(alpha: 0.35),
                height: 1,
                thickness: 1,
              ),
              AppSpacing.md.h,
            ],
          ),
          itemBuilder: (context, transaction, index) {
            return TransactionCard(transaction: transaction);
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSpacing.md.h,

        // Upper Balance Card with luxury SVG background
        WalletBalanceCard(
          balance: _walletBalance,
          onWithdraw: _handleWithdraw,
          onAddBankAccount: _handleAddBankAccount,
        ),
        AppSpacing.lg.h,

        // Transaction History Header + Date Filter (QuickContainer)
        Padding(
          padding: context.horizontalEdgeInsets,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                context.l10n.transactionHistory,
                style: context.textTheme.titleLarge,
              ),
              const TransactionDateFilter(),
            ],
          ),
        ),
        AppSpacing.md.h,

        // Filter Pills: All | Earnings | Withdrawals
        Padding(
          padding: context.horizontalEdgeInsets,
          child: Row(
            children: [
              _buildFilterPill(context, 'All'),
              AppSpacing.sm.w,
              _buildFilterPill(context, 'Earnings'),
              AppSpacing.sm.w,
              _buildFilterPill(context, 'Withdrawals'),
            ],
          ),
        ),
        AppSpacing.lg.h,
      ],
    );
  }

  Widget _buildFilterPill(BuildContext context, String label) {
    final isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () => _onFilterChanged(label),
      child: QuickContainer(
        px: AppSpacing.md,
        py: AppSpacing.xs + 2,
        radius: AppRadius.full,
        color: isSelected
            ? context.colors.onSurface
            : context.colors.surfaceContainer,
        border: Border.all(
          color: isSelected
              ? context.colors.onSurface
              : context.colors.outline.withValues(alpha: 0.25),
          width: 1,
        ),
        child: Text(
          label,
          style: context.textTheme.labelMedium?.semiBold().colour(
            isSelected
                ? context.colors.onPrimary
                : context.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
