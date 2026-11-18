import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'my_bank_details_screen.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/state/api_state.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../../data/model/transaction.model.dart';
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

  @override
  void initState() {
    super.initState();
    // Initial 8 items from fakeData matching the design mockup
    final initialItems = TransactionModel.fakeData.take(8).toList();

    _paginationController = PaginationController<TransactionModel>(
      initialState: PaginationState<TransactionModel>(
        items: initialItems,
        total: TransactionModel.fakeData.length,
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
    context.push(MyBankDetailsScreen.route);
  }

  void _handleAddBankAccount() {
    context.push(MyBankDetailsScreen.route);
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
          balance: 0,
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
        AppSpacing.xl.h,
      ],
    );
  }
}
