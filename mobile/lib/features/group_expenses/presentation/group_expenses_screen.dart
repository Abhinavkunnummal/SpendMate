import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../core/data/app_data_repository.dart';
import '../../../core/services/app_sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/delete_confirmation_dialog.dart';

class GroupExpensesScreen extends StatefulWidget {
  final String tripId;
  const GroupExpensesScreen({super.key, required this.tripId});

  @override
  State<GroupExpensesScreen> createState() => _GroupExpensesScreenState();
}

class _GroupExpensesScreenState extends State<GroupExpensesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedMember;
  String _sortOrder = 'newest'; // 'newest', 'amount_desc', 'amount_asc', 'name'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditExpenseDialog(BuildContext context, Map<String, dynamic> exp, List<String> members) {
    final titleController = TextEditingController(text: exp['title'] ?? '');
    final amountController = TextEditingController(
      text: ((exp['amountPaise'] as int? ?? 0) / 100).toStringAsFixed(0),
    );
    String selectedPayer = exp['paidBy'] ?? (members.isNotEmpty ? members.first : 'You');
    if (!members.contains(selectedPayer) && members.isNotEmpty) {
      selectedPayer = members.first;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Group Expense', style: AppTypography.titleLarge(primaryTextColor).copyWith(fontSize: 18)),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Expense Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ ', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPayer,
                  decoration: const InputDecoration(labelText: 'Paid By', border: OutlineInputBorder()),
                  items: members.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => selectedPayer = val);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final amt = int.tryParse(amountController.text.trim()) ?? 0;
                      if (title.isEmpty || amt <= 0) return;

                      await AppDataRepository.instance.updateTripExpense(
                        tripId: widget.tripId,
                        expenseId: exp['id'],
                        title: title,
                        amountPaise: amt * 100,
                        paidBy: selectedPayer,
                      );

                      AppSoundService.playIncomeChime();

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Expense "$title" updated!')),
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
          );
        },
      ),
    );
  }

  void _deleteExpense(Map<String, dynamic> exp) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      title: 'Delete Group Expense?',
      message: 'Really want to delete "${exp['title']}"? Group balances will be updated accordingly.',
    );

    if (confirmed) {
      await AppDataRepository.instance.deleteTripExpense(widget.tripId, exp['id']);
      AppSoundService.playExpenseAlert();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense "${exp['title']}" deleted successfully!'),
            backgroundColor: AppColors.coral,
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

    return ListenableBuilder(
      listenable: AppDataRepository.instance,
      builder: (context, _) {
        final tripList = AppDataRepository.instance.trips;
        final trip = tripList.cast<TripModelItem?>().firstWhere(
          (t) => t?.id == widget.tripId,
          orElse: () => null,
        );

        final expenses = trip?.expenses ?? [];
        final totalSpentPaise = trip?.spentPaise ?? 0;
        final members = (trip != null && trip.members.isNotEmpty)
            ? trip.members
            : [AuthSessionManager.instance.displayName];

        // Filtering Logic
        List<Map<String, dynamic>> filteredExpenses = List.from(expenses);

        if (_selectedMember != null && _selectedMember!.isNotEmpty) {
          filteredExpenses = filteredExpenses
              .where((e) => (e['paidBy'] as String? ?? '').toLowerCase() == _selectedMember!.toLowerCase())
              .toList();
        }

        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          filteredExpenses = filteredExpenses.where((e) {
            final title = (e['title'] as String? ?? '').toLowerCase();
            final paidBy = (e['paidBy'] as String? ?? '').toLowerCase();
            return title.contains(query) || paidBy.contains(query);
          }).toList();
        }

        // Sorting Logic
        if (_sortOrder == 'amount_desc') {
          filteredExpenses.sort((a, b) => ((b['amountPaise'] as num?)?.toInt() ?? 0).compareTo((a['amountPaise'] as num?)?.toInt() ?? 0));
        } else if (_sortOrder == 'amount_asc') {
          filteredExpenses.sort((a, b) => ((a['amountPaise'] as num?)?.toInt() ?? 0).compareTo((b['amountPaise'] as num?)?.toInt() ?? 0));
        } else if (_sortOrder == 'name') {
          filteredExpenses.sort((a, b) => (a['paidBy'] as String? ?? '').compareTo(b['paidBy'] as String? ?? ''));
        } else {
          // 'newest'
          filteredExpenses = filteredExpenses.reversed.toList();
        }

        final filteredTotalPaise = filteredExpenses.fold(0, (sum, e) => sum + ((e['amountPaise'] as num?)?.toInt() ?? 0));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Group Expenses'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () => context.push('/trips/${widget.tripId}/add-expense'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Expenditure Hero Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL GROUP SPENT',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${(totalSpentPaise / 100).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${expenses.length} shared items recorded across ${members.length} friends',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Search Bar with Clear Button
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by member or expense item...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty || _selectedMember != null
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _selectedMember = null;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // Member Filter Chips with Total Paid per Person
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _selectedMember == null,
                        label: Text('All (${expenses.length})'),
                        onSelected: (_) {
                          AppSoundService.playSuccess();
                          setState(() => _selectedMember = null);
                        },
                        selectedColor: AppColors.blue.withOpacity(0.2),
                      ),
                      const SizedBox(width: 8),
                      ...members.map((m) {
                        final memberTotal = expenses
                            .where((e) => (e['paidBy'] as String? ?? '').toLowerCase() == m.toLowerCase())
                            .fold(0, (sum, e) => sum + ((e['amountPaise'] as num?)?.toInt() ?? 0));
                        final isSelected = _selectedMember?.toLowerCase() == m.toLowerCase();

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            selected: isSelected,
                            avatar: CircleAvatar(
                              radius: 10,
                              backgroundColor: isSelected ? AppColors.blue : Colors.grey.shade300,
                              child: Text(
                                m.isNotEmpty ? m[0].toUpperCase() : 'M',
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            label: Text(
                              '$m (₹${(memberTotal / 100).toStringAsFixed(0)})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            selectedColor: AppColors.blue.withOpacity(0.25),
                            onSelected: (_) {
                              AppSoundService.playSuccess();
                              setState(() {
                                if (isSelected) {
                                  _selectedMember = null;
                                } else {
                                  _selectedMember = m;
                                }
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search & Filter Summary Banner
                if (_searchQuery.isNotEmpty || _selectedMember != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedMember != null
                                ? 'Total Paid by $_selectedMember: ₹${(filteredTotalPaise / 100).toStringAsFixed(0)}'
                                : 'Matches for "$_searchQuery": ₹${(filteredTotalPaise / 100).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.blue),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${filteredExpenses.length} items',
                          style: AppTypography.bodySmall(secondaryTextColor),
                        ),
                      ],
                    ),
                  ),

                // Expense List Header with Sort Option
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SHARED EXPENSES (${filteredExpenses.length})', style: AppTypography.labelSmall(secondaryTextColor)),
                    Row(
                      children: [
                        PopupMenuButton<String>(
                          icon: Row(
                            children: const [
                              Icon(Icons.sort_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('Sort', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          onSelected: (val) {
                            AppSoundService.playSuccess();
                            setState(() => _sortOrder = val);
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'newest',
                              child: Text('Newest First'),
                            ),
                            const PopupMenuItem(
                              value: 'amount_desc',
                              child: Text('Highest Amount (High -> Low)'),
                            ),
                            const PopupMenuItem(
                              value: 'amount_asc',
                              child: Text('Lowest Amount (Low -> High)'),
                            ),
                            const PopupMenuItem(
                              value: 'name',
                              child: Text('Sort by Payer Name'),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => context.push('/trips/${widget.tripId}/add-expense'),
                          icon: const Icon(Icons.add, size: 14, color: AppColors.primary),
                          label: Text('Add Item', style: AppTypography.labelSmall(AppColors.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (filteredExpenses.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: secondaryTextColor),
                          const SizedBox(height: 12),
                          Text(
                            expenses.isEmpty ? 'No group expenses added yet' : 'No expenses match search criteria',
                            style: AppTypography.titleMedium(primaryTextColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expenses.isEmpty
                                ? 'Tap "+ Add Item" to add petrol, food, or stays'
                                : 'Try searching with another member name or keyword',
                            style: AppTypography.bodySmall(secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredExpenses.map((exp) {
                    final title = exp['title'] ?? 'Expense';
                    final amountPaise = exp['amountPaise'] as int? ?? 0;
                    final paidBy = exp['paidBy'] ?? 'Friend';

                    return _groupExpenseCard(
                      title: title,
                      amountPaise: amountPaise,
                      paidByText: '$paidBy paid ₹${(amountPaise / 100).toStringAsFixed(0)}',
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      onEdit: () => _showEditExpenseDialog(context, exp, members),
                      onDelete: () => _deleteExpense(exp),
                    );
                  }),
                const SizedBox(height: 28),

                AppButton(
                  text: '+ Add Shared Expense',
                  onPressed: () => context.push('/trips/${widget.tripId}/add-expense'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _groupExpenseCard({
    required String title,
    required int amountPaise,
    required String paidByText,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.blue, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      paidByText,
                      style: AppTypography.bodySmall(secondaryTextColor).copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${(amountPaise / 100).toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onEdit,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 18),
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
