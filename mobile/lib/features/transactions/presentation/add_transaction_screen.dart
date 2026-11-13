import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
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
  final _friendNameController = TextEditingController(text: 'Rahul');

  String _selectedCategory = 'Food & Dining';
  String _selectedWallet = 'Primary Bank Account';
  bool _isLoading = false;

  final String _pattOptionName = 'Friend / Patt Book (IOU Ledger)';

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
    _friendNameController.dispose();
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
    final parsedAmount = double.tryParse(amountText);

    // Form Validations
    if (amountText.isEmpty || parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than ₹0')),
      );
      return;
    }

    final title = _descriptionController.text.trim().isNotEmpty
        ? _descriptionController.text.trim()
        : _selectedCategory;

    setState(() => _isLoading = true);
    final amountPaise = (parsedAmount * 100).toInt();

    if (_selectedWallet == _pattOptionName) {
      // Save directly to Patt Book without mixing with personal bank accounts!
      final friend = _friendNameController.text.trim();
      if (friend.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter friend name for Patt Book entry')),
        );
        return;
      }

      await AppDataRepository.instance.addPattEntry(
        friendName: friend,
        amountPaise: amountPaise,
        youGave: _isExpense, // Expense = you gave to/for friend (Kittan ullath)
        note: title,
        date: DateTime.now(),
      );

      AppSoundService.playIncomeChime();

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recorded in Patt Book for $friend! Kept separate from bank balance.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
      return;
    }

    // Normal Transaction
    await AppDataRepository.instance.addTransaction(
      title: title,
      amountPaise: amountPaise,
      isExpense: _isExpense,
      category: _selectedCategory,
      wallet: _selectedWallet,
    );

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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    walletNames.add(_pattOptionName);

    if (!walletNames.contains(_selectedWallet)) {
      _selectedWallet = walletNames.first;
    }

    final isPattSelected = _selectedWallet == _pattOptionName;
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
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _isExpense ? 'How much did you spend?' : 'How much did you receive?',
                      style: AppTypography.bodySmall(secondaryTextColor),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        const SizedBox(width: 4),
                        IntrinsicWidth(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 42,
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
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'In-App Fast Calculator',
                          icon: Icon(Icons.calculate_rounded, color: themeAccentColor, size: 26),
                          onPressed: _openCalculator,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Description / Merchant Input
              Text('DESCRIPTION / NOTE', style: AppTypography.labelSmall(secondaryTextColor)),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Blue Tokai Coffee, Uber to Office',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Category Selector
              Text('CATEGORY', style: AppTypography.labelSmall(secondaryTextColor)),
              const SizedBox(height: 10),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['name'];
                    final color = cat['color'] as Color;

                    return GestureDetector(
                      onTap: () {
                        AppSoundService.playSuccess();
                        setState(() => _selectedCategory = cat['name'] as String);
                      },
                      child: Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.18)
                              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat['icon'] as IconData, color: isSelected ? color : secondaryTextColor, size: 24),
                            const SizedBox(height: 6),
                            Text(
                              cat['name'] as String,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
                      final isPatt = wName == _pattOptionName;
                      final walletObj = repoWallets.cast<WalletModelItem?>().firstWhere(
                        (item) => item?.name == wName,
                        orElse: () => null,
                      );
                      IconData wIcon = Icons.account_balance_rounded;
                      if (isPatt) {
                        wIcon = Icons.menu_book_rounded;
                      } else if (walletObj?.type == 'cash') {
                        wIcon = Icons.payments_rounded;
                      } else if (walletObj?.isCreditCard == true) {
                        wIcon = Icons.credit_card_rounded;
                      }

                      return DropdownMenuItem<String>(
                        value: wName,
                        child: Row(
                          children: [
                            Icon(wIcon, size: 20, color: isPatt ? Colors.orange : themeAccentColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                wName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleMedium(primaryTextColor).copyWith(
                                  fontSize: 14,
                                  fontWeight: isPatt ? FontWeight.w700 : FontWeight.w500,
                                  color: isPatt ? Colors.orange : primaryTextColor,
                                ),
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
              const SizedBox(height: 16),

              // Friend Name Field when "Friend / Patt Book" is chosen!
              if (isPattSelected) ...[
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.handshake_outlined, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Patt Book Friend Details',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.orange),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'This will be recorded directly into your Patt Book and will NOT affect your personal bank balance.',
                        style: AppTypography.bodySmall(secondaryTextColor).copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _friendNameController,
                        decoration: const InputDecoration(
                          labelText: 'Friend Name',
                          hintText: 'e.g. Rahul, Sneha, Arun',
                          prefixIcon: Icon(Icons.person_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Existing Friends chips
                      if (AppDataRepository.instance.pattFriends.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          children: AppDataRepository.instance.pattFriends.take(4).map((f) {
                            return ActionChip(
                              label: Text(f, style: const TextStyle(fontSize: 11)),
                              onPressed: () => setState(() => _friendNameController.text = f),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 12),

              // Save Button
              AppButton(
                text: _isLoading
                    ? 'Saving...'
                    : (isPattSelected
                        ? 'Save to Patt Book (Friend Ledger)'
                        : (_isExpense ? 'Save Expense' : 'Save Income')),
                icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                onPressed: _isLoading ? () {} : _handleSave,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeTab(String title, bool isExpense, bool isDark, Color activeColor) {
    final isSelected = _isExpense == isExpense;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AppSoundService.playSuccess();
          setState(() => _isExpense = isExpense);
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
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeColor : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }
}
