import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/delete_confirmation_dialog.dart';

class GroupExpensesScreen extends StatefulWidget {
  final String tripId;
  const GroupExpensesScreen({super.key, required this.tripId});

  @override
  State<GroupExpensesScreen> createState() => _GroupExpensesScreenState();
}

class _GroupExpensesScreenState extends State<GroupExpensesScreen> {
  final List<Map<String, dynamic>> _mockExpenses = [
    {
      'id': 'exp-1',
      'title': 'Sightseeing & Shuttle Tickets',
      'amountPaise': 56000,
      'paidByText': 'Aarav paid ₹400 · Rohan paid ₹160',
      'splitSummary': 'Split equally · ₹140 / person (4 people)',
      'categoryIcon': Icons.confirmation_number_outlined,
      'categoryColor': AppColors.blue,
      'date': 'Today, 11:30 AM',
    },
    {
      'id': 'exp-2',
      'title': 'Riverside Pine Cottage Booking',
      'amountPaise': 1200000,
      'paidByText': 'You paid ₹12,000',
      'splitSummary': 'Split equally · ₹3,000 / person (4 people)',
      'categoryIcon': Icons.hotel_rounded,
      'categoryColor': AppColors.coral,
      'date': 'Yesterday, 02:00 PM',
    },
    {
      'id': 'exp-3',
      'title': 'Café 1947 Riverside Dinner',
      'amountPaise': 320000,
      'paidByText': 'Rohan Mehra paid ₹3,200',
      'splitSummary': 'Split equally · ₹800 / person (4 people)',
      'categoryIcon': Icons.restaurant_rounded,
      'categoryColor': AppColors.orange,
      'date': '12 Nov, 09:15 PM',
    },
    {
      'id': 'exp-4',
      'title': 'Snow Tubing & Gear Rental',
      'amountPaise': 480000,
      'paidByText': 'Pooja Nair paid ₹4,800',
      'splitSummary': 'Split equally · ₹1,200 / person (4 people)',
      'categoryIcon': Icons.downhill_skiing_rounded,
      'categoryColor': AppColors.purple,
      'date': '11 Nov, 03:30 PM',
    },
  ];

  void _deleteExpense(Map<String, dynamic> exp) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      title: 'Delete Group Expense?',
      message: 'Really want to delete "${exp['title']}"? Group balances will be updated accordingly.',
    );

    if (confirmed) {
      setState(() {
        _mockExpenses.removeWhere((e) => e['id'] == exp['id']);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense "${exp['title']}" deleted successfully!'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final myName = AuthSessionManager.instance.displayName;
    final totalSpentPaise = _mockExpenses.fold<int>(0, (sum, e) => sum + (e['amountPaise'] as int));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/trips/${widget.tripId}/add-expense'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expenditure Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL GROUP EXPENDITURE', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  CurrencyText(amountPaise: totalSpentPaise, fontSize: 30, fontWeight: FontWeight.w700),
                  const SizedBox(height: 6),
                  Text('Across ${_mockExpenses.length} shared activities and bills', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // All Shared Expenses List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ALL SHARED EXPENSES (${_mockExpenses.length})', style: AppTypography.labelSmall(secondaryTextColor)),
                TextButton.icon(
                  onPressed: () => context.push('/trips/${widget.tripId}/add-expense'),
                  icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                  label: Text('Add Expense', style: AppTypography.labelSmall(AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_mockExpenses.isEmpty)
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text('No group expenses recorded yet', style: AppTypography.bodySmall(secondaryTextColor)),
                ),
              )
            else
              ..._mockExpenses.map((exp) {
                String paidText = exp['paidByText'];
                if (paidText.contains('You paid')) {
                  paidText = '$myName paid ₹12,000';
                }

                return _groupExpenseCard(
                  title: exp['title'],
                  amountPaise: exp['amountPaise'],
                  paidByText: paidText,
                  splitSummary: exp['splitSummary'],
                  categoryIcon: exp['categoryIcon'],
                  categoryColor: exp['categoryColor'],
                  date: exp['date'],
                  isDark: isDark,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  onDelete: () => _deleteExpense(exp),
                  onTap: () => context.push('/trips/${widget.tripId}/split-expense'),
                );
              }),
            const SizedBox(height: 28),

            AppButton(
              text: '+ Add Shared Expense',
              onPressed: () => context.push('/trips/${widget.tripId}/add-expense'),
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
    required VoidCallback onDelete,
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
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 18),
                onPressed: onDelete,
              ),
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
