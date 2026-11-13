import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets & Targets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                    Text('November 2026', style: AppTypography.titleMedium(primaryTextColor)),
                  ],
                ),
                Text('18 days remaining', style: AppTypography.bodySmall(secondaryTextColor)),
              ],
            ),
            const SizedBox(height: 16),

            // Overall Budget Hero Card
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
                          'TOTAL MONTHLY SPENDING',
                          style: AppTypography.labelSmall(secondaryTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const StatusBadge(label: '68% Used', color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      const CurrencyText(amountPaise: 3400000, fontSize: 26, fontWeight: FontWeight.w700),
                      Text('of ₹50,000 target', style: AppTypography.bodyMedium(secondaryTextColor)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.68,
                      minHeight: 10,
                      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _statSummary('Remaining', '₹16,000', AppColors.primary)),
                      Expanded(child: _statSummary('Daily Safe Spend', '₹888 / day', primaryTextColor)),
                      Expanded(child: _statSummary('Projected', '₹48,200', secondaryTextColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Category Budgets Header
            Text('CATEGORY BUDGETS', style: AppTypography.labelSmall(secondaryTextColor)),
            const SizedBox(height: 10),

            _categoryBudgetCard(
              category: 'Food & Dining',
              spentPaise: 1120000,
              limitPaise: 1500000,
              icon: Icons.restaurant_rounded,
              color: AppColors.coral,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _categoryBudgetCard(
              category: 'Shopping & Apparel',
              spentPaise: 650000,
              limitPaise: 800000,
              icon: Icons.shopping_bag_outlined,
              color: AppColors.orange,
              isAlert: true,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _categoryBudgetCard(
              category: 'Travel & Trips',
              spentPaise: 1240000,
              limitPaise: 2000000,
              icon: Icons.flight_takeoff_rounded,
              color: AppColors.blue,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _categoryBudgetCard(
              category: 'Groceries & Supplies',
              spentPaise: 390000,
              limitPaise: 700000,
              icon: Icons.shopping_basket_rounded,
              color: AppColors.primary,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 28),

            AppButton(
              text: 'Set New Category Budget',
              variant: ButtonVariant.outline,
              icon: const Icon(Icons.add_rounded, size: 20),
              onPressed: () {},
            ),
            const SizedBox(height: 24),
          ],
        ),
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
    final progress = (spentPaise / limitPaise).clamp(0.0, 1.0);
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
