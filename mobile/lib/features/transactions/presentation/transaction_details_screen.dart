import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/delete_confirmation_dialog.dart';
import '../../../core/services/app_sound_service.dart';
import '../../../core/data/app_data_repository.dart';
import 'package:intl/intl.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final String transactionId;
  const TransactionDetailsScreen({super.key, required this.transactionId});

  void _showEditSheet(BuildContext context, TransactionModel tx) {
    final titleController = TextEditingController(text: tx.title);
    final amountController = TextEditingController(
      text: ((tx.amountPaise) / 100).toStringAsFixed(tx.amountPaise % 100 == 0 ? 0 : 2),
    );
    String selectedCategory = tx.category;
    String selectedWallet = tx.wallet;
    bool isExpense = tx.isExpense;

    final categories = [
      'Food & Dining',
      'Movies & Cinema',
      'Travel & Trips',
      'Groceries',
      'Shopping',
      'Bills & Utilities',
      'Transport & Fuel',
      'Gaming & Fun',
      'Health & Medical',
      'Education & Books',
      'Salary & Inflow',
      'Investments',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
          final repoWallets = AppDataRepository.instance.wallets;
          final walletNames = repoWallets.map((w) => w.name).toList();
          if (!walletNames.contains(selectedWallet) && walletNames.isNotEmpty) {
            selectedWallet = walletNames.first;
          }

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Edit Transaction', style: AppTypography.titleLarge(primaryTextColor).copyWith(fontSize: 18)),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title / Merchant', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ ', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: categories.contains(selectedCategory) ? selectedCategory : categories.first,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (walletNames.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selectedWallet,
                      decoration: const InputDecoration(labelText: 'Account / Wallet', border: OutlineInputBorder()),
                      items: walletNames.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedWallet = val);
                      },
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final amt = double.tryParse(amountController.text.trim()) ?? 0;
                        if (title.isEmpty || amt <= 0) return;

                        await AppDataRepository.instance.updateTransaction(
                          id: tx.id,
                          title: title,
                          amountPaise: (amt * 100).toInt(),
                          isExpense: isExpense,
                          category: selectedCategory,
                          wallet: selectedWallet,
                        );

                        AppSoundService.playIncomeChime();

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaction updated successfully!')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

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
                icon: const Icon(Icons.edit_outlined, size: 22),
                tooltip: 'Edit Transaction',
                onPressed: () => _showEditSheet(context, tx),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 22),
                tooltip: 'Delete Transaction',
                onPressed: () async {
                  final confirmed = await DeleteConfirmationDialog.show(
                    context,
                    title: 'Delete Transaction?',
                    message: 'Really want to delete "${tx.title}" (₹${(tx.amountPaise / 100).toStringAsFixed(2)})? This will restore the wallet balance.',
                  );

                  if (confirmed) {
                    await AppDataRepository.instance.deleteTransaction(tx.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Transaction "${tx.title}" deleted! Balance restored.'),
                          backgroundColor: AppColors.coral,
                          behavior: SnackBarBehavior.floating,
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
              children: [
                // Amount Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: tx.isExpense
                              ? AppColors.coral.withOpacity(0.12)
                              : AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          tx.icon,
                          size: 36,
                          color: tx.isExpense ? AppColors.coral : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${tx.isExpense ? '-' : '+'}₹${(tx.amountPaise / 100).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: tx.isExpense ? AppColors.coral : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tx.title,
                        style: AppTypography.titleLarge(primaryTextColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      StatusBadge(
                        label: tx.isExpense ? 'Expense / Outflow' : 'Income / Inflow',
                        color: tx.isExpense ? AppColors.coral : AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Details Card
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _detailRow('Category', tx.category, isDark, primaryTextColor, secondaryTextColor),
                      const Divider(height: 24),
                      _detailRow('Payment Account', tx.wallet, isDark, primaryTextColor, secondaryTextColor),
                      const Divider(height: 24),
                      _detailRow('Date & Time', dateFormat.format(tx.date), isDark, primaryTextColor, secondaryTextColor),
                      const Divider(height: 24),
                      _detailRow('Transaction ID', tx.id, isDark, primaryTextColor, secondaryTextColor),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Transaction'),
                        onPressed: () => _showEditSheet(context, tx),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, bool isDark, Color primaryColor, Color secondaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall(secondaryColor)),
        Flexible(
          child: Text(
            value,
            style: AppTypography.titleMedium(primaryColor).copyWith(fontSize: 14),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
