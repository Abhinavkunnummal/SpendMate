import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/delete_confirmation_dialog.dart';
import '../../../core/data/app_data_repository.dart';
import 'package:intl/intl.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final String transactionId;
  const TransactionDetailsScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return ListenableBuilder(
      listenable: AppDataRepository.instance,
      builder: (context, _) {
        final tx = AppDataRepository.instance.transactions.cast<TransactionModel?>().firstWhere(
          (t) => t?.id == transactionId,
          orElse: () => null,
        );

        if (tx == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Transaction Details')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textSecondaryLight),
                  const SizedBox(height: 12),
                  const Text('Transaction not found or deleted'),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
                ],
              ),
            ),
          );
        }

        final dateFormat = DateFormat('dd MMM yyyy, h:mm a');

        return Scaffold(
          appBar: AppBar(
            title: const Text('Transaction Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 22),
                tooltip: 'Delete Transaction',
                onPressed: () async {
                  final confirmed = await DeleteConfirmationDialog.show(
                    context,
                    title: 'Delete Transaction?',
                    message: 'Really want to delete "${tx.title}" (₹${(tx.amountPaise / 100).toStringAsFixed(2)})? This will restore the account balance.',
                  );

                  if (confirmed) {
                    await AppDataRepository.instance.deleteTransaction(tx.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Transaction "${tx.title}" deleted successfully!'),
                          backgroundColor: AppColors.coral,
                        ),
                      );
                      context.pop();
                    }
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Category Icon Badge
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: tx.isExpense ? AppColors.coral.withOpacity(0.12) : AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tx.icon,
                    size: 32,
                    color: tx.isExpense ? AppColors.coral : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // Title & Amount
                Text(
                  tx.title,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge(primaryTextColor),
                ),
                const SizedBox(height: 8),
                CurrencyText(
                  amountPaise: tx.amountPaise,
                  isExpense: tx.isExpense,
                  isIncome: !tx.isExpense,
                  showSign: true,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 12),
                StatusBadge(
                  label: tx.isExpense ? 'Expenditure Cleared' : 'Income Credited',
                  color: tx.isExpense ? AppColors.coral : AppColors.primary,
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(height: 28),

                // Details Breakdown Card
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _detailRow('Transaction Type', tx.isExpense ? 'Expense (Debit)' : 'Income (Credit)', primaryTextColor, secondaryTextColor),
                      const Divider(height: 24),
                      _detailRow('Category', tx.category, primaryTextColor, secondaryTextColor),
                      const Divider(height: 24),
                      _detailRow('Account / Wallet', tx.wallet, primaryTextColor, secondaryTextColor),
                      const Divider(height: 24),
                      _detailRow('Date & Time', dateFormat.format(tx.date), primaryTextColor, secondaryTextColor),
                      const Divider(height: 24),
                      _detailRow('Status', 'Verified & Recorded', primaryTextColor, secondaryTextColor),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Delete Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await DeleteConfirmationDialog.show(
                        context,
                        title: 'Delete Transaction?',
                        message: 'Really want to delete "${tx.title}" (₹${(tx.amountPaise / 100).toStringAsFixed(2)})?',
                      );

                      if (confirmed) {
                        await AppDataRepository.instance.deleteTransaction(tx.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Transaction "${tx.title}" deleted!'),
                              backgroundColor: AppColors.coral,
                            ),
                          );
                          context.pop();
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 20),
                    label: const Text('Delete Transaction', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.coral),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, Color primaryColor, Color secondaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall(secondaryColor)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium(primaryColor).copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
