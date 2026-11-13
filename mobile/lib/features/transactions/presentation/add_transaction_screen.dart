import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/data/app_data_repository.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? initialType;
  const AddTransactionScreen({super.key, this.initialType});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late bool _isExpense;
  final _amountController = TextEditingController(text: '480');
  final _descriptionController = TextEditingController(text: 'Blue Tokai Coffee');
  final _notesController = TextEditingController();

  String _selectedCategory = 'Food & Dining';
  String _selectedWallet = 'HDFC Salary Account';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food & Dining', 'icon': Icons.restaurant_rounded, 'color': AppColors.coral},
    {'name': 'Travel & Trips', 'icon': Icons.flight_takeoff_rounded, 'color': AppColors.blue},
    {'name': 'Groceries', 'icon': Icons.shopping_basket_rounded, 'color': AppColors.primary},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_outlined, 'color': AppColors.orange},
    {'name': 'Bills & Utilities', 'icon': Icons.receipt_long_rounded, 'color': AppColors.purple},
    {'name': 'Transport', 'icon': Icons.local_gas_station_rounded, 'color': const Color(0xFFF59E0B)},
    {'name': 'Entertainment', 'icon': Icons.movie_outlined, 'color': const Color(0xFFEC4899)},
    {'name': 'Salary', 'icon': Icons.payments_rounded, 'color': AppColors.primary},
  ];

  final List<String> _wallets = [
    'HDFC Salary Account',
    'ICICI Credit Card',
    'Google Pay UPI',
    'Cash In Hand',
  ];

  @override
  void initState() {
    super.initState();
    _isExpense = widget.initialType != 'income';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final amountPaise = (double.parse(amountText) * 100).toInt();
    final title = _descriptionController.text.trim().isNotEmpty
        ? _descriptionController.text.trim()
        : _selectedCategory;

    await AppDataRepository.instance.addTransaction(
      title: title,
      amountPaise: amountPaise,
      isExpense: _isExpense,
      category: _selectedCategory,
      wallet: _selectedWallet,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_isExpense ? 'Expense' : 'Income'} of ₹$amountText added successfully!'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
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
        title: Text(_isExpense ? 'Add Expense' : 'Add Income'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Segmented Type Selector (Expense vs Income)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isExpense = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isExpense ? AppColors.coral : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Expense',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isExpense ? Colors.white : secondaryTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isExpense = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isExpense ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Income',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isExpense ? Colors.white : secondaryTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Hero Amount Input
            Text(
              'Enter Amount',
              style: AppTypography.bodySmall(secondaryTextColor),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: _isExpense ? AppColors.coral : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                      letterSpacing: -1,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Description / Merchant
            AppTextField(
              label: 'Merchant / Description',
              hint: 'e.g. Starbucks, Uber, Grocery',
              controller: _descriptionController,
              prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
            ),
            const SizedBox(height: 20),

            // Category Selector
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Category',
                style: AppTypography.labelSmall(secondaryTextColor),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (cat['color'] as Color).withOpacity(0.15)
                          : (isDark ? AppColors.cardDark : AppColors.cardLight),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? (cat['color'] as Color)
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat['icon'] as IconData, size: 16, color: cat['color'] as Color),
                        const SizedBox(width: 8),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? primaryTextColor : secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Wallet Selector
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Payment Account / Wallet',
                style: AppTypography.labelSmall(secondaryTextColor),
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedWallet,
                  isExpanded: true,
                  dropdownColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                  items: _wallets.map((w) {
                    return DropdownMenuItem<String>(
                      value: w,
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(w, style: AppTypography.bodyMedium(primaryTextColor)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedWallet = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Notes / Remarks
            AppTextField(
              label: 'Notes (Optional)',
              hint: 'Add any specific notes or tags...',
              controller: _notesController,
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Save Action CTA
            AppButton(
              text: _isExpense ? 'Save Expense' : 'Save Income',
              isLoading: _isLoading,
              onPressed: _handleSave,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
