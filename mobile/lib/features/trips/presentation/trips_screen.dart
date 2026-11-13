import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../core/data/app_data_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
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
      body: ListenableBuilder(
        listenable: AppDataRepository.instance,
        builder: (context, _) {
          final allTrips = AppDataRepository.instance.trips;
          final now = DateTime.now();

          final activeTrips = allTrips.where((t) => t.endDate.isAfter(now.subtract(const Duration(days: 1)))).toList();
          final pastTrips = allTrips.where((t) => t.endDate.isBefore(now.subtract(const Duration(days: 1)))).toList();

          final displayedTrips = _selectedFilter == 0 ? activeTrips : pastTrips;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Segmented Filter
                Row(
                  children: [
                    _filterPill('Active Trips (${activeTrips.length})', 0, isDark, primaryTextColor, secondaryTextColor),
                    const SizedBox(width: 10),
                    _filterPill('Past Trips (${pastTrips.length})', 1, isDark, primaryTextColor, secondaryTextColor),
                  ],
                ),
                const SizedBox(height: 20),

                if (displayedTrips.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flight_takeoff_rounded, color: AppColors.primary, size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 0 ? 'No Active Trips' : 'No Past Trips',
                          style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Plan group adventures, add co-travelers, and easily split shared expenses.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall(secondaryTextColor),
                        ),
                        const SizedBox(height: 20),
                        AppButton(
                          text: '+ Plan New Trip',
                          onPressed: () => _showCreateTripDialog(context),
                        ),
                      ],
                    ),
                  )
                else
                  ...displayedTrips.map((trip) {
                    final dateFormat = DateFormat('dd MMM');
                    final dateRangeStr = '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)} ${trip.endDate.year}';
                    final isUserOwed = trip.spentPaise > 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _tripCard(
                        id: trip.id,
                        title: trip.name,
                        location: trip.destination,
                        dates: dateRangeStr,
                        membersCount: trip.members.isNotEmpty ? trip.members.length : 1,
                        totalSpentPaise: trip.spentPaise,
                        userBalancePaise: isUserOwed ? 0 : 0,
                        color: AppColors.primary,
                        icon: Icons.beach_access_rounded,
                        isDark: isDark,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                    );
                  }),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
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
    final isOwed = userBalancePaise >= 0;
    final balanceText = userBalancePaise == 0
        ? 'Active Group'
        : (isOwed
            ? 'You get ₹${(userBalancePaise / 100).toStringAsFixed(0)}'
            : 'You owe ₹${(userBalancePaise.abs() / 100).toStringAsFixed(0)}');

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
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(secondaryTextColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: balanceText,
                color: userBalancePaise == 0
                    ? AppColors.primary
                    : (isOwed ? AppColors.primary : AppColors.coral),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondaryLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        dates,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall(secondaryTextColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
    final titleController = TextEditingController();
    final destController = TextEditingController();
    final budgetController = TextEditingController(text: '30000');

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
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Trip Title (e.g. Goa Beach Trip)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: destController,
              decoration: const InputDecoration(labelText: 'Destination (e.g. North Goa)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Estimated Budget (₹)', prefixText: '₹ '),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;
                  final dest = destController.text.trim();
                  final budgetNum = int.tryParse(budgetController.text.trim()) ?? 30000;

                  final currentUserName = AuthSessionManager.instance.displayName;

                  await AppDataRepository.instance.addTrip(
                    name: title,
                    destination: dest.isNotEmpty ? dest : 'India',
                    budgetPaise: budgetNum * 100,
                    startDate: DateTime.now(),
                    endDate: DateTime.now().add(const Duration(days: 4)),
                    members: [currentUserName],
                  );

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Trip "$title" created successfully!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Create Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
