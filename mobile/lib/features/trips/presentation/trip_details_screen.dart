import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../core/data/app_data_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';

class TripDetailsScreen extends StatelessWidget {
  final String tripId;
  const TripDetailsScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return ListenableBuilder(
      listenable: AppDataRepository.instance,
      builder: (context, _) {
        final tripList = AppDataRepository.instance.trips;
        final trip = tripList.cast<TripModelItem?>().firstWhere(
          (t) => t?.id == tripId,
          orElse: () => null,
        );

        final tripTitle = trip?.name ?? 'Manali Snow Expedition';
        final tripDest = trip?.destination ?? 'Manali, Himachal Pradesh';
        final totalSpentPaise = trip?.spentPaise ?? 4820000;
        final budgetPaise = trip?.budgetPaise ?? 8000000;
        final dateRangeStr = trip != null
            ? '${DateFormat('dd MMM').format(trip.startDate)} - ${DateFormat('dd MMM').format(trip.endDate)}'
            : '18 Nov - 24 Nov';
        final currentUser = AuthSessionManager.instance.displayName;
        final currentUserInitials = AuthSessionManager.instance.userInitials;

        return Scaffold(
          appBar: AppBar(
            title: Text(tripTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Trip Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4388FF), Color(0xFF1D5CC9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Active Trip',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            dateRangeStr,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tripTitle,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tripDest,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TOTAL SPENT', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10)),
                                const SizedBox(height: 2),
                                Text('₹${(totalSpentPaise / 100).toStringAsFixed(0)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('BUDGET', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10)),
                                const SizedBox(height: 2),
                                Text('₹${(budgetPaise / 100).toStringAsFixed(0)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('YOUR BALANCE', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10)),
                                const SizedBox(height: 2),
                                const Text('Settled', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Navigation Feature Pills
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Group Expenses',
                        variant: ButtonVariant.secondary,
                        icon: const Icon(Icons.receipt_long_rounded, size: 16),
                        height: 44,
                        onPressed: () => context.push('/trips/$tripId/expenses'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        text: 'Balances',
                        variant: ButtonVariant.secondary,
                        icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                        height: 44,
                        onPressed: () => context.push('/trips/$tripId/balances'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        text: 'Itinerary',
                        variant: ButtonVariant.secondary,
                        icon: const Icon(Icons.map_outlined, size: 16),
                        height: 44,
                        onPressed: () => context.push('/trips/$tripId/itinerary'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Group Members Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Trip Members (${trip?.members.length ?? 4})', style: AppTypography.titleMedium(primaryTextColor)),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.person_add_outlined, size: 16, color: AppColors.primary),
                      label: Text('Invite', style: AppTypography.labelSmall(AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    children: [
                      _memberRow(currentUser, 'Organizer · You', currentUserInitials, AppColors.primary, true, primaryTextColor, secondaryTextColor),
                      const Divider(),
                      _memberRow('Aarav Sharma', 'Member · Active', 'AS', AppColors.blue, false, primaryTextColor, secondaryTextColor),
                      const Divider(),
                      _memberRow('Rohan Mehra', 'Member · Active', 'RM', AppColors.coral, false, primaryTextColor, secondaryTextColor),
                      const Divider(),
                      _memberRow('Pooja Nair', 'Member · Active', 'PN', AppColors.orange, false, primaryTextColor, secondaryTextColor),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Add Expense Primary Button
                AppButton(
                  text: 'Add Group Expense',
                  icon: const Icon(Icons.add_rounded, size: 20),
                  onPressed: () => context.push('/trips/$tripId/add-expense'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _memberRow(
    String name,
    String subtitle,
    String initials,
    Color avatarColor,
    bool isAdmin,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: avatarColor.withOpacity(0.15),
            child: Text(
              initials,
              style: TextStyle(color: avatarColor, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14)),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      const StatusBadge(label: 'Admin', color: AppColors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySmall(secondaryTextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
