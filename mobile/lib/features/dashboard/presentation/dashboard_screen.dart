import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/widgets/delete_confirmation_dialog.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../core/data/app_data_repository.dart';
import '../../../core/services/app_sound_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _showSetBudgetCapDialog(BuildContext context) {
    final currentCap = AppDataRepository.instance.monthlyBudgetCapPaise ~/ 100;
    final ctrl = TextEditingController(text: currentCap.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.track_changes_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Set Monthly Spend Cap', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Limit how much you want to spend this month. SpendMate will alert you if you exceed this budget.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Monthly Spending Limit (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(ctrl.text.trim()) ?? 5000;
              await AppDataRepository.instance.setMonthlyBudgetCap(val * 100);
              AppSoundService.playSuccess();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Monthly budget cap set to ₹${NumberFormat('#,##,##0').format(val)}!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save Limit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTransaction(BuildContext context, TransactionModel tx) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      title: 'Delete Transaction?',
      message: 'Really want to delete "${tx.title}" (₹${(tx.amountPaise / 100).toStringAsFixed(2)})? This will restore the wallet balance.',
    );

    if (confirmed) {
      await AppDataRepository.instance.deleteTransaction(tx.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction "${tx.title}" deleted!'),
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 400));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Greeting & Profile Avatar
                ListenableBuilder(
                  listenable: AuthSessionManager.instance,
                  builder: (context, _) {
                    final auth = AuthSessionManager.instance;
                    final displayName = auth.displayName;
                    final initials = auth.userInitials;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome back,', style: AppTypography.bodySmall(secondaryTextColor)),
                              const SizedBox(height: 2),
                              Text(
                                displayName,
                                style: AppTypography.titleLarge(primaryTextColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
                            child: Text(
                              initials,
                              style: AppTypography.labelLarge(AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Apple Wallet Style Balance Card (Gain in Green, Loss in Red, Not mixed!)
                ListenableBuilder(
                  listenable: AppDataRepository.instance,
                  builder: (context, _) {
                    final repo = AppDataRepository.instance;
                    final netWorth = repo.netWorthPaise;
                    final income = repo.totalIncomeThisMonthPaise;
                    final spent = repo.totalSpentThisMonthPaise;
                    final walletCount = repo.wallets.length;
                    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
                    final compactFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF16A878), Color(0xFF0F766E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL AVAILABLE NET WORTH',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/wallets'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '$walletCount ${walletCount == 1 ? 'Account' : 'Accounts'}',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.chevron_right, size: 14, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(netWorth / 100),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                // Gain (Green Theme)
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.arrow_downward_rounded, size: 14, color: Colors.white),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Gain (Income)', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                                            Text(compactFormat.format(income / 100), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 28, color: Colors.white.withOpacity(0.25)),
                                // Loss (Red Theme)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.arrow_upward_rounded, size: 14, color: Colors.white),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Loss (Spent)', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                                              Text(compactFormat.format(spent / 100), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFFFD4D4), fontWeight: FontWeight.w700, fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Today's Expense & Income Pulse (Separate from Net Worth!)
                ListenableBuilder(
                  listenable: AppDataRepository.instance,
                  builder: (context, _) {
                    final repo = AppDataRepository.instance;
                    final todaySpent = repo.totalSpentTodayPaise;
                    final todayIncome = repo.totalIncomeTodayPaise;
                    final todayNet = todayIncome - todaySpent;

                    return AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.today_rounded, size: 20, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "TODAY'S TRANSACTIONS",
                                  style: AppTypography.labelSmall(secondaryTextColor).copyWith(fontSize: 10),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      'Spend: ₹${(todaySpent / 100).toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.coral),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Income: ₹${(todayIncome / 100).toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: todayNet >= 0 ? AppColors.primaryLight : AppColors.coralLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              todayNet >= 0
                                  ? '+₹${(todayNet / 100).toStringAsFixed(0)}'
                                  : '-₹${(todayNet.abs() / 100).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: todayNet >= 0 ? AppColors.primary : AppColors.coral,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Fast Action Floating Widget Row (Expense, Income, New Trip - Scan Bill Removed)
                Row(
                  children: [
                    Expanded(
                      child: _quickActionItem(
                        icon: Icons.add_rounded,
                        label: '+ Expense',
                        color: AppColors.coral,
                        onTap: () => context.push('/add-transaction?type=expense'),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _quickActionItem(
                        icon: Icons.arrow_downward_rounded,
                        label: '+ Income',
                        color: AppColors.primary,
                        onTap: () => context.push('/add-transaction?type=income'),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _quickActionItem(
                        icon: Icons.luggage_outlined,
                        label: 'New Trip',
                        color: AppColors.blue,
                        onTap: () => context.push('/trips'),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Dedicated Patt Book Card (Moved DOWN right under Income/Expense Fast Actions!)
                ListenableBuilder(
                  listenable: AppDataRepository.instance,
                  builder: (context, _) {
                    final repo = AppDataRepository.instance;
                    final youWillGet = repo.totalYouWillGetPaise;
                    final youWillGive = repo.totalYouWillGivePaise;
                    final friendCount = repo.pattFriends.length;

                    return GestureDetector(
                      onTap: () => context.push('/patt-book'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.menu_book_rounded, color: Colors.orange, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Patt Book (Friend Ledger)',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$friendCount Friends · Separate Total',
                                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('You Will Get (To Receive)', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text('₹${(youWillGet / 100).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.coral.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.coral.withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('You Will Give (To Pay)', style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text('₹${(youWillGive / 100).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Dedicated Monthly Spending Limit Space with Exceeded Warning
                ListenableBuilder(
                  listenable: AppDataRepository.instance,
                  builder: (context, _) {
                    final repo = AppDataRepository.instance;
                    final capPaise = repo.monthlyBudgetCapPaise;
                    final spentPaise = repo.totalSpentThisMonthPaise;
                    final isExceeded = repo.isBudgetCapExceeded;
                    final remainingPaise = repo.budgetRemainingPaise;

                    final double ratio = capPaise > 0 ? (spentPaise / capPaise).clamp(0.0, 1.0) : 0.0;
                    final now = DateTime.now();
                    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
                    final daysLeft = daysInMonth - now.day + 1;
                    final safeDailyPace = remainingPaise > 0 && daysLeft > 0 ? (remainingPaise / daysLeft / 100).toStringAsFixed(0) : '0';

                    return AppCard(
                      onTap: () => _showSetBudgetCapDialog(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isExceeded ? Icons.warning_amber_rounded : Icons.speed_rounded,
                                    size: 20,
                                    color: isExceeded ? AppColors.coral : AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Monthly Spending Cap Space',
                                    style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => _showSetBudgetCapDialog(context),
                                child: Text('Edit Cap', style: AppTypography.labelSmall(AppColors.primary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          if (isExceeded) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.coral.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.coral.withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'WARNING: You exceeded your ₹${(capPaise / 100).toStringAsFixed(0)} limit by ₹${(remainingPaise.abs() / 100).toStringAsFixed(0)}!',
                                      style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Text(
                              '₹${(spentPaise / 100).toStringAsFixed(0)} spent of ₹${(capPaise / 100).toStringAsFixed(0)} cap (₹$safeDailyPace/day safe pace)',
                              style: AppTypography.bodySmall(secondaryTextColor),
                            ),
                          ],
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 8,
                              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                              valueColor: AlwaysStoppedAnimation<Color>(isExceeded ? AppColors.coral : AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Active Trips Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Trips', style: AppTypography.titleMedium(primaryTextColor)),
                    TextButton(
                      onPressed: () => context.push('/trips'),
                      child: Text('See All', style: AppTypography.labelSmall(AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Dynamic Active Trip Card
                ListenableBuilder(
                  listenable: AppDataRepository.instance,
                  builder: (context, _) {
                    final trips = AppDataRepository.instance.trips;
                    if (trips.isEmpty) {
                      return AppCard(
                        onTap: () => context.push('/trips'),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.blue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.flight_takeoff_rounded, color: AppColors.blue, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Plan Your Next Group Trip', style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text('Add co-travelers and track split balances.', style: AppTypography.bodySmall(secondaryTextColor)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                          ],
                        ),
                      );
                    }

                    final trip = trips.first;
                    return AppCard(
                      onTap: () => context.push('/trips/${trip.id}'),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.blue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.beach_access_rounded, color: AppColors.blue, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip.name,
                                  style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${trip.members.length} friends · ${trip.destination}',
                                  style: AppTypography.bodySmall(secondaryTextColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${(trip.spentPaise / 100).toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text('Spent', style: AppTypography.labelSmall(AppColors.primary)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Recent Transactions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Activity', style: AppTypography.titleMedium(primaryTextColor)),
                    TextButton(
                      onPressed: () => context.push('/transactions'),
                      child: Text('View All', style: AppTypography.labelSmall(AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Dynamic Recent Transactions List
                ListenableBuilder(
                  listenable: AppDataRepository.instance,
                  builder: (context, _) {
                    final txs = AppDataRepository.instance.transactions.take(5).toList();

                    if (txs.isEmpty) {
                      return AppCard(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.textSecondaryLight),
                              const SizedBox(height: 10),
                              Text('No transactions yet', style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('Tap "+ Expense" or "+ Income" to record your first transaction.', textAlign: TextAlign.center, style: AppTypography.bodySmall(secondaryTextColor)),
                            ],
                          ),
                        ),
                      );
                    }

                    return AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Column(
                        children: txs.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final tx = entry.value;

                          return Column(
                            children: [
                              if (idx > 0) const Divider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: tx.isExpense ? AppColors.coral.withOpacity(0.12) : AppColors.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(tx.icon, size: 20, color: tx.isExpense ? AppColors.coral : AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.title,
                                            style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${tx.category} · ${tx.wallet}',
                                            style: AppTypography.bodySmall(secondaryTextColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        CurrencyText(
                                          amountPaise: tx.amountPaise,
                                          isExpense: tx.isExpense,
                                          isIncome: !tx.isExpense,
                                          showSign: true,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        const SizedBox(height: 2),
                                        GestureDetector(
                                          onTap: () => _confirmDeleteTransaction(context, tx),
                                          child: const Text('Delete', style: TextStyle(color: AppColors.coral, fontSize: 11, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        AppSoundService.playSuccess();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
