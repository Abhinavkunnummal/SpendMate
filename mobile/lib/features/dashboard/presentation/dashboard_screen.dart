import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../core/data/app_data_repository.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Greeting & Profile Avatar (Dynamic Real User)
                ListenableBuilder(
                  listenable: AuthSessionManager.instance,
                  builder: (context, _) {
                    final auth = AuthSessionManager.instance;
                    final displayName = (auth.userName != null && auth.userName!.trim().isNotEmpty)
                        ? auth.userName!
                        : 'Friend';
                    final initials = displayName
                        .split(' ')
                        .where((s) => s.isNotEmpty)
                        .map((s) => s[0].toUpperCase())
                        .take(2)
                        .join();

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good morning,',
                                style: AppTypography.bodySmall(secondaryTextColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayName,
                                style: AppTypography.titleLarge(primaryTextColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
                                child: Text(
                                  initials.isNotEmpty ? initials : 'SM',
                                  style: AppTypography.labelLarge(AppColors.primary),
                                ),
                              ),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.coral,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? AppColors.backgroundDark : Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Apple Wallet Style Balance Card (Dynamic Real Balance)
                ListenableBuilder(
                  listenable: AppDataRepository.instance,
                  builder: (context, _) {
                    final repo = AppDataRepository.instance;
                    final netWorth = repo.netWorthPaise;
                    final income = repo.totalIncomePaise;
                    final spent = repo.totalSpentPaise;
                    final walletCount = repo.wallets.length;
                    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
                    final compactFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF16A878), Color(0xFF0D7C57)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.28),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL NET WORTH',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/wallets'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '$walletCount ${walletCount == 1 ? 'Wallet' : 'Wallets'}',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.chevron_right, size: 14, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(netWorth / 100),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.arrow_downward_rounded, size: 14, color: Colors.white),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Income', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
                                            Text(compactFormat.format(income / 100), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 28, color: Colors.white.withOpacity(0.2)),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 12.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.arrow_upward_rounded, size: 14, color: Colors.white),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Spent', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
                                              Text(compactFormat.format(spent / 100), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Quick Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _quickActionItem(
                      icon: Icons.add_rounded,
                      label: 'Add Expense',
                      color: AppColors.coral,
                      onTap: () => context.push('/add-transaction?type=expense'),
                      isDark: isDark,
                    ),
                    _quickActionItem(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Add Income',
                      color: AppColors.primary,
                      onTap: () => context.push('/add-transaction?type=income'),
                      isDark: isDark,
                    ),
                    _quickActionItem(
                      icon: Icons.luggage_outlined,
                      label: 'New Trip',
                      color: AppColors.blue,
                      onTap: () => context.push('/trips'),
                      isDark: isDark,
                    ),
                    _quickActionItem(
                      icon: Icons.document_scanner_outlined,
                      label: 'Scan Receipt',
                      color: AppColors.purple,
                      onTap: () => context.push('/receipt-scanner'),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Monthly Budget Progress Widget
                AppCard(
                  onTap: () => context.push('/budgets'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.track_changes_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Monthly Budget',
                                style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15),
                              ),
                            ],
                          ),
                          Text(
                            '68% Spent',
                            style: AppTypography.labelSmall(AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: 0.68,
                          minHeight: 8,
                          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: Text('₹34,000 spent', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall(secondaryTextColor))),
                          const SizedBox(width: 8),
                          Flexible(child: Text('₹16,000 left of ₹50,000', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall(secondaryTextColor))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Active Trips Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Trips', style: AppTypography.titleMedium(primaryTextColor)),
                    TextButton(
                      onPressed: () => context.push('/trips'),
                      child: Text('See All', style: AppTypography.labelSmall(AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Active Trip Card
                AppCard(
                  onTap: () => context.push('/trips/trip-manali-101'),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.blueLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.snowboarding_rounded, color: AppColors.blue, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manali Snow Expedition',
                              style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '4 members · 18 Nov - 24 Nov',
                              style: AppTypography.bodySmall(secondaryTextColor),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            '₹48,200',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text('You get ₹960', style: AppTypography.labelSmall(AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Recent Transactions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Transactions', style: AppTypography.titleMedium(primaryTextColor)),
                    TextButton(
                      onPressed: () => context.push('/transactions'),
                      child: Text('See All', style: AppTypography.labelSmall(AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Recent Transactions List (Dynamic Real User Transactions)
                ListenableBuilder(
                  listenable: AppDataRepository.instance,
                  builder: (context, _) {
                    final txs = AppDataRepository.instance.transactions;
                    if (txs.isEmpty) {
                      return AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 36, color: secondaryTextColor),
                              const SizedBox(height: 10),
                              Text('No transactions yet', style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(
                                'Tap "+ Add Expense" above to record your first spend!',
                                style: AppTypography.bodySmall(secondaryTextColor),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final recentTxs = txs.take(5).toList();
                    final timeFormat = DateFormat('dd MMM, h:mm a');

                    return Column(
                      children: recentTxs.map((tx) {
                        return _transactionItem(
                          icon: tx.icon,
                          title: tx.title,
                          category: '${tx.category} · ${tx.wallet}',
                          amountPaise: tx.amountPaise,
                          isExpense: tx.isExpense,
                          time: timeFormat.format(tx.date),
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () => context.push('/transactions/${tx.id}'),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _transactionItem({
    required IconData icon,
    required String title,
    required String category,
    required int amountPaise,
    required bool isExpense,
    required String time,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isExpense ? AppColors.coralLight : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isExpense ? AppColors.coral : AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$category · $time',
                  style: AppTypography.bodySmall(secondaryTextColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CurrencyText(
            amountPaise: amountPaise,
            isExpense: isExpense,
            isIncome: !isExpense,
            showSign: true,
            fontSize: 15,
          ),
        ],
      ),
    );
  }
}
