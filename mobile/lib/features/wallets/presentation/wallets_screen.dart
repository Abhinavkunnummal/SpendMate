import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/currency_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/delete_confirmation_dialog.dart';
import '../../../core/services/app_sound_service.dart';
import '../../../core/data/app_data_repository.dart';
import 'package:intl/intl.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallets, Cards & EMIs'),
        actions: [
          IconButton(
            tooltip: 'Add Account / Card',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showAddAccountSheet(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: AppDataRepository.instance,
        builder: (context, _) {
          final repo = AppDataRepository.instance;
          final allWallets = repo.wallets;
          final bankAccounts = allWallets.where((w) => !w.isCreditCard).toList();
          final creditCards = allWallets.where((w) => w.isCreditCard).toList();
          final emis = repo.emis;

          final bankLiquidity = repo.bankLiquidityPaise;
          final creditDebt = repo.totalCreditOutstandingPaise;
          final netWorth = repo.netWorthPaise;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Liquidity & Debt Breakdown Card (Clean separation: not mixed!)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF16A878)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.24),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL NET LIQUIDITY',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${NumberFormat('#,##,##0.00').format(netWorth / 100)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bank & Cash',
                                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${(bankLiquidity / 100).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 26, color: Colors.white.withOpacity(0.25)),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Credit Card Due',
                                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${(creditDebt / 100).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Color(0xFFFFD1D1),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION 1: BANK ACCOUNTS & DEBIT CARDS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('BANK ACCOUNTS & CASH (${bankAccounts.length})', style: AppTypography.labelSmall(secondaryTextColor)),
                    TextButton.icon(
                      onPressed: () => _showAddAccountSheet(context, defaultTab: 0),
                      icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                      label: Text('Add Bank', style: AppTypography.labelSmall(AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (bankAccounts.isEmpty)
                  _emptyCard('No bank accounts connected', 'Tap "+ Add Bank" to add your account with a manual balance.', primaryTextColor, secondaryTextColor)
                else
                  ...bankAccounts.map((w) {
                    IconData icon = Icons.account_balance_rounded;
                    Color color = AppColors.primary;
                    if (w.type == 'cash') {
                      icon = Icons.payments_rounded;
                      color = AppColors.orange;
                    }

                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(icon, color: color, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  w.name,
                                  style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${w.type.toUpperCase()} · •••• ${w.accountNumberLast4}',
                                  style: AppTypography.bodySmall(secondaryTextColor),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CurrencyText(
                                amountPaise: w.balancePaise,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _confirmDeleteWallet(context, w),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: AppColors.coral, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 24),

                // SECTION 2: CREDIT CARDS & BILLING DATES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('CREDIT CARDS (${creditCards.length})', style: AppTypography.labelSmall(secondaryTextColor)),
                    TextButton.icon(
                      onPressed: () => _showAddAccountSheet(context, defaultTab: 1),
                      icon: const Icon(Icons.add, size: 16, color: AppColors.coral),
                      label: Text('Add Card', style: AppTypography.labelSmall(AppColors.coral)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (creditCards.isEmpty)
                  _emptyCard('No credit cards added', 'Track credit limits, amount to pay, and monthly due dates.', primaryTextColor, secondaryTextColor)
                else
                  ...creditCards.map((card) {
                    final availableLimit = card.limitPaise - card.outstandingPaise;
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.coral.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.credit_card_rounded, color: AppColors.coral, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      card.name,
                                      style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '•••• ${card.accountNumberLast4} · Due ${card.dueDate ?? '18th of month'}',
                                      style: AppTypography.bodySmall(secondaryTextColor),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 20),
                                onPressed: () => _confirmDeleteWallet(context, card),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('AMOUNT TO PAY', style: TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${(card.outstandingPaise / 100).toStringAsFixed(0)}',
                                    style: const TextStyle(color: AppColors.coral, fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('AVAILABLE LIMIT', style: TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${(availableLimit / 100).toStringAsFixed(0)} / ₹${(card.limitPaise / 100).toStringAsFixed(0)}',
                                    style: TextStyle(color: primaryTextColor, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 24),

                // SECTION 3: EMI & LOAN TRACKER WITH REMINDERS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('EMIS & MONTHLY REMINDERS (${emis.length})', style: AppTypography.labelSmall(secondaryTextColor)),
                    TextButton.icon(
                      onPressed: () => _showAddEMISheet(context),
                      icon: const Icon(Icons.add, size: 16, color: AppColors.blue),
                      label: Text('Add EMI', style: AppTypography.labelSmall(AppColors.blue)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (emis.isEmpty)
                  _emptyCard('No active EMIs', 'Track monthly loan installments, due days, and final payment dates.', primaryTextColor, secondaryTextColor)
                else
                  ...emis.map((emi) {
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  emi.title,
                                  style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 18),
                                onPressed: () => _confirmDeleteEMI(context, emi),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${(emi.monthlyAmountPaise / 100).toStringAsFixed(0)} / month · ${emi.remainingMonths} mo left',
                                style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              StatusBadge(
                                label: 'Due ${emi.dueDate}',
                                color: AppColors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Last Date: ${DateFormat('dd MMM yyyy').format(emi.lastDate)}',
                                style: AppTypography.bodySmall(secondaryTextColor),
                              ),
                              Row(
                                children: [
                                  Text(
                                    emi.reminderEnabled ? 'Reminder On' : 'Reminder Off',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: emi.reminderEnabled ? AppColors.primary : secondaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Switch(
                                    value: emi.reminderEnabled,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) {
                                      AppSoundService.playSuccess();
                                      repo.toggleEMIReminder(emi.id);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 28),

                AppButton(
                  text: '+ Add New Account / Card / EMI',
                  onPressed: () => _showAddAccountSheet(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyCard(String title, String subtitle, Color primaryColor, Color secondaryColor) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Text(title, style: AppTypography.titleMedium(primaryColor).copyWith(fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: AppTypography.bodySmall(secondaryColor)),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteWallet(BuildContext context, WalletModelItem wallet) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      title: 'Delete ${wallet.name}?',
      message: 'Really want to delete this ${wallet.isCreditCard ? 'credit card' : 'bank account'}? This will remove its recorded balance and history.',
    );

    if (confirmed) {
      await AppDataRepository.instance.deleteWallet(wallet.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${wallet.name} deleted successfully!'),
            backgroundColor: AppColors.coral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmDeleteEMI(BuildContext context, EMIModelItem emi) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      title: 'Delete EMI Tracker?',
      message: 'Really want to delete "${emi.title}"? Your installment tracking and reminder will be removed.',
    );

    if (confirmed) {
      await AppDataRepository.instance.deleteEMI(emi.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${emi.title} deleted successfully!'),
            backgroundColor: AppColors.coral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddAccountSheet(BuildContext context, {int defaultTab = 0}) {
    int selectedTab = defaultTab; // 0: Bank, 1: Credit Card, 2: Debit/Cash
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: '10000');
    final limitCtrl = TextEditingController(text: '50000');
    final dueCtrl = TextEditingController(text: '18th');
    final last4Ctrl = TextEditingController(text: '1234');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Financial Account', style: AppTypography.titleLarge(AppColors.textPrimaryLight)),
                const SizedBox(height: 14),

                // Account Type Selector
                Row(
                  children: [
                    _typePill('Bank Account', 0, selectedTab, () => setModalState(() => selectedTab = 0)),
                    const SizedBox(width: 8),
                    _typePill('Credit Card', 1, selectedTab, () => setModalState(() => selectedTab = 1)),
                    const SizedBox(width: 8),
                    _typePill('Cash / Debit', 2, selectedTab, () => setModalState(() => selectedTab = 2)),
                  ],
                ),
                const SizedBox(height: 18),

                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: selectedTab == 1 ? 'Card Name (e.g. HDFC Regalia)' : 'Account Name (e.g. SBI Savings)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                if (selectedTab != 1) ...[
                  TextField(
                    controller: balanceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Manual Initial Balance (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: limitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Credit Limit (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: balanceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Current Amount to Pay / Outstanding (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: dueCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Due Date (e.g. 18th of month)',
                      hintText: 'e.g. 18th of every month',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                TextField(
                  controller: last4Ctrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Last 4 Digits of Account / Card',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;

                      final numVal = int.tryParse(balanceCtrl.text.trim()) ?? 0;
                      final type = selectedTab == 1 ? 'credit_card' : (selectedTab == 2 ? 'cash' : 'bank');
                      final limitNum = int.tryParse(limitCtrl.text.trim()) ?? 50000;

                      await AppDataRepository.instance.addWallet(
                        name: name,
                        type: type,
                        balancePaise: selectedTab == 1 ? (limitNum - numVal) * 100 : numVal * 100,
                        accountNumberLast4: last4Ctrl.text.trim().isNotEmpty ? last4Ctrl.text.trim() : '0000',
                        limitPaise: limitNum * 100,
                        outstandingPaise: selectedTab == 1 ? numVal * 100 : 0,
                        dueDate: dueCtrl.text.trim(),
                      );

                      AppSoundService.playIncomeChime();

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name added successfully!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Save Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddEMISheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final monthlyCtrl = TextEditingController(text: '5000');
    final totalCtrl = TextEditingController(text: '60000');
    final monthsCtrl = TextEditingController(text: '12');
    final dueCtrl = TextEditingController(text: '5th of month');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Track New EMI Loan', style: AppTypography.titleLarge(AppColors.textPrimaryLight)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'EMI Item (e.g. iPhone 16 Pro EMI)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: monthlyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monthly Installment (₹)', prefixText: '₹ ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: totalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Loan Principal (₹)', prefixText: '₹ ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: monthsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Months Left', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: dueCtrl,
                      decoration: const InputDecoration(labelText: 'Due Day (e.g. 5th)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;

                    final monthlyNum = int.tryParse(monthlyCtrl.text.trim()) ?? 5000;
                    final totalNum = int.tryParse(totalCtrl.text.trim()) ?? 60000;
                    final months = int.tryParse(monthsCtrl.text.trim()) ?? 12;

                    await AppDataRepository.instance.addEMI(
                      title: title,
                      monthlyAmountPaise: monthlyNum * 100,
                      totalAmountPaise: totalNum * 100,
                      remainingMonths: months,
                      linkedCardOrBank: 'Primary Bank',
                      dueDate: dueCtrl.text.trim(),
                      lastDate: DateTime.now().add(Duration(days: months * 30)),
                    );

                    AppSoundService.playIncomeChime();

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('EMI "$title" added successfully!'), backgroundColor: AppColors.blue),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
                  child: const Text('Add EMI & Set Reminder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typePill(String title, int index, int selectedTab, VoidCallback onTap) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondaryLight,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
