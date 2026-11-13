import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';

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
                // Top Header: Greeting & Profile Avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning,',
                          style: AppTypography.bodySmall(secondaryTextColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kunal Verma',
                          style: AppTypography.titleLarge(primaryTextColor),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
                            child: Text(
                              'KV',
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
                ),
                const SizedBox(height: 20),

                // Apple Wallet Style Balance Card
                Container(
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
                              child: const Row(
                                children: [
                                  Text(
                                    '4 Wallets',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.chevron_right, size: 14, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '₹1,42,850.00',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Income', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
                                      const Text('₹1,85,000', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                    ],
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
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Spent', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
                                        const Text('₹42,150', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                      ],
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
                          Text('₹34,000 spent', style: AppTypography.bodySmall(secondaryTextColor)),
                          Text('₹16,000 left of ₹50,000', style: AppTypography.bodySmall(secondaryTextColor)),
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

                // Recent Transactions List
                _transactionItem(
                  icon: Icons.restaurant_rounded,
                  title: 'Blue Tokai Coffee Roasters',
                  category: 'Food & Dining · HDFC Bank',
                  amountPaise: 48000,
                  isExpense: true,
                  time: 'Today, 10:30 AM',
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  onTap: () => context.push('/transactions/tx-101'),
                ),
                _transactionItem(
                  icon: Icons.work_outline_rounded,
                  title: 'Client Milestone Payment',
                  category: 'Freelance · Google Pay',
                  amountPaise: 4500000,
                  isExpense: false,
                  time: 'Yesterday, 4:15 PM',
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  onTap: () => context.push('/transactions/tx-102'),
                ),
                _transactionItem(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Apple Store Purchase',
                  category: 'Electronics · ICICI Credit Card',
                  amountPaise: 890000,
                  isExpense: true,
                  time: '11 Nov, 2:40 PM',
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  onTap: () => context.push('/transactions/tx-103'),
                ),
                _transactionItem(
                  icon: Icons.local_gas_station_rounded,
                  title: 'HP Auto Fuel',
                  category: 'Transport · Cash',
                  amountPaise: 250000,
                  isExpense: true,
                  time: '10 Nov, 8:10 PM',
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  onTap: () => context.push('/transactions/tx-104'),
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
