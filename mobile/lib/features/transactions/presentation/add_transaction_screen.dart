import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/quick_calculator_sheet.dart';
import '../../../core/services/app_sound_service.dart';
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
  String _selectedWallet = 'Primary Bank Account';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food & Dining', 'icon': Icons.restaurant_rounded, 'color': AppColors.coral},
    {'name': 'Movies & Cinema', 'icon': Icons.movie_creation_outlined, 'color': const Color(0xFFE11D48)},
    {'name': 'Travel & Trips', 'icon': Icons.flight_takeoff_rounded, 'color': AppColors.blue},
    {'name': 'Groceries', 'icon': Icons.shopping_basket_rounded, 'color': AppColors.primary},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_outlined, 'color': AppColors.orange},
    {'name': 'Bills & Utilities', 'icon': Icons.receipt_long_rounded, 'color': AppColors.purple},
    {'name': 'Transport & Fuel', 'icon': Icons.local_gas_station_rounded, 'color': const Color(0xFFF59E0B)},
    {'name': 'Gaming & Fun', 'icon': Icons.sports_esports_outlined, 'color': const Color(0xFF6366F1)},
    {'name': 'Health & Medical', 'icon': Icons.medical_services_outlined, 'color': const Color(0xFF10B981)},
    {'name': 'Education & Books', 'icon': Icons.school_outlined, 'color': const Color(0xFF0EA5E9)},
    {'name': 'Personal Care', 'icon': Icons.spa_outlined, 'color': const Color(0xFFEC4899)},
    {'name': 'Salary & Inflow', 'icon': Icons.payments_rounded, 'color': AppColors.primary},
    {'name': 'Investments', 'icon': Icons.trending_up_rounded, 'color': const Color(0xFF14B8A6)},
    {'name': 'Freelance / Gift', 'icon': Icons.card_giftcard_rounded, 'color': const Color(0xFF8B5CF6)},
  ];

  @override
  void initState() {
    super.initState();
    _isExpense = widget.initialType != 'income';
    final repoWallets = AppDataRepository.instance.wallets;
    if (repoWallets.isNotEmpty) {
      _selectedWallet = repoWallets.first.name;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _openCalculator() async {
    final currentVal = double.tryParse(_amountController.text.trim()) ?? 0;
    final result = await QuickCalculatorSheet.show(context, initialValue: currentVal);
    if (result != null) {
      setState(() {
        _amountController.text = result % 1 == 0
            ? result.toInt().toString()
            : result.toStringAsFixed(2);
      });
    }
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

    // Audio & Haptic Feedback (Google Pay style for income, distinct alert for spend)
    if (_isExpense) {
      AppSoundService.playExpenseAlert();
    } else {
      AppSoundService.playIncomeChime();
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_isExpense ? 'Expense' : 'Income'} of ₹$amountText added to $_selectedWallet!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: _isExpense ? AppColors.coral : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final repoWallets = AppDataRepository.instance.wallets;
    final walletNames = repoWallets.map((w) => w.name).toList();
    if (walletNames.isEmpty) {
      walletNames.add('Primary Bank Account');
    }
    if (!walletNames.contains(_selectedWallet)) {
      _selectedWallet = walletNames.first;
    }

    final themeAccentColor = _isExpense ? AppColors.coral : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isExpense ? 'Record Expense' : 'Record Income'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Fast Calculator',
            icon: const Icon(Icons.calculate_outlined, size: 22),
            onPressed: _openCalculator,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Toggle: Expense vs Income
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _typeTab('Expense (Spend)', true, isDark, AppColors.coral),
                    _typeTab('Income (Gain)', false, isDark, AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Amount Card with Fast Calculator Trigger
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: themeAccentColor.withOpacity(0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeAccentColor.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
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
                          _isExpense ? 'TOTAL EXPENDITURE' : 'INCOMING AMOUNT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: themeAccentColor,
                          ),
                        ),
                        InkWell(
                          onTap: _openCalculator,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: themeAccentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calculate_rounded, size: 14, color: themeAccentColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Calculator',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: themeAccentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '₹',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: themeAccentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '0.00',
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Description Field
              AppTextField(
                label: 'Description / Payee',
                hint: _isExpense ? 'e.g. Blue Tokai Coffee, PVR Movies' : 'e.g. Monthly Salary, Freelance project',
                controller: _descriptionController,
                prefixIcon: const Icon(Icons.edit_note_rounded),
              ),
              const SizedBox(height: 20),

              // Category Picker Section
              Text('CATEGORY', style: AppTypography.labelSmall(secondaryTextColor)),
              const SizedBox(height: 10),
              SizedBox(
                height: 96,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['name'];
                    final Color catColor = cat['color'];

                    return GestureDetector(
                      onTap: () {
                        AppSoundService.playSuccess();
                        setState(() => _selectedCategory = cat['name']);
                      },
                      child: Container(
                        width: 82,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catColor.withOpacity(0.18)
                              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? catColor : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat['icon'], color: isSelected ? catColor : secondaryTextColor, size: 26),
                            const SizedBox(height: 6),
                            Text(
                              cat['name'],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                color: isSelected ? primaryTextColor : secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Payment Wallet / Bank Account Selector
              Text('SELECT ACCOUNT / WALLET', style: AppTypography.labelSmall(secondaryTextColor)),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedWallet,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded),
                    dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                    items: walletNames.map((wName) {
                      final walletObj = repoWallets.cast<WalletModelItem?>().firstWhere(
                        (item) => item?.name == wName,
                        orElse: () => null,
                      );
                      IconData wIcon = Icons.account_balance_rounded;
                      if (walletObj?.type == 'cash') {
                        wIcon = Icons.payments_rounded;
                      } else if (walletObj?.isCreditCard == true) {
                        wIcon = Icons.credit_card_rounded;
                      }

                      return DropdownMenuItem<String>(
                        value: wName,
                        child: Row(
                          children: [
                            Icon(wIcon, size: 20, color: themeAccentColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                wName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                              ),
                            ),
                            if (walletObj != null)
                              Text(
                                walletObj.isCreditCard
                                    ? 'Due ₹${(walletObj.outstandingPaise / 100).toStringAsFixed(0)}'
                                    : '₹${(walletObj.balancePaise / 100).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryTextColor,
                                ),
                              ),
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

              // Optional Notes Field
              AppTextField(
                label: 'Notes / Tags (Optional)',
                hint: 'Add extra details, warranty, or reference #',
                controller: _notesController,
                prefixIcon: const Icon(Icons.note_alt_outlined),
              ),
              const SizedBox(height: 32),

              // Save Action Button
              AppButton(
                text: _isExpense ? 'Save Expense' : 'Save Income',
                isLoading: _isLoading,
                onPressed: _handleSave,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeTab(String title, bool isExpenseTab, bool isDark, Color activeColor) {
    final isSelected = _isExpense == isExpenseTab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AppSoundService.playSuccess();
          setState(() => _isExpense = isExpenseTab);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
