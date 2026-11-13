import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/app_button.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final String transactionId;
  const TransactionDetailsScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Transaction'),
                  content: const Text('Are you sure you want to delete this transaction?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.pop();
                      },
                      child: const Text('Delete', style: TextStyle(color: AppColors.coral)),
                    ),
                  ],
                ),
              );
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.coralLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant_rounded, size: 30, color: AppColors.coral),
            ),
            const SizedBox(height: 16),

            // Title & Amount
            Text(
              'Blue Tokai Coffee Roasters',
              style: AppTypography.titleLarge(primaryTextColor),
            ),
            const SizedBox(height: 8),
            const CurrencyText(
              amountPaise: 48000,
              isExpense: true,
              showSign: true,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 12),
            const StatusBadge(
              label: 'Completed',
              color: AppColors.primary,
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(height: 28),

            // Details Breakdown Card
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _detailRow('Category', 'Food & Dining', primaryTextColor, secondaryTextColor),
                  const Divider(height: 24),
                  _detailRow('Payment Method', 'HDFC Salary Account', primaryTextColor, secondaryTextColor),
                  const Divider(height: 24),
                  _detailRow('Date & Time', '13 Nov 2026, 10:30 AM', primaryTextColor, secondaryTextColor),
                  const Divider(height: 24),
                  _detailRow('Transaction Ref', '#TX-9482-101', primaryTextColor, secondaryTextColor),
                  const Divider(height: 24),
                  _detailRow('Notes', 'Specialty flat white with colleague', primaryTextColor, secondaryTextColor),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Receipt Attachment Card
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Receipt Attached', style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('blue_tokai_invoice.jpg · 1.2 MB', style: AppTypography.bodySmall(secondaryTextColor)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            AppButton(
              text: 'Edit Transaction',
              variant: ButtonVariant.outline,
              onPressed: () => context.push('/add-transaction'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color primaryColor, Color secondaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium(secondaryColor)),
        Text(value, style: AppTypography.titleMedium(primaryColor).copyWith(fontSize: 14)),
      ],
    );
  }
}
