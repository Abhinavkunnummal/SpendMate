import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../core/data/app_data_repository.dart';
import '../../../core/services/app_sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/quick_calculator_sheet.dart';

class AddGroupExpenseScreen extends StatefulWidget {
  final String tripId;
  const AddGroupExpenseScreen({super.key, required this.tripId});

  @override
  State<AddGroupExpenseScreen> createState() => _AddGroupExpenseScreenState();
}

class _AddGroupExpenseScreenState extends State<AddGroupExpenseScreen> {
  final _amountController = TextEditingController(text: '1200');
  final _descriptionController = TextEditingController(text: 'Petrol / Fuel Refill');

  // Multi-Payer State
  bool _isMultiPayer = false;
  String _singlePayer = '';
  final Map<String, TextEditingController> _payerControllers = {};

  final List<String> _quickCategories = [
    'Petrol & Fuel',
    'Hotel / Resort',
    'Food & Dining',
    'Sightseeing & Tickets',
    'Cab / Transportation',
    'Snacks & Drinks',
    'Groceries / Cooking',
    'Activities & Sports',
  ];

  @override
  void initState() {
    super.initState();
    _initMembers();
  }

  void _initMembers() {
    final tripList = AppDataRepository.instance.trips;
    final trip = tripList.cast<TripModelItem?>().firstWhere(
      (t) => t?.id == widget.tripId,
      orElse: () => null,
    );

    final myName = AuthSessionManager.instance.displayName;
    final members = (trip != null && trip.members.isNotEmpty)
        ? trip.members
        : [myName, 'Friend 1'];

    _singlePayer = members.first;

    for (var m in members) {
      _payerControllers[m] = TextEditingController(
        text: m == _singlePayer ? _amountController.text : '0',
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    for (var c in _payerControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _calculatePaidSum() {
    if (!_isMultiPayer) {
      return int.tryParse(_amountController.text.trim()) ?? 0;
    }
    int sum = 0;
    for (var c in _payerControllers.values) {
      final val = int.tryParse(c.text.trim()) ?? 0;
      sum += val;
    }
    return sum;
  }

  void _handleSave() async {
    final title = _descriptionController.text.trim();
    final amountText = _amountController.text.trim();
    final totalAmount = int.tryParse(amountText) ?? 0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an expense title / item name')),
      );
      return;
    }

    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than ₹0')),
      );
      return;
    }

    if (_isMultiPayer) {
      final paidSum = _calculatePaidSum();
      if (paidSum != totalAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contributions sum (₹$paidSum) must match total amount (₹$totalAmount)'),
            backgroundColor: AppColors.coral,
          ),
        );
        return;
      }

