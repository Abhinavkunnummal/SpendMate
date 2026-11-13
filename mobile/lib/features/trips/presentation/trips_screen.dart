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
import '../../../core/widgets/delete_confirmation_dialog.dart';
import '../../../core/services/app_sound_service.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  int _selectedFilter = 0; // 0: Active, 1: Past

  void _confirmDeleteTrip(BuildContext context, TripModelItem trip) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      title: 'Delete Trip "${trip.name}"?',
      message: 'Really want to delete this group trip? All associated group expenses and balances will be removed.',
    );

    if (confirmed) {
      await AppDataRepository.instance.deleteTrip(trip.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip "${trip.name}" deleted successfully!'),
            backgroundColor: AppColors.coral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Trips & Travel'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Create New Trip',
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
                          decoration: const BoxDecoration(
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
                          'Plan group adventures, add your friends, and track everyone\'s spendings and settlements.',
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

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _tripCard(
                        trip: trip,
                        dates: dateRangeStr,
                        isDark: isDark,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        onDelete: () => _confirmDeleteTrip(context, trip),
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
      onTap: () {
        AppSoundService.playSuccess();
        setState(() => _selectedFilter = index);
      },
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
    required TripModelItem trip,
    required String dates,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required VoidCallback onDelete,
  }) {
    final remainingBudget = trip.budgetPaise - trip.spentPaise;
    return AppCard(
      onTap: () => context.push('/trips/${trip.id}'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.beach_access_rounded, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trip.destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(secondaryTextColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
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
                '${trip.members.length} friends · ₹${(trip.spentPaise / 100).toStringAsFixed(0)} spent',
                style: AppTypography.labelSmall(primaryTextColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget: ₹${(trip.budgetPaise / 100).toStringAsFixed(0)}',
                style: AppTypography.bodySmall(secondaryTextColor),
              ),
              Text(
                remainingBudget >= 0
                    ? '₹${(remainingBudget / 100).toStringAsFixed(0)} left'
                    : '₹${(remainingBudget.abs() / 100).toStringAsFixed(0)} over budget',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: remainingBudget >= 0 ? AppColors.primary : AppColors.coral,
                ),
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
    final budgetController = TextEditingController(text: '35000');
    final friendsController = TextEditingController(text: 'Aarav, Rohan, Pooja');

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create New Group Trip', style: AppTypography.titleLarge(AppColors.textPrimaryLight)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Trip Title (e.g. Goa Beach Trip)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destController,
                decoration: const InputDecoration(labelText: 'Destination (e.g. South Goa)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Trip Estimated Budget (₹)', prefixText: '₹ ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: friendsController,
                decoration: const InputDecoration(
                  labelText: 'Add Friends (comma separated)',
                  hintText: 'e.g. Aarav, Rohan, Pooja, Vikram',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group_add_outlined),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;
                    final dest = destController.text.trim();
                    final budgetNum = int.tryParse(budgetController.text.trim()) ?? 35000;

                    final currentUserName = AuthSessionManager.instance.displayName;

                    final friendsInput = friendsController.text.trim();
                    final parsedFriends = friendsInput
                        .split(',')
                        .map((f) => f.trim())
                        .where((f) => f.isNotEmpty)
                        .toList();

                    final allMembers = [currentUserName, ...parsedFriends];

                    await AppDataRepository.instance.addTrip(
                      name: title,
                      destination: dest.isNotEmpty ? dest : 'India',
                      budgetPaise: budgetNum * 100,
                      startDate: DateTime.now(),
                      endDate: DateTime.now().add(const Duration(days: 4)),
                      members: allMembers,
                    );

                    AppSoundService.playIncomeChime();

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Trip "$title" with ${allMembers.length} friends created!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Create Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
