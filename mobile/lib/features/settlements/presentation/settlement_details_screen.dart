import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';

class SettlementDetailsScreen extends StatefulWidget {
  final String settlementId;
  const SettlementDetailsScreen({super.key, required this.settlementId});

  @override
  State<SettlementDetailsScreen> createState() => _SettlementDetailsScreenState();
}

class _SettlementDetailsScreenState extends State<SettlementDetailsScreen> {
  bool _isSettled = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlement Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Payer to Receiver Avatar Row
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.coralLight,
                  child: Text('RM', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700)),
                ),
                SizedBox(width: 14),
                Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 24),
                SizedBox(width: 14),
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryLight,
                  child: Text('KV', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Rohan Mehra pays Kunal Verma',
              style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const CurrencyText(
              amountPaise: 48000,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 10),
            StatusBadge(
              label: _isSettled ? 'Settled & Verified' : 'Pending Payment',
              color: _isSettled ? AppColors.primary : AppColors.orange,
              icon: _isSettled ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
            ),
            const SizedBox(height: 28),

            // UPI QR & Payment Info Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: const Center(
                      child: Icon(Icons.qr_code_2_rounded, size: 100, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Kunal Verma UPI ID', style: AppTypography.bodySmall(secondaryTextColor)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('kunal@okhdfcbank', style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15)),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            AppButton(
              text: 'Pay via Google Pay / PhonePe',
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              onPressed: () {},
            ),
            const SizedBox(height: 12),

            AppButton(
              text: _isSettled ? 'Payment Completed' : 'Mark as Received & Settled',
              variant: ButtonVariant.outline,
              onPressed: () {
                setState(() => _isSettled = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settlement marked as completed and verified!')),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