      // Add multi-payer entries
      for (var entry in _payerControllers.entries) {
        final amt = int.tryParse(entry.value.text.trim()) ?? 0;
        if (amt > 0) {
          await AppDataRepository.instance.addTripExpense(
            tripId: widget.tripId,
            title: '$title (${entry.key})',
            amountPaise: amt * 100,
            paidBy: entry.key,
          );
        }
      }
    } else {
      await AppDataRepository.instance.addTripExpense(
        tripId: widget.tripId,
        title: title,
        amountPaise: totalAmount * 100,
        paidBy: _singlePayer,
      );
    }

    AppSoundService.playIncomeChime();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip expense "$title" of ₹$totalAmount saved successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final targetAmount = int.tryParse(_amountController.text.trim()) ?? 0;
    final currentPaidSum = _calculatePaidSum();
    final isMatching = currentPaidSum == targetAmount;

    final tripList = AppDataRepository.instance.trips;
    final trip = tripList.cast<TripModelItem?>().firstWhere(
      (t) => t?.id == widget.tripId,
      orElse: () => null,
    );
    final members = (trip != null && trip.members.isNotEmpty)
        ? trip.members
        : [AuthSessionManager.instance.displayName];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Trip Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Fast Calculator',
            onPressed: () async {
              final currentVal = double.tryParse(_amountController.text.trim()) ?? 0;
              final result = await QuickCalculatorSheet.show(context, initialValue: currentVal);
              if (result != null) {
                setState(() {
                  _amountController.text = result.toStringAsFixed(0);
                  if (!_isMultiPayer && _payerControllers.containsKey(_singlePayer)) {
                    _payerControllers[_singlePayer]!.text = result.toStringAsFixed(0);
                  }
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Hero Input
            Center(
              child: Column(
                children: [
                  Text('Total Expense Amount', style: AppTypography.bodySmall(secondaryTextColor)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '₹',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            setState(() {
                              if (!_isMultiPayer && _payerControllers.containsKey(_singlePayer)) {
                                _payerControllers[_singlePayer]!.text = val;
                              }
                            });
                          },
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: primaryTextColor),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            filled: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.calculate_rounded, color: AppColors.primary, size: 26),
                        tooltip: 'Calculate Expense',
                        onPressed: () async {
                          final currentVal = double.tryParse(_amountController.text.trim()) ?? 0;
                          final result = await QuickCalculatorSheet.show(context, initialValue: currentVal);
                          if (result != null) {
                            setState(() {
                              _amountController.text = result.toStringAsFixed(0);
                              if (!_isMultiPayer && _payerControllers.containsKey(_singlePayer)) {
                                _payerControllers[_singlePayer]!.text = result.toStringAsFixed(0);
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Item Name / Description
            Text('ITEM OR EXPENSE NAME', style: AppTypography.labelSmall(secondaryTextColor)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'e.g. Petrol for car, Hotel booking, Dinner bill',
                prefixIcon: Icon(Icons.receipt_long_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Quick Category Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _quickCategories.take(6).map((cat) {
                return ActionChip(
                  label: Text(cat, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() => _descriptionController.text = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Who Paid Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('WHO PAID FOR THIS?', style: AppTypography.labelSmall(secondaryTextColor)),
                Row(
                  children: [
                    Text('Multiple Payers', style: AppTypography.bodySmall(primaryTextColor)),
                    Switch.adaptive(
                      value: _isMultiPayer,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _isMultiPayer = val;
                          if (!val && _payerControllers.containsKey(_singlePayer)) {
                            _payerControllers[_singlePayer]!.text = _amountController.text;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (!_isMultiPayer) ...[
              // Single Payer Dropdown (Using REAL Trip Members!)
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: members.contains(_singlePayer) ? _singlePayer : members.first,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded),
                    dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                    items: members.map((m) {
                      final isYou = m.contains('You') || m == AuthSessionManager.instance.displayName;
                      return DropdownMenuItem<String>(
                        value: m,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                m.isNotEmpty ? m[0].toUpperCase() : 'M',
                                style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isYou ? '$m (You)' : m,
                                style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _singlePayer = val;
                          if (_payerControllers.containsKey(val)) {
                            _payerControllers[val]!.text = _amountController.text;
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
            ] else ...[
              // Multi-Payer Breakdown (Using REAL Trip Members!)
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: members.map((member) {
                    if (!_payerControllers.containsKey(member)) {
                      _payerControllers[member] = TextEditingController(text: '0');
                    }
                    final ctrl = _payerControllers[member]!;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              member.isNotEmpty ? member[0].toUpperCase() : 'M',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              member,
                              style: AppTypography.bodyMedium(primaryTextColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            height: 40,
                            child: TextField(
                              controller: ctrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              onChanged: (_) => setState(() {}),
                              style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                filled: true,
                                fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              // Multi-Payer Validation Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isMatching ? AppColors.primaryLight : AppColors.coralLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isMatching ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 16,
                      color: isMatching ? AppColors.primary : AppColors.coral,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isMatching
                            ? 'Contributions match ₹$targetAmount'
                            : 'Paid ₹$currentPaidSum of ₹$targetAmount (Difference: ₹${(targetAmount - currentPaidSum).abs()})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isMatching ? AppColors.primary : AppColors.coral,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Save Button
            AppButton(
              text: 'Save Trip Expense',
              icon: const Icon(Icons.check_rounded, size: 20),
              onPressed: _handleSave,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
