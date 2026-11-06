import 'package:flutter/material.dart';
import 'package:guardup/core/extensions/number.extension.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';

/// Top card in the wallet screen displaying current balance and primary actions
/// (Withdraw and Add Bank Account) backed by the luxury gold [balanceBackground] SVG.
class WalletBalanceCard extends StatelessWidget {
  /// Current available balance.
  final double balance;

  /// Triggered when the user taps "Withdraw".
  final VoidCallback? onWithdraw;

  /// Triggered when the user taps "Add Bank Account".
  final VoidCallback? onAddBankAccount;

  const WalletBalanceCard({
    super.key,
    this.balance = 250.50,
    this.onWithdraw,
    this.onAddBankAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: 3.wPercent(context).lPadding,
      child: QuickContainer(
        py: AppSpacing.xl,
        px: AppSpacing.huge,
        image: DecorationImage(
          image: AssetImage(Assets.png.balanceBackground.path),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Balance Label
            Text(
              context.l10n.balance,
              style: context.textTheme.titleSmall
                  ?.regular()
                  .colour(context.colors.onSurface.withValues(alpha: 0.85))
                  .increaseSize(1),
            ),
            AppSpacing.md.h,

            // Balance Value
            Text(
              "${balance.toUsd} USD",
              style: context.textTheme.headlineMedium?.bold(),
            ),
            AppSpacing.sm.h,

            // Action Buttons Row
            Row(
              children: [
                // Withdraw Button (White background, Dark text)
                Expanded(
                  child: AppButton(
                    text: context.l10n.withdraw,
                    size: ButtonSize.normal,
                    backgroundColor: context.colors.onSurface,
                    foregroundColor: context.colors.onPrimary,
                    onPressed: onWithdraw,
                  ),
                ),
                AppSpacing.sm.w,

                // Add Bank Account Button (Elevated surface container, White text)
                Expanded(
                  child: AppButton(
                    text: context.l10n.addBankAccount,
                    size: ButtonSize.normal,
                    type: .secondaryOff,
                    onPressed: onAddBankAccount,
                  ),
                ),
              ],
            ),
            AppSpacing.md.h,
          ],
        ),
      ),
    );
  }
}
