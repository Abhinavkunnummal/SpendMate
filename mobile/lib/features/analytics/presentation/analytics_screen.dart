import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/data/app_data_repository.dart';
import '../../../core/services/app_sound_service.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 1; // 0: Week, 1: Month, 2: Year

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics'),
        centerTitle: false,
      ),
      body: ListenableBuilder(
        listenable: AppDataRepository.instance,
        builder: (context, _) {
          final repo = AppDataRepository.instance;
          final allTxs = repo.transactions;
          final now = DateTime.now();

          // Filter by period
          List<TransactionModel> periodTxs = [];
          String periodTitle = 'This Month';
          List<Map<String, dynamic>> barData = [];

          if (_selectedPeriod == 0) {
            // Week (Past 7 days)
            periodTitle = 'Past 7 Days';
            final sevenDaysAgo = now.subtract(const Duration(days: 7));
            periodTxs = allTxs.where((t) => t.date.isAfter(sevenDaysAgo)).toList();

            for (int i = 6; i >= 0; i--) {
              final d = now.subtract(Duration(days: i));
              final dayTxs = periodTxs.where((t) => t.date.year == d.year && t.date.month == d.month && t.date.day == d.day);
              final spent = dayTxs.where((t) => t.isExpense).fold(0, (sum, t) => sum + t.amountPaise);
              barData.add({
                'label': DateFormat('E').format(d),
                'amountPaise': spent,
              });
            }
          } else if (_selectedPeriod == 1) {
            // Month (Past 4 Weeks)
            periodTitle = 'This Month';
            periodTxs = allTxs.where((t) => t.date.year == now.year && t.date.month == now.month).toList();

            for (int w = 1; w <= 4; w++) {
              final weekTxs = periodTxs.where((t) {
                final day = t.date.day;
                if (w == 1) return day <= 7;
                if (w == 2) return day > 7 && day <= 14;
                if (w == 3) return day > 14 && day <= 21;
                return day > 21;
              });
              final spent = weekTxs.where((t) => t.isExpense).fold(0, (sum, t) => sum + t.amountPaise);
              barData.add({
                'label': 'W$w',
                'amountPaise': spent,
              });
            }
          } else {
            // Year (12 Months)
            periodTitle = '${now.year} Annual';
            periodTxs = allTxs.where((t) => t.date.year == now.year).toList();

            for (int m = 1; m <= 12; m++) {
              final monthTxs = periodTxs.where((t) => t.date.month == m);
              final spent = monthTxs.where((t) => t.isExpense).fold(0, (sum, t) => sum + t.amountPaise);
              barData.add({
                'label': DateFormat('MMM').format(DateTime(now.year, m, 1)),
                'amountPaise': spent,
              });
            }
          }

          final inflowPaise = periodTxs.where((t) => !t.isExpense).fold(0, (sum, t) => sum + t.amountPaise);
          final outflowPaise = periodTxs.where((t) => t.isExpense).fold(0, (sum, t) => sum + t.amountPaise);
          final netSavingsPaise = inflowPaise - outflowPaise;

          // Compute max bar amount for scaling
          final maxBar = barData.fold<int>(1, (max, item) => (item['amountPaise'] as int) > max ? item['amountPaise'] as int : max);

          // Category distribution
          final Map<String, int> catSpending = {};
          for (var t in periodTxs.where((t) => t.isExpense)) {
            catSpending[t.category] = (catSpending[t.category] ?? 0) + t.amountPaise;
          }
          final sortedCats = catSpending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Segmented Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _periodTab('Week', 0, isDark, primaryTextColor, secondaryTextColor),
                      _periodTab('Month', 1, isDark, primaryTextColor, secondaryTextColor),
                      _periodTab('Year', 2, isDark, primaryTextColor, secondaryTextColor),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Cashflow Overview Card
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NET SAVINGS ($periodTitle)', style: AppTypography.labelSmall(secondaryTextColor)),
                      const SizedBox(height: 6),
                      Text(
                        '₹${(netSavingsPaise / 100).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: netSavingsPaise >= 0 ? AppColors.primary : AppColors.coral,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${(outflowPaise / 100).toStringAsFixed(0)} total spent across ${periodTxs.where((t) => t.isExpense).length} purchases',
                        style: AppTypography.bodySmall(secondaryTextColor),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Inflow', style: AppTypography.bodySmall(secondaryTextColor)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '+₹${(inflowPaise / 100).toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Outflow', style: AppTypography.bodySmall(secondaryTextColor)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '-₹${(outflowPaise / 100).toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.coral),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Interactive Spending Bar Chart
                Text('SPENDING PATTERN ($periodTitle)', style: AppTypography.labelSmall(secondaryTextColor)),
                const SizedBox(height: 10),
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Expenditure Distribution', style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15)),
                          Text('Max: ₹${(maxBar / 100).toStringAsFixed(0)}', style: AppTypography.bodySmall(secondaryTextColor)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Bar Graph Rows
                      SizedBox(
                        height: 140,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: barData.map((b) {
                            final amount = b['amountPaise'] as int;
                            final double ratio = maxBar > 0 ? (amount / maxBar).clamp(0.05, 1.0) : 0.05;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (amount > 0)
                                      Text(
                                        '₹${(amount / 100).toStringAsFixed(0)}',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: secondaryTextColor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 100 * ratio,
                                      decoration: BoxDecoration(
                                        color: amount > 0 ? AppColors.primary : (isDark ? Colors.white12 : Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      b['label'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: primaryTextColor,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Top Categories Breakdown
                Text('TOP SPENDING CATEGORIES', style: AppTypography.labelSmall(secondaryTextColor)),
                const SizedBox(height: 10),

                if (sortedCats.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text('No expenditures recorded for $periodTitle', style: AppTypography.bodySmall(secondaryTextColor)),
                    ),
                  )
                else
                  ...sortedCats.map((cat) {
                    final catPercent = outflowPaise > 0 ? ((cat.value / outflowPaise) * 100).toStringAsFixed(1) : '0';
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.coral.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.category_rounded, size: 20, color: AppColors.coral),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat.key, style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14)),
                                const SizedBox(height: 2),
                                Text('$catPercent% of total outflows', style: AppTypography.bodySmall(secondaryTextColor)),
                              ],
                            ),
                          ),
                          Text(
                            '₹${(cat.value / 100).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.coral),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _periodTab(String title, int index, bool isDark, Color primaryColor, Color secondaryColor) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AppSoundService.playSuccess();
          setState(() => _selectedPeriod = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : secondaryColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
