import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/data/app_data_repository.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();

  final List<String> _filters = ['All', 'Expenses', 'Income'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => context.push('/add-transaction'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search transactions or categories...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _searchController.clear()),
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedFilter = filter);
                          },
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Transactions List (Dynamic Real User Transactions)
          Expanded(
            child: ListenableBuilder(
              listenable: AppDataRepository.instance,
              builder: (context, _) {
                final realList = AppDataRepository.instance.transactions;
                final filteredList = realList.where((tx) {
                  if (_selectedFilter == 'Expenses' && !tx.isExpense) return false;
                  if (_selectedFilter == 'Income' && tx.isExpense) return false;
                  if (_searchController.text.isNotEmpty) {
                    final query = _searchController.text.toLowerCase();
                    return tx.title.toLowerCase().contains(query) ||
                        tx.category.toLowerCase().contains(query);
                  }
                  return true;
                }).toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 54, color: secondaryTextColor),
                          const SizedBox(height: 14),
                          Text('No transactions found', style: AppTypography.titleMedium(primaryTextColor)),
                          const SizedBox(height: 6),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'No results matching "${_searchController.text}"'
                                : 'Tap "+" above to add your first transaction',
                            style: AppTypography.bodySmall(secondaryTextColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final timeFormat = DateFormat('h:mm a');
                final dateFormat = DateFormat('dd MMM yyyy');

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final tx = filteredList[index];
                    final dateLabel = dateFormat.format(tx.date);
                    final showHeader = index == 0 ||
                        dateFormat.format(filteredList[index - 1].date) != dateLabel;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0, bottom: 8.0, left: 4.0),
                            child: Text(
                              dateLabel,
                              style: AppTypography.labelSmall(secondaryTextColor),
                            ),
                          ),
                        ],
                        AppCard(
                          onTap: () => context.push('/transactions/${tx.id}'),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: tx.isExpense ? AppColors.coralLight : AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  tx.icon,
                                  size: 20,
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
                                      style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tx.category} · ${tx.wallet} · ${timeFormat.format(tx.date)}',
                                      style: AppTypography.bodySmall(secondaryTextColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              CurrencyText(
                                amountPaise: tx.amountPaise,
                                isExpense: tx.isExpense,
                                isIncome: !tx.isExpense,
                                showSign: true,
                                fontSize: 15,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
