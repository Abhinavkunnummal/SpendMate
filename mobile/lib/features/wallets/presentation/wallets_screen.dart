import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/data/app_data_repository.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallets & Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddWalletSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: ListenableBuilder(
          listenable: AppDataRepository.instance,
          builder: (context, _) {
            final repo = AppDataRepository.instance;
            final realWallets = repo.wallets;
            final netLiquidity = repo.netWorthPaise;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Liquidity Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL AVAILABLE LIQUIDITY', style: AppTypography.labelSmall(secondaryTextColor)),
                      const SizedBox(height: 6),
                      CurrencyText(
                        amountPaise: netLiquidity,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Across ${realWallets.length} connected financial accounts',
                        style: AppTypography.bodySmall(secondaryTextColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Accounts List
                Text('ACCOUNTS & CARDS', style: AppTypography.labelSmall(secondaryTextColor)),
                const SizedBox(height: 10),

                ...realWallets.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final w = entry.value;
                  IconData icon = Icons.account_balance_rounded;
                  Color color = AppColors.primary;
                  if (w.type == 'cash') {
                    icon = Icons.payments_rounded;
                    color = AppColors.orange;
                  } else if (w.type == 'card') {
                    icon = Icons.credit_card_rounded;
                    color = AppColors.coral;
                  }

                  return _walletCard(
                    name: w.name,
                    type: '${w.type.toUpperCase()} · ${w.accountNumberLast4}',
                    balancePaise: w.balancePaise,
                    icon: icon,
                    color: color,
                    isDefault: idx == 0,
                    isDark: isDark,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  );
                }),
                const SizedBox(height: 28),

            AppButton(
              text: 'Connect New Account',
              variant: ButtonVariant.outline,
              icon: const Icon(Icons.add_rounded, size: 20),
              onPressed: () => _showAddWalletSheet(context),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    ),
  ),
);
  }

  Widget _walletCard({
    required String name,
    required String type,
    required int balancePaise,
    required IconData icon,
    required Color color,
    required bool isDefault,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      const StatusBadge(label: 'Default', color: AppColors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(type, style: AppTypography.bodySmall(secondaryTextColor)),
              ],
            ),
          ),
          CurrencyText(
            amountPaise: balancePaise,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  void _showAddWalletSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Account or Wallet', style: AppTypography.titleLarge(AppColors.textPrimaryLight)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.account_balance_rounded, color: AppColors.primary),
              title: const Text('Bank Account'),
              subtitle: const Text('Savings or Current checking account'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card_rounded, color: AppColors.coral),
              title: const Text('Credit Card'),
              subtitle: const Text('Track card balance and billing cycle'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.wallet_rounded, color: AppColors.blue),
              title: const Text('UPI & Digital Wallet'),
              subtitle: const Text('Google Pay, PhonePe, Paytm'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
