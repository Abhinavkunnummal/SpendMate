import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();

  final List<String> _filters = ['All', 'Expenses', 'Income', 'Transfers'];

  final List<Map<String, dynamic>> _mockTransactions = [
    {
      'id': 'tx-101',
      'title': 'Blue Tokai Coffee Roasters',
      'category': 'Food & Dining',
      'wallet': 'HDFC Bank',
      'amountPaise': 48000,
      'isExpense': true,
      'dateGroup': 'Today',
      'time': '10:30 AM',
      'icon': Icons.restaurant_rounded,
    },
    {
      'id': 'tx-102',
      'title': 'Uber Premier Ride',
      'category': 'Transport',
      'wallet': 'Google Pay',
      'amountPaise': 42000,
      'isExpense': true,
      'dateGroup': 'Today',
      'time': '08:45 AM',
      'icon': Icons.directions_car_filled_rounded,
    },
    {
      'id': 'tx-103',
      'title': 'Client Milestone Payment',
      'category': 'Freelance',
      'wallet': 'HDFC Bank',
      'amountPaise': 4500000,
      'isExpense': false,
      'dateGroup': 'Yesterday',
      'time': '04:15 PM',
      'icon': Icons.work_outline_rounded,
    },
    {
      'id': 'tx-104',
      'title': 'Whole Foods Market',
      'category': 'Groceries',
      'wallet': 'ICICI Credit Card',
      'amountPaise': 235000,
      'isExpense': true,
      'dateGroup': 'Yesterday',
      'time': '12:20 PM',
      'icon': Icons.shopping_basket_rounded,
    },
    {
      'id': 'tx-105',
      'title': 'Apple Store Purchase',
      'category': 'Electronics',
      'wallet': 'ICICI Credit Card',
      'amountPaise': 890000,
      'isExpense': true,
      'dateGroup': '11 Nov 2026',
      'time': '02:40 PM',
      'icon': Icons.shopping_bag_outlined,
    },
    {
      'id': 'tx-106',
      'title': 'HP Auto Fuel',
      'category': 'Transport',
      'wallet': 'Cash',
      'amountPaise': 250000,
      'isExpense': true,
      'dateGroup': '10 Nov 2026',
      'time': '08:10 PM',
      'icon': Icons.local_gas_station_rounded,
    },
  ];

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

    final filteredList = _mockTransactions.where((item) {
      if (_selectedFilter == 'Expenses' && !item['isExpense']) return false;
      if (_selectedFilter == 'Income' && item['isExpense']) return false;
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        final matchTitle = item['title'].toString().toLowerCase().contains(query);
        final matchCategory = item['category'].toString().toLowerCase().contains(query);
        return matchTitle || matchCategory;
      }
      return true;
    }).toList();

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

          // Transactions List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final tx = filteredList[index];
                final showHeader = index == 0 || tx['dateGroup'] != filteredList[index - 1]['dateGroup'];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0, bottom: 8.0, left: 4.0),
                        child: Text(
                          tx['dateGroup'],
                          style: AppTypography.labelSmall(secondaryTextColor),
                        ),
                      ),
                    ],
                    AppCard(
                      onTap: () => context.push('/transactions/${tx['id']}'),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: tx['isExpense'] ? AppColors.coralLight : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              tx['icon'] as IconData,
                              size: 20,
                              color: tx['isExpense'] ? AppColors.coral : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx['title'],
                                  style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${tx['category']} · ${tx['wallet']} · ${tx['time']}',
                                  style: AppTypography.bodySmall(secondaryTextColor),
                                ),
                              ],
                            ),
                          ),
                          CurrencyText(
                            amountPaise: tx['amountPaise'] as int,
                            isExpense: tx['isExpense'] as bool,
                            isIncome: !(tx['isExpense'] as bool),
                            showSign: true,
                            fontSize: 15,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
