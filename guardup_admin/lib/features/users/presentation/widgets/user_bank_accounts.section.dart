import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/string.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/users/data/models/user_bank_account.model.dart';
import '/features/users/data/models/user_model.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/sections/app_detail_section.dart';
import '/shared/widgets/sections/app_detail_tile.dart';

/// Payout bank accounts of a bodyguard / company (read-only).
class UserBankAccountsSection extends StatelessWidget {
  const UserBankAccountsSection({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Ordered primary first by UsersRepository.getDetails.
    final accounts = user.bankAccounts ?? const <UserBankAccountModel>[];

    return AppDetailSection(
      title: 'Bank Accounts',
      subtitle: accounts.isEmpty
          ? 'No payout account added yet'
          : '${accounts.length} payout '
                '${accounts.length == 1 ? 'account' : 'accounts'}',
      icon: Icons.account_balance_outlined,
      child: accounts.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'User has not added any bank account yet.',
                style: context.textTheme.bodyMedium?.colour(
                  colors.onSurfaceSecondary,
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < accounts.length; i++) ...[
                  if (i > 0) AppSpacing.sm.h,
                  _BankAccountCard(account: accounts[i]),
                ],
              ],
            ),
    );
  }
}

class _BankAccountCard extends StatefulWidget {
  const _BankAccountCard({required this.account});

  final UserBankAccountModel account;

  @override
  State<_BankAccountCard> createState() => _BankAccountCardState();
}

class _BankAccountCardState extends State<_BankAccountCard> {
  bool _showNumber = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final account = widget.account;
    final branchAddress = account.branchAddress?.trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.backgroundLight,
        borderRadius: AppRadius.smRadius,
        border: Border.all(
          color: account.isPrimary
              ? colors.primary.withValues(alpha: 0.35)
              : colors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.xsRadius,
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              AppSpacing.md.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.bankName,
                      style: context.textTheme.bodyMedium?.bold(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    (AppSpacing.xs / 2).h,
                    Text(
                      account.accountHolder,
                      style: context.textTheme.bodySmall?.colour(
                        colors.onSurfaceSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (account.isPrimary)
                AppChip(
                  title: 'Primary',
                  icon: Icons.star_rounded,
                  color: colors.primary,
                  size: AppChipSize.small,
                ),
            ],
          ),
          AppSpacing.sm.h,
          Divider(color: colors.borderLight.withValues(alpha: 0.5), height: 1),
          // Masked by default; tap to reveal, then the tile's copy action
          // copies the full number.
          AppDetailTile(
            label: 'Account Number',
            value: _showNumber
                ? account.accountNumber
                : account.accountNumber.masked(
                    type: MaskType.card,
                    showLast: 4,
                  ),
            icon: Icons.numbers_rounded,
            onTap: () => setState(() => _showNumber = !_showNumber),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showNumber) ...[
                  IconButton(
                    icon: Icon(
                      Icons.copy_rounded,
                      size: AppSpacing.md + 2,
                      color: colors.onSurfaceSecondary.withValues(alpha: 0.6),
                    ),
                    tooltip: 'Copy Account Number',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: AppSpacing.md,
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: account.accountNumber),
                      );
                      AppSnackbar.show(
                        message: 'Copied Account Number to clipboard',
                        type: SnackbarType.success,
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),
                  AppSpacing.sm.w,
                ],
                IconButton(
                  icon: Icon(
                    _showNumber
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: AppSpacing.md + 2,
                    color: colors.onSurfaceSecondary,
                  ),
                  tooltip: _showNumber ? 'Hide number' : 'Show number',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: AppSpacing.md,
                  onPressed: () => setState(() => _showNumber = !_showNumber),
                ),
              ],
            ),
          ),
          AppDetailTile(
            label: 'IFSC Code',
            value: account.ifscCode,
            icon: Icons.qr_code_2_rounded,
            isCopyable: true,
          ),
          AppDetailTile(
            label: 'Branch',
            value: account.branch,
            icon: Icons.store_mall_directory_outlined,
          ),
          if (branchAddress != null && branchAddress.isNotEmpty)
            AppDetailTile(
              label: 'Branch Address',
              value: branchAddress,
              icon: Icons.location_on_outlined,
            ),
        ],
      ),
    );
  }
}
