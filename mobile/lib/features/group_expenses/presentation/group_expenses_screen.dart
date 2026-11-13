import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/widgets/app_button.dart';

class GroupExpensesScreen extends StatelessWidget {
  final String tripId;
  const GroupExpensesScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/trips/$tripId/add-expense'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Overview Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL GROUP EXPENDITURE',
                          style: AppTypography.labelSmall(secondaryTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const CurrencyText(amountPaise: 4820000, fontSize: 22, fontWeight: FontWeight.w700),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => context.push('/trips/$tripId/balances'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Balances', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('ALL SHARED EXPENSES (5)', style: AppTypography.labelSmall(secondaryTextColor)),
            const SizedBox(height: 10),

            // Expense 1: The Multi-Payer example from Prompt!
            _groupExpenseCard(
              title: 'Sightseeing & Shuttle Tickets',
              amountPaise: 56000, // ₹560.00
              paidByText: 'Aarav paid ₹400 · Rohan paid ₹160',
              splitSummary: 'Split equally · ₹140 / person (4 people)',
              categoryIcon: Icons.confirmation_number_outlined,
              categoryColor: AppColors.blue,
              date: 'Today, 11:30 AM',
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              onTap: () => context.push('/trips/$tripId/split-expense'),
            ),

            // Expense 2
            _groupExpenseCard(
              title: 'Riverside Pine Cottage Booking',
              amountPaise: 1200000, // ₹12,000.00
              paidByText: '${AuthSessionManager.instance.displayName} paid ₹12,000',
              splitSummary: 'Split equally · ₹3,000 / person (4 people)',
              categoryIcon: Icons.hotel_rounded,
              categoryColor: AppColors.coral,
              date: 'Yesterday, 02:00 PM',
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              onTap: () {},
            ),

            // Expense 3
            _groupExpenseCard(
              title: 'Café 1947 Riverside Dinner',
              amountPaise: 320000, // ₹3,200.00
              paidByText: 'Rohan Mehra paid ₹3,200',
              splitSummary: 'Split equally · ₹800 / person (4 people)',
              categoryIcon: Icons.restaurant_rounded,
              categoryColor: AppColors.orange,
              date: '12 Nov, 09:15 PM',
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              onTap: () {},
            ),

            // Expense 4
            _groupExpenseCard(
              title: 'Snow Tubing & Gear Rental',
              amountPaise: 480000, // ₹4,800.00
              paidByText: 'Pooja Nair paid ₹4,800',
              splitSummary: 'Split equally · ₹1,200 / person (4 people)',
              categoryIcon: Icons.downhill_skiing_rounded,
              categoryColor: AppColors.purple,
              date: '11 Nov, 03:30 PM',
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              onTap: () {},
            ),
            const SizedBox(height: 24),

            AppButton(
              text: '+ Add New Group Expense',
              onPressed: () => context.push('/trips/$tripId/add-expense'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _groupExpenseCard({
    required String title,
    required int amountPaise,
    required String paidByText,
    required String splitSummary,
    required IconData categoryIcon,
    required Color categoryColor,
    required String date,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(date, style: AppTypography.bodySmall(secondaryTextColor)),
                  ],
                ),
              ),
              CurrencyText(amountPaise: amountPaise, fontSize: 16, fontWeight: FontWeight.w700),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payment_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        paidByText,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryTextColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  splitSummary,
                  style: TextStyle(fontSize: 11, color: secondaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
