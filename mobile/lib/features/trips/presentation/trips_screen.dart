import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  int _selectedFilter = 0; // 0: Active, 1: Past

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Trips'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateTripDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Filter
            Row(
              children: [
                _filterPill('Active Trips (2)', 0, isDark, primaryTextColor, secondaryTextColor),
                const SizedBox(width: 10),
                _filterPill('Past Trips (4)', 1, isDark, primaryTextColor, secondaryTextColor),
              ],
            ),
            const SizedBox(height: 20),

            // Active Trip Cards
            _tripCard(
              id: 'trip-manali-101',
              title: 'Manali Snow Expedition',
              location: 'Manali, Himachal Pradesh',
              dates: '18 Nov - 24 Nov 2026',
              membersCount: 4,
              totalSpentPaise: 4820000,
              userBalancePaise: 96000, // +₹960
              color: AppColors.blue,
              icon: Icons.snowboarding_rounded,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 16),
            _tripCard(
              id: 'trip-goa-102',
              title: 'Goa Coastal Getaway',
              location: 'South Goa & Palolem',
              dates: '28 Dec - 02 Jan 2027',
              membersCount: 6,
              totalSpentPaise: 12800000,
              userBalancePaise: -48000, // -₹480
              color: AppColors.orange,
              icon: Icons.beach_access_rounded,
              isDark: isDark,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _filterPill(String title, int index, bool isDark, Color primaryColor, Color secondaryColor) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : secondaryColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _tripCard({
    required String id,
    required String title,
    required String location,
    required String dates,
    required int membersCount,
    required int totalSpentPaise,
    required int userBalancePaise,
    required Color color,
    required IconData icon,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final isOwed = userBalancePaise > 0;
    final balanceText = isOwed
        ? 'You get ₹${(userBalancePaise / 100).toStringAsFixed(0)}'
        : 'You owe ₹${(userBalancePaise.abs() / 100).toStringAsFixed(0)}';

    return AppCard(
      onTap: () => context.push('/trips/$id'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(location, style: AppTypography.bodySmall(secondaryTextColor)),
                  ],
                ),
              ),
              StatusBadge(
                label: balanceText,
                color: isOwed ? AppColors.primary : AppColors.coral,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 6),
                  Text(dates, style: AppTypography.bodySmall(secondaryTextColor)),
                ],
              ),
              Text(
                '$membersCount members · ₹${(totalSpentPaise / 100).toStringAsFixed(0)} spent',
                style: AppTypography.labelSmall(primaryTextColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateTripDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create New Group Trip', style: AppTypography.titleLarge(AppColors.textPrimaryLight)),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Trip Title (e.g. Ladakh Bike Tour)'),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: 'Destination (e.g. Leh, Ladakh)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Create Trip', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
