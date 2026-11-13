import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/data/app_data_repository.dart';
import '../../../core/services/app_sound_service.dart';
import 'package:intl/intl.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  void _showSetBudgetDialog(BuildContext context) {
    final currentCap = AppDataRepository.instance.monthlyBudgetCapPaise ~/ 100;
    final ctrl = TextEditingController(text: currentCap.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set Monthly Spending Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set your target budget limit for this month. SpendMate will alert you if your expenses exceed this limit.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Target (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(ctrl.text.trim()) ?? 5000;
              await AppDataRepository.instance.setMonthlyBudgetCap(val * 100);
              AppSoundService.playSuccess();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Monthly budget set to ₹${NumberFormat('#,##,##0').format(val)}!'), backgroundColor: AppColors.primary),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save Budget', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final now = DateTime.now();
    final currentMonthStr = DateFormat('MMMM yyyy').format(now);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day + 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets & Targets'),
        actions: [
          IconButton(
            tooltip: 'Adjust Budget Cap',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => _showSetBudgetDialog(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: AppDataRepository.instance,
        builder: (context, _) {
          final repo = AppDataRepository.instance;
          final capPaise = repo.monthlyBudgetCapPaise;
          final spentPaise = repo.totalSpentThisMonthPaise;
          final isExceeded = repo.isBudgetCapExceeded;
          final remainingPaise = repo.budgetRemainingPaise;

          final double ratio = capPaise > 0 ? (spentPaise / capPaise).clamp(0.0, 1.0) : 0.0;
          final percentUsed = capPaise > 0 ? ((spentPaise / capPaise) * 100).round() : 0;
          final dailySafePace = remainingPaise > 0 && daysLeft > 0 ? (remainingPaise / daysLeft / 100).toStringAsFixed(0) : '0';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Selector Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(currentMonthStr, style: AppTypography.titleMedium(primaryTextColor)),
                      ],
                    ),
                    Text('$daysLeft days remaining', style: AppTypography.bodySmall(secondaryTextColor)),
                  ],
                ),
                const SizedBox(height: 16),

                // Overall Budget Hero Card (With Exceeded Warning space)
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'TOTAL MONTHLY SPENDING SPACE',
                              style: AppTypography.labelSmall(secondaryTextColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            label: '$percentUsed% Used',
                            color: isExceeded ? AppColors.coral : AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          CurrencyText(amountPaise: spentPaise, fontSize: 26, fontWeight: FontWeight.w700),
                          Text('of ₹${(capPaise / 100).toStringAsFixed(0)} limit', style: AppTypography.bodyMedium(secondaryTextColor)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (isExceeded) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.coral.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.coral.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.coral, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'WARNING: You have exceeded your monthly limit by ₹${(remainingPaise.abs() / 100).toStringAsFixed(0)}!',
                                  style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 10,
                          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation<Color>(isExceeded ? AppColors.coral : AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _statSummary(
                              'Remaining',
                              remainingPaise >= 0 ? '₹${(remainingPaise / 100).toStringAsFixed(0)}' : '-₹${(remainingPaise.abs() / 100).toStringAsFixed(0)}',
                              remainingPaise >= 0 ? AppColors.primary : AppColors.coral,
                            ),
                          ),
                          Expanded(
                            child: _statSummary('Daily Safe Pace', '₹$dailySafePace / day', primaryTextColor),
                          ),
                          Expanded(
                            child: _statSummary('Target Cap', '₹${(capPaise / 100).toStringAsFixed(0)}', secondaryTextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Category Budgets Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('CATEGORY BUDGET BREAKDOWN', style: AppTypography.labelSmall(secondaryTextColor)),
                    TextButton(
                      onPressed: () => _showSetBudgetDialog(context),
                      child: Text('Edit Cap', style: AppTypography.labelSmall(AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _categoryBudgetCard(
                  category: 'Food & Dining',
                  spentPaise: (spentPaise * 0.35).toInt(),
                  limitPaise: (capPaise * 0.35).toInt(),
                  icon: Icons.restaurant_rounded,
                  color: AppColors.coral,
                  isDark: isDark,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _categoryBudgetCard(
                  category: 'Shopping & Apparel',
                  spentPaise: (spentPaise * 0.25).toInt(),
                  limitPaise: (capPaise * 0.25).toInt(),
                  icon: Icons.shopping_bag_outlined,
                  color: AppColors.orange,
                  isAlert: isExceeded,
                  isDark: isDark,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _categoryBudgetCard(
                  category: 'Travel & Trips',
                  spentPaise: (spentPaise * 0.25).toInt(),
                  limitPaise: (capPaise * 0.25).toInt(),
                  icon: Icons.flight_takeoff_rounded,
                  color: AppColors.blue,
                  isDark: isDark,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                _categoryBudgetCard(
                  category: 'Groceries & Household',
                  spentPaise: (spentPaise * 0.15).toInt(),
                  limitPaise: (capPaise * 0.15).toInt(),
                  icon: Icons.shopping_basket_rounded,
                  color: AppColors.primary,
                  isDark: isDark,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                const SizedBox(height: 28),

                AppButton(
                  text: 'Adjust Monthly Spending Budget',
                  variant: ButtonVariant.outline,
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  onPressed: () => _showSetBudgetDialog(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statSummary(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _categoryBudgetCard({
    required String category,
    required int spentPaise,
    required int limitPaise,
    required IconData icon,
    required Color color,
    bool isAlert = false,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final progress = limitPaise > 0 ? (spentPaise / limitPaise).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).round();

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(category, style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15)),
              ),
              Text('$percentage%', style: TextStyle(fontWeight: FontWeight.w700, color: isAlert ? AppColors.coral : primaryTextColor)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(isAlert ? AppColors.coral : color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CurrencyText(
                  amountPaise: spentPaise,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'limit ₹${(limitPaise / 100).toStringAsFixed(0)}',
                style: AppTypography.bodySmall(secondaryTextColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
