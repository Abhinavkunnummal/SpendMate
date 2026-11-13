import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  Text('NET MONTHLY SAVINGS', style: AppTypography.labelSmall(secondaryTextColor)),
                  const SizedBox(height: 6),
                  const Text(
                    '₹1,42,850.00',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text('77% Savings Rate · ₹42,150 total expenditures', style: AppTypography.bodySmall(secondaryTextColor)),
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
                              const Text('₹1,85,000', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
                              const Text('₹42,150', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.coral)),
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

            // AI Insight Callout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.purpleLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.purple.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.purple, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Spending Insight', style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          'Your food & dining spend dropped by 12% this month! You are on pace to save an extra ₹6,500.',
                          style: AppTypography.bodySmall(secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Spending by Category
            Text('SPENDING BY CATEGORY', style: AppTypography.labelSmall(secondaryTextColor)),
            const SizedBox(height: 12),

            _categoryRow('Food & Dining', 1450000, 34, AppColors.coral, isDark, primaryTextColor, secondaryTextColor),
            _categoryRow('Travel & Trips', 1250000, 30, AppColors.blue, isDark, primaryTextColor, secondaryTextColor),
            _categoryRow('Shopping', 820000, 19, AppColors.orange, isDark, primaryTextColor, secondaryTextColor),
            _categoryRow('Bills & Utilities', 695000, 17, AppColors.purple, isDark, primaryTextColor, secondaryTextColor),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _periodTab(String title, int index, bool isDark, Color primaryColor, Color secondaryColor) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? AppColors.cardDark : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? primaryColor : secondaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryRow(
    String category,
    int amountPaise,
    int percentage,
    Color color,
    bool isDark,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(category, style: AppTypography.titleMedium(primaryColor).copyWith(fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  CurrencyText(amountPaise: amountPaise, fontSize: 14, fontWeight: FontWeight.w600),
                  const SizedBox(width: 8),
                  Text('$percentage%', style: AppTypography.bodySmall(secondaryColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              minHeight: 5,
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
