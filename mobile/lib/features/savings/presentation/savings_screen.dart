import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
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
            // Total Savings Overview Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4388FF), Color(0xFF2B6CE0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withOpacity(0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL ACCUMULATED SAVINGS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '₹5,05,000.00',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '67% of total ₹7,50,000 target achieved',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Goals List
            Text('ACTIVE GOALS', style: AppTypography.labelSmall(secondaryTextColor)),
            const SizedBox(height: 10),

            _goalCard(
              title: 'Japan Autumn Trip 2027',
              currentPaise: 11000000,
              targetPaise: 25000000,
              targetDate: 'Oct 2027',
              icon: Icons.flight_takeoff_rounded,
              color: AppColors.blue,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _goalCard(
              title: 'Emergency Safety Reserve',
              currentPaise: 21500000,
              targetPaise: 30000000,
              targetDate: 'Ongoing',
              icon: Icons.shield_rounded,
              color: AppColors.primary,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _goalCard(
              title: 'MacBook Pro M3 Max',
              currentPaise: 18000000,
              targetPaise: 20000000,
              targetDate: 'Dec 2026',
              icon: Icons.laptop_mac_rounded,
              color: AppColors.purple,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 24),

            AppButton(
              text: 'Create New Savings Goal',
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

  Widget _goalCard({
    required String title,
    required int currentPaise,
    required int targetPaise,
    required String targetDate,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final progress = (currentPaise / targetPaise).clamp(0.0, 1.0);
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
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('Target: $targetDate', style: AppTypography.bodySmall(secondaryTextColor)),
                  ],
                ),
              ),
              StatusBadge(label: '$percentage%', color: color),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CurrencyText(amountPaise: currentPaise, fontSize: 14, fontWeight: FontWeight.w600),
              Text('Goal: ₹${(targetPaise / 100).toStringAsFixed(0)}', style: AppTypography.bodySmall(secondaryTextColor)),
            ],
          ),
        ],
      ),
    );
  }
}
