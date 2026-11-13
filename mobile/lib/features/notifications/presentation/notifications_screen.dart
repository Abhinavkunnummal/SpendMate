import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all as read', style: TextStyle(color: AppColors.primary, fontSize: 13)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        children: [
          Text('TODAY', style: AppTypography.labelSmall(secondaryTextColor)),
          const SizedBox(height: 8),

          _notificationItem(
            icon: Icons.payments_rounded,
            iconColor: AppColors.primary,
            title: 'Settlement Payment Pending',
            message: 'Rohan owes you ₹480 for Sightseeing Shuttle Tickets in Manali.',
            time: '2 hours ago',
            isUnread: true,
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            onTap: () => context.push('/settlements/settle-101'),
          ),

          _notificationItem(
            icon: Icons.group_rounded,
            iconColor: AppColors.blue,
            title: 'Group Expense Added',
            message: 'Aarav recorded Sightseeing & Shuttle Tickets (₹560) in Manali Snow Expedition.',
            time: '4 hours ago',
            isUnread: true,
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            onTap: () => context.push('/trips/trip-manali-101/expenses'),
          ),

          const SizedBox(height: 16),
          Text('EARLIER THIS WEEK', style: AppTypography.labelSmall(secondaryTextColor)),
          const SizedBox(height: 8),

          _notificationItem(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.orange,
            title: 'Shopping Budget Alert',
            message: 'You have used 81% of your Shopping & Apparel budget for November.',
            time: '2 days ago',
            isUnread: false,
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            onTap: () => context.push('/budgets'),
          ),

          _notificationItem(
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.purple,
            title: 'Upcoming Subscription Renewal',
            message: 'Netflix 4K Ultra (₹649) is scheduled for automatic renewal in 3 days.',
            time: '3 days ago',
            isUnread: false,
            isDark: isDark,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            onTap: () => context.push('/recurring-expenses'),
          ),
        ],
      ),
    );
  }

  Widget _notificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14)),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(message, style: AppTypography.bodySmall(secondaryTextColor)),
                const SizedBox(height: 6),
                Text(time, style: TextStyle(fontSize: 11, color: secondaryTextColor.withOpacity(0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
