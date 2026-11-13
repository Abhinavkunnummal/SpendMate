import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/auth/auth_session_manager.dart';

class BalancesScreen extends StatelessWidget {
  final String tripId;
  const BalancesScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balances & Settlements'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User personal standing hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16A878), Color(0xFF0F8A62)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR NET GROUP STANDING',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'You are owed ₹960.00',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '2 members will pay you directly to settle up.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Optimal Suggested Payments Section (Debt Minimizer output)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'SUGGESTED PAYMENTS (3)',
                    style: AppTypography.labelSmall(secondaryTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Debt Minimizer Active',
                  style: AppTypography.labelSmall(AppColors.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 10),

            _suggestedPaymentCard(
              context: context,
              fromName: 'Rohan Mehra',
              toName: '${AuthSessionManager.instance.userName ?? 'You'} (You)',
              amountPaise: 48000,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _suggestedPaymentCard(
              context: context,
              fromName: 'Pooja Nair',
              toName: '${AuthSessionManager.instance.displayName} (You)',
              amountPaise: 48000,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _suggestedPaymentCard(
              context: context,
              fromName: 'Pooja Nair',
              toName: 'Aarav Sharma',
              amountPaise: 16000,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 24),

            // Individual Net Balances
            Text('INDIVIDUAL NET BALANCES', style: AppTypography.labelSmall(secondaryTextColor)),
            const SizedBox(height: 10),

            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _balanceRow('${AuthSessionManager.instance.displayName} (You)', 96000, true, primaryTextColor),
                  const Divider(),
                  _balanceRow('Aarav Sharma', 16000, true, primaryTextColor),
                  const Divider(),
                  _balanceRow('Rohan Mehra', -48000, false, primaryTextColor),
                  const Divider(),
                  _balanceRow('Pooja Nair', -64000, false, primaryTextColor),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _suggestedPaymentCard({
    required BuildContext context,
    required String fromName,
    required String toName,
    required int amountPaise,
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTypography.bodyMedium(primaryTextColor),
                    children: [
                      TextSpan(text: fromName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const TextSpan(text: ' pays '),
                      TextSpan(text: toName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text('UPI Direct Transfer', style: AppTypography.bodySmall(secondaryTextColor)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CurrencyText(amountPaise: amountPaise, fontSize: 16, fontWeight: FontWeight.w700),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => context.push('/settlements/settle-101'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Settle Up',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceRow(String name, int amountPaise, bool getsMoney, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: AppTypography.bodyMedium(textColor).copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Text(
                getsMoney ? 'receives ' : 'owes ',
                style: TextStyle(fontSize: 12, color: getsMoney ? AppColors.primary : AppColors.coral),
              ),
              CurrencyText(
                amountPaise: amountPaise.abs(),
                customColor: getsMoney ? AppColors.primary : AppColors.coral,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
