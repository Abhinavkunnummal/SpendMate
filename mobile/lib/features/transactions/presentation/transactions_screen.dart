import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/widgets/delete_confirmation_dialog.dart';
import '../../../core/services/app_sound_service.dart';
import '../../../core/data/app_data_repository.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedTypeFilter = 'All'; // 'All', 'Expenses', 'Income'
  final _searchController = TextEditingController();
  DateTime? _selectedDate; // null means "All Days"

  final List<String> _typeFilters = ['All', 'Expenses', 'Income'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _confirmDelete(BuildContext context, TransactionModel tx) async {
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
            content: Text('Transaction "${tx.title}" deleted successfully!'),
            backgroundColor: AppColors.coral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        title: const Text('All Transactions'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Record Transaction',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => context.push('/add-transaction'),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: AppDataRepository.instance,
        builder: (context, _) {
          final repo = AppDataRepository.instance;
          final allTxs = repo.transactions;

          // Days strip (Past 14 days)
          final today = DateTime.now();
          final daysList = List.generate(14, (i) => today.subtract(Duration(days: i)));

          // Filter by selected date
          List<TransactionModel> dateFiltered = allTxs;
          if (_selectedDate != null) {
            dateFiltered = allTxs.where((t) => _isSameDay(t.date, _selectedDate!)).toList();
          }

          // Filter by Expense/Income and Search Query
          final finalFilteredList = dateFiltered.where((tx) {
            if (_selectedTypeFilter == 'Expenses' && !tx.isExpense) return false;
            if (_selectedTypeFilter == 'Income' && tx.isExpense) return false;
            if (_searchController.text.isNotEmpty) {
              final query = _searchController.text.toLowerCase();
              return tx.title.toLowerCase().contains(query) ||
                  tx.category.toLowerCase().contains(query);
            }
            return true;
          }).toList();

          // Calculate Day Summary stats for the active view
          final activeSummary = _selectedDate != null
              ? repo.getDaySummary(_selectedDate!)
              : {
                  'totalExpensePaise': repo.totalSpentPaise,
                  'totalIncomePaise': repo.totalIncomePaise,
                  'topExpense': allTxs.where((t) => t.isExpense).fold<TransactionModel?>(null, (prev, curr) => prev == null || curr.amountPaise > prev.amountPaise ? curr : prev),
                  'topIncome': allTxs.where((t) => !t.isExpense).fold<TransactionModel?>(null, (prev, curr) => prev == null || curr.amountPaise > prev.amountPaise ? curr : prev),
                };

          final topExpense = activeSummary['topExpense'] as TransactionModel?;
          final topIncome = activeSummary['topIncome'] as TransactionModel?;
          final totalExp = activeSummary['totalExpensePaise'] as int;
          final totalInc = activeSummary['totalIncomePaise'] as int;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search payees, items, or categories...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _searchController.clear()),
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                  ),
                ),
              ),

              // Calendar Strip with Daily Spend Indicators
              Padding(
                padding: const EdgeInsets.only(left: 20.0, top: 4.0, bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('CALENDAR DAYS & DAILY SPEND', style: AppTypography.labelSmall(secondaryTextColor)),
                    if (_selectedDate != null)
                      TextButton(
                        onPressed: () => setState(() => _selectedDate = null),
                        child: const Text('Show All Days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ),
                  ],
                ),
              ),

              SizedBox(
                height: 74,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: daysList.length,
                  itemBuilder: (context, idx) {
                    final dayDate = daysList[idx];
                    final isSelected = _selectedDate != null && _isSameDay(_selectedDate!, dayDate);
                    final daySummary = repo.getDaySummary(dayDate);
                    final daySpent = daySummary['totalExpensePaise'] as int;
                    final dayIncome = daySummary['totalIncomePaise'] as int;

                    String spendText = '—';
                    Color spendColor = secondaryTextColor;
                    if (daySpent > 0) {
                      spendText = '-₹${(daySpent / 100).toStringAsFixed(0)}';
                      spendColor = AppColors.coral;
                    } else if (dayIncome > 0) {
                      spendText = '+₹${(dayIncome / 100).toStringAsFixed(0)}';
                      spendColor = AppColors.primary;
                    }

                    final dayLabel = idx == 0 ? 'Today' : (idx == 1 ? 'Yest.' : DateFormat('E').format(dayDate));
                    final dateNum = DateFormat('d MMM').format(dayDate);

                    return GestureDetector(
                      onTap: () {
                        AppSoundService.playSuccess();
                        setState(() {
                          if (isSelected) {
                            _selectedDate = null;
                          } else {
                            _selectedDate = dayDate;
                          }
                        });
                      },
                      child: Container(
                        width: 68,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.cardDark : AppColors.cardLight),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateNum,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              spendText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white70 : spendColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Daily Top Expense & Top Income Highlight Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Top Expense
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.coral.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_upward_rounded, color: AppColors.coral, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    topExpense != null ? topExpense.title : 'Top Expense',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryTextColor),
                                  ),
                                  Text(
                                    topExpense != null
                                        ? '₹${(topExpense.amountPaise / 100).toStringAsFixed(0)}'
                                        : (totalExp > 0 ? '₹${(totalExp / 100).toStringAsFixed(0)}' : '₹0'),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.coral),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 30, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      const SizedBox(width: 10),

                      // Top Income
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_downward_rounded, color: AppColors.primary, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    topIncome != null ? topIncome.title : 'Top Income',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryTextColor),
                                  ),
                                  Text(
                                    topIncome != null
                                        ? '₹${(topIncome.amountPaise / 100).toStringAsFixed(0)}'
                                        : (totalInc > 0 ? '₹${(totalInc / 100).toStringAsFixed(0)}' : '₹0'),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Chips (All / Expenses / Income)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Row(
                  children: _typeFilters.map((filter) {
                    final isSelected = _selectedTypeFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedTypeFilter = filter);
                        },
                        selectedColor: filter == 'Expenses'
                            ? AppColors.coral
                            : (filter == 'Income' ? AppColors.primary : AppColors.primary),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : secondaryTextColor,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Transactions List
              Expanded(
                child: finalFilteredList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 50, color: secondaryTextColor),
                              const SizedBox(height: 12),
                              Text(
                                _selectedDate != null
                                    ? 'No transactions on ${DateFormat('dd MMM').format(_selectedDate!)}'
                                    : 'No transactions found',
                                style: AppTypography.titleMedium(primaryTextColor),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap "+" to record expenses or income.',
                                style: AppTypography.bodySmall(secondaryTextColor),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        itemCount: finalFilteredList.length,
                        itemBuilder: (context, index) {
                          final tx = finalFilteredList[index];
                          final timeStr = DateFormat('h:mm a').format(tx.date);
                          final dateStr = DateFormat('dd MMM yyyy').format(tx.date);

                          return AppCard(
                            onTap: () => context.push('/transactions/${tx.id}'),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: tx.isExpense
                                        ? AppColors.coral.withOpacity(0.12)
                                        : AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    tx.icon,
                                    size: 22,
                                    color: tx.isExpense ? AppColors.coral : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.title,
                                        style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${tx.category} · ${tx.wallet} · $dateStr, $timeStr',
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () => context.push('/transactions/${tx.id}'),
                                          child: const Text(
                                            'Edit',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _confirmDelete(context, tx),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: AppColors.coral,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
