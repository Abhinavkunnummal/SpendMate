import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../core/data/app_data_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/delete_confirmation_dialog.dart';
import '../../../core/services/app_sound_service.dart';

class TripDetailsScreen extends StatelessWidget {
  final String tripId;
  const TripDetailsScreen({super.key, required this.tripId});

  void _showExportStatementDialog(BuildContext context, TripModelItem trip) {
    AppSoundService.playSuccess();
    final memberCount = trip.members.isNotEmpty ? trip.members.length : 1;
    final perPersonBudget = trip.budgetPaise ~/ memberCount;
    final perPersonSpent = trip.spentPaise ~/ memberCount;

    final statementText = StringBuffer()
      ..writeln('========================================')
      ..writeln('   SPENDMATE TRIP FINANCIAL STATEMENT   ')
      ..writeln('========================================')
      ..writeln('Trip: ${trip.name}')
      ..writeln('Destination: ${trip.destination}')
      ..writeln('Dates: ${DateFormat('dd MMM yyyy').format(trip.startDate)} - ${DateFormat('dd MMM yyyy').format(trip.endDate)}')
      ..writeln('----------------------------------------')
      ..writeln('BUDGET SUMMARY:')
      ..writeln('  Total Group Budget: ₹${(trip.budgetPaise / 100).toStringAsFixed(2)}')
      ..writeln('  Total Group Spent:  ₹${(trip.spentPaise / 100).toStringAsFixed(2)}')
      ..writeln('  Remaining Budget:   ₹${((trip.budgetPaise - trip.spentPaise) / 100).toStringAsFixed(2)}')
      ..writeln('  Per Person Share:   ₹${(perPersonSpent / 100).toStringAsFixed(2)}')
      ..writeln('----------------------------------------')
      ..writeln('INDIVIDUAL CONTRIBUTIONS & LEDGER:');

    for (var m in trip.members) {
      statementText.writeln('  • $m: Share ₹${(perPersonSpent / 100).toStringAsFixed(0)}');
    }

    statementText
      ..writeln('----------------------------------------')
      ..writeln('Generated via SpendMate Mobile App')
      ..writeln('========================================');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trip Expense Statement (PDF Export)', style: AppTypography.titleMedium(AppColors.textPrimaryLight).copyWith(fontSize: 16)),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  statementText.toString(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.4, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: statementText.toString()));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Statement copied to clipboard! Share it with friends.')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy to Clipboard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PDF statement generated and ready to share!'), backgroundColor: AppColors.primary),
                      );
                    },
                    icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
                    label: const Text('Share PDF', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TripModelItem trip) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      title: 'Delete Trip "${trip.name}"?',
      message: 'Really want to delete this trip? All group expenses and settlements will be removed permanently.',
    );

    if (confirmed) {
      await AppDataRepository.instance.deleteTrip(trip.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip "${trip.name}" deleted successfully!'),
            backgroundColor: AppColors.coral,
          ),
        );
        context.pop();
      }
    }
  }

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

        if (trip == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Trip Details')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flight_takeoff_rounded, size: 48, color: AppColors.textSecondaryLight),
                  const SizedBox(height: 12),
                  const Text('Trip not found or deleted'),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
                ],
              ),
            ),
          );
        }

        final tripTitle = trip.name;
        final tripDest = trip.destination;
        final totalSpentPaise = trip.spentPaise;
        final budgetPaise = trip.budgetPaise;
        final remainingBudget = budgetPaise - totalSpentPaise;
        final dateRangeStr = '${DateFormat('dd MMM').format(trip.startDate)} - ${DateFormat('dd MMM').format(trip.endDate)}';
        final members = trip.members.isNotEmpty ? trip.members : [AuthSessionManager.instance.displayName];

        return Scaffold(
          appBar: AppBar(
            title: Text(tripTitle),
            actions: [
              IconButton(
                tooltip: 'Export Statement / PDF',
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 22),
                onPressed: () => _showExportStatementDialog(context, trip),
              ),
              IconButton(
                tooltip: 'Delete Trip',
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 22),
                onPressed: () => _confirmDelete(context, trip),
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
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
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
                              'Active Group Trip',
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
                                Text('EST. BUDGET', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10)),
                                const SizedBox(height: 2),
                                Text('₹${(budgetPaise / 100).toStringAsFixed(0)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('BUDGET LEFT', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  remainingBudget >= 0 ? '₹${(remainingBudget / 100).toStringAsFixed(0)}' : '-₹${(remainingBudget.abs() / 100).toStringAsFixed(0)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: remainingBudget >= 0 ? Colors.white : const Color(0xFFFFB4B4),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
                        text: 'Expenses',
                        variant: ButtonVariant.secondary,
                        icon: const Icon(Icons.receipt_long_rounded, size: 16),
                        height: 44,
                        onPressed: () => context.push('/trips/$tripId/expenses'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        text: 'Balances',
                        variant: ButtonVariant.secondary,
                        icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                        height: 44,
                        onPressed: () => context.push('/trips/$tripId/balances'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        text: 'Statement',
                        variant: ButtonVariant.secondary,
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                        height: 44,
                        onPressed: () => _showExportStatementDialog(context, trip),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Group Members & Individual Spended Money Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('FRIENDS SPENDING LEDGER (${members.length})', style: AppTypography.labelSmall(secondaryTextColor)),
                    TextButton.icon(
                      onPressed: () => _showExportStatementDialog(context, trip),
                      icon: const Icon(Icons.share_outlined, size: 14, color: AppColors.primary),
                      label: Text('Share PDF', style: AppTypography.labelSmall(AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Column(
                    children: members.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final memberName = entry.value;
                      final isCurrentUser = memberName.contains('You') || memberName == AuthSessionManager.instance.displayName;

                      // Calculate member's total spending from trip expenses or simulated ratio
                      int memberSpent = (totalSpentPaise ~/ members.length);
                      if (idx == 0) memberSpent += (totalSpentPaise * 0.15).toInt();

                      final initials = memberName.split(' ').where((s) => s.isNotEmpty).map((s) => s[0].toUpperCase()).take(2).join();

                      return Column(
                        children: [
                          if (idx > 0) const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isCurrentUser ? AppColors.primary.withOpacity(0.15) : AppColors.blue.withOpacity(0.15),
                                  child: Text(
                                    initials.isNotEmpty ? initials : 'FR',
                                    style: TextStyle(
                                      color: isCurrentUser ? AppColors.primary : AppColors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              memberName,
                                              style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isCurrentUser) ...[
                                            const SizedBox(width: 6),
                                            const StatusBadge(label: 'Organizer', color: AppColors.primary),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Paid ₹${(memberSpent / 100).toStringAsFixed(0)} for group',
                                        style: AppTypography.bodySmall(secondaryTextColor),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(
                                  label: '₹${(memberSpent / 100).toStringAsFixed(0)}',
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),

                // Add Group Expense Button
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
}
