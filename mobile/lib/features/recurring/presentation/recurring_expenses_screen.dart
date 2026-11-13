import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/widgets/app_button.dart';

class RecurringExpensesScreen extends StatelessWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Subscriptions'),
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
            // Monthly Commitments Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withOpacity(0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL MONTHLY SUBSCRIPTIONS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '₹4,047.00 / mo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '4 active recurring subscriptions tracked',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('ACTIVE SUBSCRIPTIONS', style: AppTypography.labelSmall(secondaryTextColor)),
            const SizedBox(height: 10),

            _recurringCard(
              title: 'Netflix 4K Ultra',
              category: 'Entertainment',
              amountPaise: 64900,
              renewalText: 'Renews in 7 days · 20 Nov',
              icon: Icons.movie_outlined,
              color: const Color(0xFFE50914),
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _recurringCard(
              title: 'Spotify Premium Duo',
              category: 'Music & Audio',
              amountPaise: 14900,
              renewalText: 'Renews in 9 days · 22 Nov',
              icon: Icons.music_note_rounded,
              color: const Color(0xFF1DB954),
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _recurringCard(
              title: 'Apple iCloud+ 2TB',
              category: 'Cloud Storage',
              amountPaise: 74900,
              renewalText: 'Renews in 15 days · 28 Nov',
              icon: Icons.cloud_outlined,
              color: AppColors.blue,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _recurringCard(
              title: 'Anytime Fitness Gym',
              category: 'Health & Wellness',
              amountPaise: 250000,
              renewalText: 'Renews in 18 days · 01 Dec',
              icon: Icons.fitness_center_rounded,
              color: AppColors.orange,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 24),

            AppButton(
              text: 'Add Recurring Subscription',
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

  Widget _recurringCard({
    required String title,
    required String category,
    required int amountPaise,
    required String renewalText,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
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
                Text(renewalText, style: AppTypography.bodySmall(secondaryTextColor)),
              ],
            ),
          ),
          CurrencyText(amountPaise: amountPaise, fontSize: 15, fontWeight: FontWeight.w700),
        ],
      ),
    );
  }
}
