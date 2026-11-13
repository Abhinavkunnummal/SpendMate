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

  final int _totalExpense = 560;

  final List<Map<String, dynamic>> _contributors = [
    {'name': 'Aarav Sharma', 'paid': 400},
    {'name': 'Rohan Mehra', 'paid': 160},
  ];

  late final List<Map<String, dynamic>> _participants;

  @override
  void initState() {
    super.initState();
    final myName = AuthSessionManager.instance.displayName;
    _participants = [
      {'name': 'Aarav Sharma', 'selected': true, 'share': 140, 'percent': 25},
      {'name': '$myName (You)', 'selected': true, 'share': 140, 'percent': 25},
      {'name': 'Rohan Mehra', 'selected': true, 'share': 140, 'percent': 25},
      {'name': 'Pooja Nair', 'selected': true, 'share': 140, 'percent': 25},
    ];
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
    await AppDataRepository.instance.addTripExpense(
      tripId: widget.tripId,
      title: 'Group Shared Expense',
      amountPaise: _totalExpense * 100,
      paidBy: 'Aarav Sharma',
    );
    AppSoundService.playIncomeChime();

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Split of ₹560 saved and group balances recalculated!'),
        backgroundColor: AppColors.primary,
      ),
    );
    // Navigate to Balances screen to see updated settlements!
    context.go('/trips/${widget.tripId}/balances');
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
            // Total & Contributors Summary Card
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL EXPENSE', style: AppTypography.labelSmall(secondaryTextColor)),
                      const StatusBadge(label: '₹560.00', color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text('PAID BY (CONTRIBUTORS)', style: AppTypography.labelSmall(secondaryTextColor)),
                  const SizedBox(height: 8),
                  ..._contributors.map((c) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    c['name'],
                                    style: AppTypography.bodyMedium(primaryTextColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Paid ₹${c['paid']}',
                            style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Split Method Selector
            Text('SPLIT METHOD', style: AppTypography.labelSmall(secondaryTextColor)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _splitMethodTab('Equally', 0, isDark, primaryTextColor, secondaryTextColor),
                  _splitMethodTab('Custom', 1, isDark, primaryTextColor, secondaryTextColor),
                  _splitMethodTab('Percentage', 2, isDark, primaryTextColor, secondaryTextColor),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Participants List & Individual Shares
            Text('PARTICIPANTS & SHARES', style: AppTypography.labelSmall(secondaryTextColor)),
            const SizedBox(height: 8),

            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: _participants.map((p) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: p['selected'],
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              p['selected'] = val ?? false;
                              _recalculateShares();
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            p['name'],
                            style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${p['share']}',
                              style: AppTypography.titleMedium(primaryTextColor).copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${p['percent']}% share',
                              style: AppTypography.bodySmall(secondaryTextColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // Confirmation Button
            AppButton(
              text: 'Confirm & Save Split (₹560)',
              isLoading: _isLoading,
              onPressed: _handleConfirm,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _splitMethodTab(String label, int index, bool isDark, Color primaryColor, Color secondaryColor) {
    final isSelected = _splitMethod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _splitMethod = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? AppColors.cardDark : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? primaryColor : secondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
