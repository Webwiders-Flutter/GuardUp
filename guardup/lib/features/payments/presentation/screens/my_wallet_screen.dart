import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/state/api_state.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
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
  const MyWalletScreen({super.key});

  @override
  State<MyWalletScreen> createState() => _MyWalletScreenState();
}

class _MyWalletScreenState extends State<MyWalletScreen> {
  late final PaginationController<TransactionModel> _paginationController;
  late final ValueNotifier<double> _balanceNotifier;

  @override
  void initState() {
    super.initState();
    _balanceNotifier = ValueNotifier<double>(250.0);

    // Initial 8 items from fakeData matching the design mockup
    final initialItems = TransactionModel.fakeData.take(8).toList();

    _paginationController = PaginationController<TransactionModel>(
      initialState: PaginationState<TransactionModel>(
        items: initialItems,
        total: TransactionModel.fakeData.length,
        status: const ApiState.success(null),
      ),
      onRefresh: _handleRefresh,
      onLoadMore: _handleLoadMore,
    );
  }

  @override
  void dispose() {
    _paginationController.dispose();
    _balanceNotifier.dispose();
    super.dispose();
  }

  /// Pull-to-refresh callback simulates real-world network refresh.
  Future<void> _handleRefresh() async {
    if (!mounted) return;

    final refreshedItems = TransactionModel.fakeData.take(8).toList();
    _paginationController.updateState(
      PaginationState<TransactionModel>(
        items: refreshedItems,
        total: TransactionModel.fakeData.length,
        status: const ApiState.success(null),
      ),
    );
  }

  /// Infinite scroll page-load callback.
  Future<void> _handleLoadMore() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final currentItems = _paginationController.value.items;
    final nextItems = TransactionModel.fakeData
        .skip(currentItems.length)
        .take(4)
        .toList();

    if (nextItems.isEmpty) return;

    final updated = [...currentItems, ...nextItems];
    _paginationController.updateState(
      _paginationController.value.copyWith(
        items: updated,
        loadMoreStatus: const ApiState.success(null),
      ),
    );
  }

  void _handleWithdraw() {
    AppSnackbar.info(
      'Withdrawal service will process funds to your linked account.',
      context: context,
    );
  }

  void _handleAddBankAccount() {
    context.push(AppRoutes.myBankDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar.transparent(
        title: context.l10n.myWalletTitle,
        showBackIcon: true,
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
            return TransactionCard(
              transaction: transaction,
              onTap: () {
                AppSnackbar.info(
                  '${transaction.title} • ${transaction.amountFormatted}',
                  context: context,
                );
              },
            );
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
        ValueListenableBuilder<double>(
          valueListenable: _balanceNotifier,
          builder: (context, balance, _) {
            return WalletBalanceCard(
              balance: balance,
              currency: 'USD',
              onWithdraw: _handleWithdraw,
              onAddBankAccount: _handleAddBankAccount,
            );
          },
        ),
        AppSpacing.xl.h,

        // Transaction History Header + Date Filter (QuickContainer)
        Padding(
          padding: context.horizontalEdgeInsets,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                context.l10n.transactionHistory,
                style: context.textTheme.titleLarge?.regular(),
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
