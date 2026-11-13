import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class AddGroupExpenseScreen extends StatefulWidget {
  final String tripId;
  const AddGroupExpenseScreen({super.key, required this.tripId});

  @override
  State<AddGroupExpenseScreen> createState() => _AddGroupExpenseScreenState();
}

class _AddGroupExpenseScreenState extends State<AddGroupExpenseScreen> {
  final _amountController = TextEditingController(text: '560');
  final _descriptionController = TextEditingController(text: 'Sightseeing Shuttle Tickets');

  // Multi-Payer State
  bool _isMultiPayer = true;
  final Map<String, TextEditingController> _payerControllers = {
    'Aarav Sharma': TextEditingController(text: '400'),
    'Kunal Verma': TextEditingController(text: '0'),
    'Rohan Mehra': TextEditingController(text: '160'),
    'Pooja Nair': TextEditingController(text: '0'),
  };

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    for (var c in _payerControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _calculatePaidSum() {
    int sum = 0;
    for (var c in _payerControllers.values) {
      final val = int.tryParse(c.text.trim()) ?? 0;
      sum += val;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final targetAmount = int.tryParse(_amountController.text.trim()) ?? 0;
    final currentPaidSum = _calculatePaidSum();
    final isMatching = currentPaidSum == targetAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Group Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Hero Input
            Center(
              child: Column(
                children: [
                  Text('Total Expense Amount', style: AppTypography.bodySmall(secondaryTextColor)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '₹',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700, color: primaryTextColor),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            filled: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description Field
            AppTextField(
              label: 'Expense Description',
              hint: 'e.g. Dinner, Bus Tickets, Cottage Rental',
              controller: _descriptionController,
              prefixIcon: const Icon(Icons.receipt_outlined, size: 20),
            ),
            const SizedBox(height: 24),

            // Who Paid? (Multi-Payer support)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('WHO PAID FOR THIS?', style: AppTypography.labelSmall(secondaryTextColor)),
                Row(
                  children: [
                    Text('Multiple Payers', style: AppTypography.bodySmall(primaryTextColor)),
                    Switch.adaptive(
                      value: _isMultiPayer,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _isMultiPayer = val),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Payers List
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: _payerControllers.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            entry.key.substring(0, 1),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(entry.key, style: AppTypography.bodyMedium(primaryTextColor)),
                        ),
                        SizedBox(
                          width: 100,
                          height: 40,
                          child: TextField(
                            controller: entry.value,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            onChanged: (_) => setState(() {}),
                            style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Validation Status Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isMatching ? AppColors.primaryLight : AppColors.coralLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isMatching ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    size: 16,
                    color: isMatching ? AppColors.primary : AppColors.coral,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isMatching
                        ? 'Total contributions match ₹$targetAmount'
                        : 'Paid sum ₹$currentPaidSum of ₹$targetAmount (Difference: ₹${targetAmount - currentPaidSum})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isMatching ? AppColors.primary : AppColors.coral,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Continue to Split Configuration
            AppButton(
              text: 'Configure Split & Participants →',
              onPressed: () {
                context.push('/trips/${widget.tripId}/split-expense');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
