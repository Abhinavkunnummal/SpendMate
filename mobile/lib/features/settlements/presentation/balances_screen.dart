import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../core/data/app_data_repository.dart';
import '../../../core/services/app_sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/widgets/delete_confirmation_dialog.dart';

class DebtTransfer {
  final String from;
  final String to;
  final int amountPaise;

  const DebtTransfer({
    required this.from,
    required this.to,
    required this.amountPaise,
  });
}

class BalancesScreen extends StatelessWidget {
  final String tripId;
  const BalancesScreen({super.key, required this.tripId});

  List<DebtTransfer> _calculateOptimalTransfers(Map<String, int> netMap) {
    final debtors = <MapEntry<String, int>>[];
    final creditors = <MapEntry<String, int>>[];

    netMap.forEach((name, net) {
      if (net < -50) {
        debtors.add(MapEntry(name, -net)); // Store as positive debt
      } else if (net > 50) {
        creditors.add(MapEntry(name, net));
      }
    });

    debtors.sort((a, b) => b.value.compareTo(a.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    final results = <DebtTransfer>[];
    int i = 0;
    int j = 0;

    while (i < debtors.length && j < creditors.length) {
      final debtor = debtors[i];
      final creditor = creditors[j];
      final settleAmt = debtor.value < creditor.value ? debtor.value : creditor.value;

      if (settleAmt > 0) {
        results.add(DebtTransfer(from: debtor.key, to: creditor.key, amountPaise: settleAmt));
      }

      if (debtor.value == settleAmt) {
        i++;
      } else {
        debtors[i] = MapEntry(debtor.key, debtor.value - settleAmt);
      }

      if (creditor.value == settleAmt) {
        j++;
      } else {
        creditors[j] = MapEntry(creditor.key, creditor.value - settleAmt);
      }
    }

    return results;
  }

  void _shareBalanceSummary(
    BuildContext context,
    String tripName,
    int totalTripSpent,
    List<String> members,
    int sharePerMember,
    Map<String, int> paidMap,
    Map<String, int> netMap,
    List<DebtTransfer> transfers,
  ) {
    AppSoundService.playSuccess();
    final buffer = StringBuffer()
      ..writeln('====================================')
      ..writeln('   SPENDMATE TRIP BALANCE STATEMENT ')
      ..writeln('====================================')
      ..writeln('Trip: $tripName')
      ..writeln('Total Spent: ₹${(totalTripSpent / 100).toStringAsFixed(2)}')
      ..writeln('Members (${members.length}): ${members.join(', ')}')
      ..writeln('Equal Share per Member: ₹${(sharePerMember / 100).toStringAsFixed(2)}')
      ..writeln('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}')
      ..writeln('------------------------------------')
      ..writeln('MEMBER CONTRIBUTIONS & BALANCES:');

    for (var m in members) {
      final paid = paidMap[m] ?? 0;
      final net = netMap[m] ?? 0;
      final standing = net > 0
          ? 'receives +₹${(net / 100).toStringAsFixed(0)}'
          : (net < 0 ? 'owes -₹${(net.abs() / 100).toStringAsFixed(0)}' : 'settled (₹0)');
      buffer.writeln('• $m: paid ₹${(paid / 100).toStringAsFixed(0)} ($standing)');
    }

    buffer.writeln('------------------------------------');
    buffer.writeln('SUGGESTED DEBT MINIMIZER SETTLEMENTS:');
    if (transfers.isEmpty) {
      buffer.writeln('  All expenses are fully balanced! No transfers needed.');
    } else {
      for (var t in transfers) {
        buffer.writeln('• ${t.from} pays ${t.to} -> ₹${(t.amountPaise / 100).toStringAsFixed(2)}');
      }
    }
    buffer.writeln('------------------------------------');
    buffer.writeln('Calculated with SpendMate');
    buffer.writeln('====================================');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip balance statement copied! Paste in WhatsApp to share with the group.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return ListenableBuilder(
      listenable: AppDataRepository.instance,
      builder: (context, _) {
        final trips = AppDataRepository.instance.trips;
        final trip = trips.cast<TripModelItem?>().firstWhere(
          (t) => t?.id == tripId,
          orElse: () => null,
        );

        if (trip == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Balances & Settlements')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.luggage_outlined, size: 64, color: secondaryTextColor),
                  const SizedBox(height: 16),
                  Text('Trip not found', style: AppTypography.titleLarge(primaryTextColor)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Gather all members
        final memberSet = <String>{};
        if (trip.members.isNotEmpty) {
          memberSet.addAll(trip.members);
        }
        for (var exp in trip.expenses) {
          final paidBy = exp['paidBy'] as String?;
          if (paidBy != null && paidBy.trim().isNotEmpty) {
            memberSet.add(paidBy.trim());
          }
        }
        final myName = AuthSessionManager.instance.displayName;
        if (memberSet.isEmpty) {
          memberSet.add(myName);
        }
        final members = memberSet.toList();

        // Calculate paid map & total
        final Map<String, int> paidMap = {for (var m in members) m: 0};
        int totalTripSpent = 0;
        for (var exp in trip.expenses) {
          final amt = (exp['amountPaise'] as num?)?.toInt() ?? 0;
          final p = (exp['paidBy'] as String?)?.trim() ?? members.first;
          paidMap[p] = (paidMap[p] ?? 0) + amt;
          totalTripSpent += amt;
        }

        // Apply completed settlements to paidMap:
        // Payer (debtor) has satisfied their obligation (+amt contributed)
        // Receiver (creditor) has received reimbursement (-amt remaining credit)
        for (var s in trip.settlements) {
          final sAmt = (s['amountPaise'] as num?)?.toInt() ?? 0;
          final sFrom = (s['from'] as String?)?.trim() ?? '';
          final sTo = (s['to'] as String?)?.trim() ?? '';
          if (sFrom.isNotEmpty && sTo.isNotEmpty && sAmt > 0) {
            paidMap[sFrom] = (paidMap[sFrom] ?? 0) + sAmt;
            paidMap[sTo] = (paidMap[sTo] ?? 0) - sAmt;
          }
        }

        // Calculate equal share
        final sharePerMember = members.isNotEmpty ? (totalTripSpent / members.length).round() : 0;

        // Calculate net standing
        final Map<String, int> netMap = {};
        for (var m in members) {
          netMap[m] = (paidMap[m] ?? 0) - sharePerMember;
        }

        // User standing: match current user in members list
        int userNet = 0;
        final matchedMember = members.firstWhere(
          (m) =>
              m.toLowerCase().trim() == myName.toLowerCase().trim() ||
              m.toLowerCase().contains(myName.toLowerCase().trim()) ||
              myName.toLowerCase().contains(m.toLowerCase().trim()) ||
              m.toLowerCase().contains('you'),
          orElse: () => '',
        );
        final bool userIsInTrip = matchedMember.isNotEmpty;
        if (userIsInTrip) {
          userNet = netMap[matchedMember] ?? 0;
        }

        final transfers = _calculateOptimalTransfers(netMap);
        final int totalPendingPaise = transfers.fold<int>(0, (sum, t) => sum + t.amountPaise);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Balances & Settlements'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share Balance Statement',
                onPressed: () => _shareBalanceSummary(
                  context,
                  trip.name,
                  totalTripSpent,
                  members,
                  sharePerMember,
                  paidMap,
                  netMap,
                  transfers,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User & Group Standing Hero Card
                // Never prematurely shows "All settled 0" if pending group settlements exist!
                Builder(
                  builder: (context) {
                    final bool hasPendingTransfers = transfers.isNotEmpty;
                    final bool userHasDirectBalance = userIsInTrip && userNet.abs() > 50;

                    final String heroTitle = userHasDirectBalance
                        ? 'YOUR NET GROUP STANDING'
                        : (hasPendingTransfers ? 'GROUP PENDING SETTLEMENTS' : 'GROUP SETTLEMENT STATUS');

                    final String heroAmount = userHasDirectBalance
                        ? (userNet > 0
                            ? 'You are owed ₹${(userNet / 100).toStringAsFixed(2)}'
                            : 'You owe ₹${(userNet.abs() / 100).toStringAsFixed(2)}')
                        : (hasPendingTransfers
                            ? '₹${(totalPendingPaise / 100).toStringAsFixed(2)} to Settle'
                            : 'All Settled Up! (₹0.00)');

                    final String heroSubtitle = userHasDirectBalance
                        ? (hasPendingTransfers
                            ? '${transfers.length} pending transfer${transfers.length > 1 ? 's' : ''} in group · Total: ₹${(totalTripSpent / 100).toStringAsFixed(0)}'
                            : 'All group debts cleared · Equal share: ₹${(sharePerMember / 100).toStringAsFixed(0)}')
                        : (hasPendingTransfers
                            ? '${transfers.length} transfer${transfers.length > 1 ? 's' : ''} pending between friends · Your balance: ₹0.00'
                            : (totalTripSpent == 0
                                ? 'No expenses recorded yet in this trip'
                                : 'All members have paid their exact share (₹${(sharePerMember / 100).toStringAsFixed(0)} each)'));

                    final List<Color> gradientColors = userHasDirectBalance
                        ? (userNet > 0
                            ? [const Color(0xFF16A878), const Color(0xFF0F8A62)]
                            : [const Color(0xFFEF4444), const Color(0xFFB91C1C)])
                        : (hasPendingTransfers
                            ? [const Color(0xFFD97706), const Color(0xFFB45309)] // Amber when group owes money
                            : [const Color(0xFF334155), const Color(0xFF1E293B)]); // Slate when fully settled

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors.first.withOpacity(0.28),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                heroTitle,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (hasPendingTransfers)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${transfers.length} Pending',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            heroAmount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            heroSubtitle,
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Optimal Suggested Payments Section (Debt Minimizer output)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'SUGGESTED PAYMENTS (${transfers.length})',
                        style: AppTypography.labelSmall(secondaryTextColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Debt Minimizer Active',
                        style: AppTypography.labelSmall(AppColors.primary).copyWith(fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (transfers.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 40, color: AppColors.primary),
                          const SizedBox(height: 10),
                          Text(
                            totalTripSpent == 0
                                ? 'No expenses recorded yet'
                                : 'All members are fully settled!',
                            style: AppTypography.titleMedium(primaryTextColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalTripSpent == 0
                                ? 'Tap "+ Expense" in trip details to add petrol, hotel or food.'
                                : 'Every member has paid their exact share.',
                            style: AppTypography.bodySmall(secondaryTextColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...transfers.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final t = entry.value;
                    return _suggestedPaymentCard(
                      context: context,
                      settleIndex: idx,
                      tripId: trip.id,
                      fromName: t.from,
                      toName: t.to,
                      amountPaise: t.amountPaise,
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    );
                  }),

                const SizedBox(height: 24),

                // Individual Net Balances
                Text('INDIVIDUAL NET BALANCES (${members.length})', style: AppTypography.labelSmall(secondaryTextColor)),
                const SizedBox(height: 10),

                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: members.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final m = entry.value;
                      final net = netMap[m] ?? 0;
                      final isMe = m.toLowerCase().contains(myName.toLowerCase()) || m.toLowerCase().contains('you');
                      final displayName = isMe ? '$m (You)' : m;

                      return Column(
                        children: [
                          if (idx > 0) const Divider(height: 1),
                          _balanceRow(displayName, net, primaryTextColor),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Completed Settlements Section
                if (trip.settlements.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'COMPLETED SETTLEMENTS (${trip.settlements.length})',
                        style: AppTypography.labelSmall(secondaryTextColor),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Settled & Verified',
                          style: AppTypography.labelSmall(AppColors.primary).copyWith(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...trip.settlements.reversed.map((s) {
                    final sFrom = s['from'] as String? ?? 'Member';
                    final sTo = s['to'] as String? ?? 'Member';
                    final sAmt = (s['amountPaise'] as num?)?.toInt() ?? 0;
                    final sId = s['id'] as String? ?? '';
                    final sDate = s['settledAt'] != null
                        ? DateFormat('dd MMM, hh:mm a').format(DateTime.tryParse(s['settledAt']) ?? DateTime.now())
                        : 'Recently';

                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$sFrom paid $sTo',
                                  style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Settled on $sDate',
                                  style: AppTypography.bodySmall(secondaryTextColor).copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CurrencyText(
                                amountPaise: sAmt,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                customColor: AppColors.primary,
                              ),
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: () async {
                                  final confirmed = await DeleteConfirmationDialog.show(
                                    context,
                                    title: 'Undo Settlement?',
                                    message:
                                        'Remove this settlement record and return ₹${(sAmt / 100).toStringAsFixed(2)} to pending debt?',
                                    confirmLabel: 'Undo',
                                  );
                                  if (confirmed) {
                                    await AppDataRepository.instance.deleteTripSettlement(trip.id, sId);
                                    AppSoundService.playSuccess();
                                  }
                                },
                                child: const Text(
                                  'Undo',
                                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _suggestedPaymentCard({
    required BuildContext context,
    required int settleIndex,
    required String tripId,
    required String fromName,
    required String toName,
    required int amountPaise,
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTypography.bodyMedium(primaryTextColor),
                    children: [
                      TextSpan(text: fromName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const TextSpan(text: ' pays '),
                      TextSpan(text: toName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text('UPI Direct Transfer', style: AppTypography.bodySmall(secondaryTextColor)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CurrencyText(amountPaise: amountPaise, fontSize: 16, fontWeight: FontWeight.w700),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  final encodedFrom = Uri.encodeComponent(fromName);
                  final encodedTo = Uri.encodeComponent(toName);
                  context.push(
                    '/settlements/settle-$settleIndex?from=$encodedFrom&to=$encodedTo&amount=$amountPaise&tripId=$tripId',
                    extra: {
                      'fromName': fromName,
                      'toName': toName,
                      'amountPaise': amountPaise,
                      'tripId': tripId,
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Settle Up',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceRow(String name, int netPaise, Color textColor) {
    final getsMoney = netPaise > 0;
    final isZero = netPaise == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: AppTypography.bodyMedium(textColor).copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (isZero)
            const Text(
              'settled (₹0)',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
            )
          else
            Row(
              children: [
                Text(
                  getsMoney ? 'receives ' : 'owes ',
                  style: TextStyle(fontSize: 12, color: getsMoney ? AppColors.primary : AppColors.coral),
                ),
                CurrencyText(
                  amountPaise: netPaise.abs(),
                  customColor: getsMoney ? AppColors.primary : AppColors.coral,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
