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

  void _showEditTripDialog(BuildContext context, TripModelItem trip) {
    final titleController = TextEditingController(text: trip.name);
    final destController = TextEditingController(text: trip.destination);
    final budgetController = TextEditingController(
      text: trip.budgetPaise > 0 ? (trip.budgetPaise / 100).toStringAsFixed(0) : '',
    );
    final friendsController = TextEditingController(text: trip.members.join(', '));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Trip Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Trip Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destController,
                decoration: const InputDecoration(labelText: 'Destination', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Est. Budget (₹) - Optional',
                  hintText: 'Leave empty for flexible / open budget',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: friendsController,
                decoration: const InputDecoration(
                  labelText: 'Friends / Members (comma separated)',
                  hintText: 'e.g. Rahul, Sneha, Arun, Vikram',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group_outlined),
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
                    final budgetNum = int.tryParse(budgetController.text.trim()) ?? 0;

                    final parsedMembers = friendsController.text
                        .split(',')
                        .map((f) => f.trim())
                        .where((f) => f.isNotEmpty)
                        .toList();

                    await AppDataRepository.instance.updateTrip(
                      id: trip.id,
                      name: title,
                      destination: dest.isNotEmpty ? dest : trip.destination,
                      budgetPaise: budgetNum * 100,
                      startDate: trip.startDate,
                      endDate: trip.endDate,
                      members: parsedMembers.isNotEmpty ? parsedMembers : trip.members,
                    );

                    AppSoundService.playIncomeChime();

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Trip "$title" updated successfully!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportStatementDialog(BuildContext context, TripModelItem trip) {
    AppSoundService.playSuccess();
    final memberCount = trip.members.isNotEmpty ? trip.members.length : 1;
    final perPersonSpent = trip.spentPaise ~/ memberCount;

    final statementText = StringBuffer()
      ..writeln('========================================')
      ..writeln('   SPENDMATE TRIP FINANCIAL STATEMENT   ')
      ..writeln('========================================')
      ..writeln('Trip: ${trip.name}')
      ..writeln('Destination: ${trip.destination}')
      ..writeln('Dates: ${DateFormat('dd MMM yyyy').format(trip.startDate)} - ${DateFormat('dd MMM yyyy').format(trip.endDate)}')
      ..writeln('----------------------------------------')
      ..writeln('FINANCIAL SUMMARY:')
      ..writeln('  Total Group Spent:  ₹${(trip.spentPaise / 100).toStringAsFixed(2)}')
      ..writeln('  Total Group Budget: ${trip.budgetPaise > 0 ? '₹${(trip.budgetPaise / 100).toStringAsFixed(2)}' : 'Flexible (No Limit)'}')
      ..writeln('  Per Person Share:   ₹${(perPersonSpent / 100).toStringAsFixed(2)}')
      ..writeln('----------------------------------------')
      ..writeln('SHARED EXPENSES & ITEM BREAKDOWN:');

    if (trip.expenses.isEmpty) {
      statementText.writeln('  (No individual items recorded yet)');
    } else {
      for (var e in trip.expenses) {
        final amt = (e['amountPaise'] as int? ?? 0) / 100;
        statementText.writeln('  • ${e['title']}: ₹${amt.toStringAsFixed(0)} (Paid by: ${e['paidBy']})');
      }
    }

    statementText
      ..writeln('----------------------------------------')
      ..writeln('INDIVIDUAL CONTRIBUTIONS & BALANCES:');

    for (var m in trip.members) {
      final actualPaid = trip.expenses
          .where((e) => e['paidBy'] == m || (m.contains('You') && e['paidBy'] == AuthSessionManager.instance.displayName))
          .fold<int>(0, (sum, e) => sum + (e['amountPaise'] as int? ?? 0));

      final balance = actualPaid - perPersonSpent;
      final balanceStr = balance > 0
          ? 'Gets back ₹${(balance / 100).toStringAsFixed(0)}'
          : (balance < 0 ? 'Owes ₹${(balance.abs() / 100).toStringAsFixed(0)}' : 'Settled');

      statementText.writeln('  • $m: Paid ₹${(actualPaid / 100).toStringAsFixed(0)} -> $balanceStr');
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
              maxHeight: 280,
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
                    label: const Text('Copy Text'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: statementText.toString()));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PDF Statement copied! Ready to share via WhatsApp.'), backgroundColor: AppColors.primary),
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
        final hasBudget = budgetPaise > 0;
        final remainingBudget = budgetPaise - totalSpentPaise;
        final dateRangeStr = '${DateFormat('dd MMM').format(trip.startDate)} - ${DateFormat('dd MMM').format(trip.endDate)}';
        final members = trip.members.isNotEmpty ? trip.members : [AuthSessionManager.instance.displayName];

        return Scaffold(
          appBar: AppBar(
            title: Text(tripTitle),
            actions: [
              IconButton(
                tooltip: 'Edit Trip',
                icon: const Icon(Icons.edit_outlined, size: 22),
                onPressed: () => _showEditTripDialog(context, trip),
              ),
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
                      const SizedBox(height: 14),
                      Text(
                        tripTitle,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      const SizedBox(height: 18),

                      // Safe Responsive Metric Row (Zero Overflows!)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TOTAL SPENT', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${(totalSpentPaise / 100).toStringAsFixed(0)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('EST. BUDGET', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  hasBudget ? '₹${(budgetPaise / 100).toStringAsFixed(0)}' : 'Flexible',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                                ),
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
                                  hasBudget
                                      ? (remainingBudget >= 0 ? '₹${(remainingBudget / 100).toStringAsFixed(0)}' : '-₹${(remainingBudget.abs() / 100).toStringAsFixed(0)}')
                                      : 'No Limit',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: !hasBudget || remainingBudget >= 0 ? Colors.white : const Color(0xFFFFB4B4),
                                    fontSize: 17,
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
                const SizedBox(height: 18),

                // Navigation Feature Pills
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.receipt_long_rounded, size: 16),
                        label: const Text('Expenses', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        onPressed: () => context.push('/trips/$tripId/expenses'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                        label: const Text('Balances', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        onPressed: () => context.push('/trips/$tripId/balances'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                        label: const Text('Statement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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

                // Members list with EXACT spent amounts from trip.expenses
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Column(
                    children: members.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final memberName = entry.value;
                      final isCurrentUser = memberName.contains('You') || memberName == AuthSessionManager.instance.displayName;

                      // Calculate EXACT member spend from trip.expenses
                      int memberSpent = 0;
                      for (var exp in trip.expenses) {
                        if (exp['paidBy'] == memberName || (isCurrentUser && exp['paidBy'] == AuthSessionManager.instance.displayName)) {
                          memberSpent += (exp['amountPaise'] as int? ?? 0);
                        }
                      }

                      final initials = memberName.split(' ').where((s) => s.isNotEmpty).map((s) => s[0].toUpperCase()).take(2).join();

                      return Column(
                        children: [
                          if (idx > 0) const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
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
                                      Text(
                                        isCurrentUser ? '$memberName (You)' : memberName,
                                        style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Paid ₹${(memberSpent / 100).toStringAsFixed(0)} for group',
                                        style: AppTypography.bodySmall(secondaryTextColor).copyWith(fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge(
                                  label: '₹${(memberSpent / 100).toStringAsFixed(0)}',
                                  color: memberSpent > 0 ? AppColors.primary : Colors.grey,
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
