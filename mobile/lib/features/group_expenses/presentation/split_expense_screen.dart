import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../core/data/app_data_repository.dart';
import '../../../core/services/app_sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';

class SplitExpenseScreen extends StatefulWidget {
  final String tripId;
  const SplitExpenseScreen({super.key, required this.tripId});

  @override
  State<SplitExpenseScreen> createState() => _SplitExpenseScreenState();
}

class _SplitExpenseScreenState extends State<SplitExpenseScreen> {
  int _splitMethod = 0; // 0: Equal, 1: Custom, 2: Percentage
  bool _isLoading = false;
  int _totalExpense = 1200;

  late final List<Map<String, dynamic>> _participants;

  @override
  void initState() {
    super.initState();
    _initParticipants();
  }

  void _initParticipants() {
    final tripList = AppDataRepository.instance.trips;
    final trip = tripList.cast<TripModelItem?>().firstWhere(
      (t) => t?.id == widget.tripId,
      orElse: () => null,
    );

    final myName = AuthSessionManager.instance.displayName;
    final members = (trip != null && trip.members.isNotEmpty)
        ? trip.members
        : [myName, 'Friend 1'];

    final count = members.length;
    final perPerson = _totalExpense ~/ count;
    final percent = (100 / count).round();

    _participants = members.map((m) {
      final isYou = m.contains('You') || m == myName;
      return {
        'name': isYou ? '$m (You)' : m,
        'selected': true,
        'share': perPerson,
        'percent': percent,
      };
    }).toList();
  }

  void _recalculateShares() {
    final selectedCount = _participants.where((p) => p['selected'] as bool).length;
    if (selectedCount == 0) return;

    final perPerson = _totalExpense ~/ selectedCount;
    for (var p in _participants) {
      if (p['selected'] as bool) {
        p['share'] = perPerson;
        p['percent'] = (100 / selectedCount).round();
      } else {
        p['share'] = 0;
        p['percent'] = 0;
      }
    }
  }

  void _handleConfirm() async {
    setState(() => _isLoading = true);

    final tripList = AppDataRepository.instance.trips;
    final trip = tripList.cast<TripModelItem?>().firstWhere(
      (t) => t?.id == widget.tripId,
      orElse: () => null,
    );
    final payer = (trip != null && trip.members.isNotEmpty) ? trip.members.first : 'You';

    await AppDataRepository.instance.addTripExpense(
      tripId: widget.tripId,
      title: 'Group Shared Expense',
      amountPaise: _totalExpense * 100,
      paidBy: payer,
    );

    AppSoundService.playIncomeChime();

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Split of ₹$_totalExpense saved and group balances updated!'),
        backgroundColor: AppColors.primary,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Summary Card
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXPENSE TO SPLIT', style: AppTypography.labelSmall(secondaryTextColor)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹$_totalExpense',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      StatusBadge(
                        label: '${_participants.where((p) => p['selected'] as bool).length} People',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Split Method Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _methodTab('Equal', 0, isDark),
                  _methodTab('Custom', 1, isDark),
                  _methodTab('Percentage', 2, isDark),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Participants Checklist & Split Calculation
            Text('SPLIT BETWEEN MEMBERS', style: AppTypography.labelSmall(secondaryTextColor)),
            const SizedBox(height: 8),

            AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: _participants.map((p) {
                  final isSelected = p['selected'] as bool;
                  final name = p['name'] as String;
                  final share = p['share'] as int;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Checkbox.adaptive(
                          value: isSelected,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              p['selected'] = val ?? true;
                              _recalculateShares();
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            name,
                            style: AppTypography.titleMedium(primaryTextColor).copyWith(
                              fontSize: 14,
                              color: isSelected ? primaryTextColor : secondaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _splitMethod == 2 ? '${p['percent']}%' : '₹$share',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),

            // Confirm Button
            AppButton(
              text: _isLoading ? 'Saving...' : 'Confirm Split & Recalculate',
              onPressed: _isLoading ? () {} : _handleConfirm,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _methodTab(String title, int index, bool isDark) {
    final isSelected = _splitMethod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AppSoundService.playSuccess();
          setState(() => _splitMethod = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? AppColors.cardDark : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }
}
