import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/data/app_data_repository.dart';
import '../../../core/services/app_sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/delete_confirmation_dialog.dart';

/// Dedicated Patt Book (കടം / പറ്റ് ബുക്ക് / IOU Ledger) Screen.
/// Manages debts, lendings, and borrowings with friends.
/// Strictly separated from personal bank balances and monthly expense calculations.
class PattBookScreen extends StatefulWidget {
  const PattBookScreen({super.key});

  @override
  State<PattBookScreen> createState() => _PattBookScreenState();
}

class _PattBookScreenState extends State<PattBookScreen> {
  int _selectedFilter = 0; // 0: All, 1: You Will Get, 2: You Will Give

  void _showAddEditEntrySheet(BuildContext context, {PattEntryItem? editEntry, String? defaultFriend}) {
    final isEditing = editEntry != null;
    final friendController = TextEditingController(text: editEntry?.friendName ?? defaultFriend ?? '');
    final phoneController = TextEditingController(text: editEntry?.friendPhone ?? '');
    final amountController = TextEditingController(
      text: editEntry != null ? (editEntry.amountPaise / 100).toStringAsFixed(0) : '',
    );
    final noteController = TextEditingController(text: editEntry?.note ?? '');
    bool youGave = editEntry?.youGave ?? true; // true: You gave (Lent), false: You took (Borrowed)
    DateTime selectedDate = editEntry?.date ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
          final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
          final knownFriends = AppDataRepository.instance.pattFriends;

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Patt Entry' : 'Add Patt / Kadam Entry',
                        style: AppTypography.titleLarge(primaryTextColor).copyWith(fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Transaction Type Toggle (You Gave vs You Took)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            AppSoundService.playIncomeChime();
                            setSheetState(() => youGave = true);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: youGave ? AppColors.primary : (isDark ? AppColors.surfaceDark : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: youGave ? AppColors.primary : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Text(
                                  'You Gave (Lent)',
                                  style: TextStyle(
                                    color: youGave ? Colors.white : primaryTextColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'കിട്ടാനുള്ളത്',
                                  style: TextStyle(
                                    color: youGave ? Colors.white70 : secondaryTextColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            AppSoundService.playExpenseAlert();
                            setSheetState(() => youGave = false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !youGave ? AppColors.coral : (isDark ? AppColors.surfaceDark : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: !youGave ? AppColors.coral : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Text(
                                  'You Took (Borrowed)',
                                  style: TextStyle(
                                    color: !youGave ? Colors.white : primaryTextColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'കൊടുക്കാനുള്ളത്',
                                  style: TextStyle(
                                    color: !youGave ? Colors.white70 : secondaryTextColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Friend Name (with quick chips)
                  TextField(
                    controller: friendController,
                    decoration: const InputDecoration(
                      labelText: 'Friend Name',
                      hintText: 'e.g. Rahul, Sneha, Arun',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (knownFriends.isNotEmpty && !isEditing) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: knownFriends.take(4).map((f) {
                        return ActionChip(
                          label: Text(f, style: const TextStyle(fontSize: 12)),
                          onPressed: () => setSheetState(() => friendController.text = f),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Amount
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹)',
                      hintText: '0',
                      prefixText: '₹ ',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Note / Purpose
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note / Reason',
                      hintText: 'e.g. Dinner bill split, Cab fare, Movie tickets',
                      prefixIcon: Icon(Icons.description_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Button with Validation
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final friend = friendController.text.trim();
                        final amount = double.tryParse(amountController.text.trim()) ?? 0;
                        final note = noteController.text.trim();

                        if (friend.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter friend name')),
                          );
                          return;
                        }
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter an amount greater than ₹0')),
                          );
                          return;
                        }

                        final paise = (amount * 100).toInt();

                        if (isEditing) {
                          await AppDataRepository.instance.updatePattEntry(
                            id: editEntry.id,
                            friendName: friend,
                            friendPhone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                            amountPaise: paise,
                            youGave: youGave,
                            note: note.isNotEmpty ? note : 'Patt Transaction',
                            date: selectedDate,
                          );
                        } else {
                          await AppDataRepository.instance.addPattEntry(
                            friendName: friend,
                            friendPhone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                            amountPaise: paise,
                            youGave: youGave,
                            note: note.isNotEmpty ? note : 'Patt Transaction',
                            date: selectedDate,
                          );
                        }

                        AppSoundService.playIncomeChime();

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEditing ? 'Patt entry updated!' : 'Patt entry recorded for $friend!'),
                              backgroundColor: youGave ? AppColors.primary : AppColors.coral,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: youGave ? AppColors.primary : AppColors.coral,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        isEditing ? 'Update Entry' : 'Save Patt Entry',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFriendLedgerSheet(BuildContext context, String friendName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ListenableBuilder(
        listenable: AppDataRepository.instance,
        builder: (ctx, _) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
          final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

          final entries = AppDataRepository.instance.pattEntries
              .where((p) => p.friendName.toLowerCase() == friendName.toLowerCase())
              .toList();

          final balancePaise = AppDataRepository.instance.getFriendBalancePaise(friendName);
          final friendInitials = friendName.split(' ').map((s) => s.isNotEmpty ? s[0].toUpperCase() : '').take(2).join();

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.8,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Friend Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        friendInitials.isNotEmpty ? friendInitials : 'FR',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(friendName, style: AppTypography.titleLarge(primaryTextColor).copyWith(fontSize: 18)),
                          Text(
                            balancePaise > 0
                                ? 'You will get ₹${(balancePaise / 100).toStringAsFixed(0)} (കിട്ടാനുള്ളത്)'
                                : (balancePaise < 0
                                    ? 'You will give ₹${(balancePaise.abs() / 100).toStringAsFixed(0)} (കൊടുക്കാനുള്ളത്)'
                                    : 'All settled up!'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: balancePaise > 0
                                  ? AppColors.primary
                                  : (balancePaise < 0 ? AppColors.coral : secondaryTextColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Action Bar: Settle / Share Statement / Add
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await DeleteConfirmationDialog.show(
                            context,
                            title: 'Settle All with $friendName?',
                            message: 'Mark all pending borrowings and lendings with $friendName as fully settled?',
                            confirmLabel: 'Mark Settled',
                          );
                          if (confirmed) {
                            await AppDataRepository.instance.settlePattFriend(friendName);
                            AppSoundService.playIncomeChime();
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('All settled with $friendName!')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.handshake_outlined, size: 16),
                        label: const Text('Settle', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _shareFriendStatement(context, friendName, entries, balancePaise);
                        },
                        icon: const Icon(Icons.share_outlined, size: 16),
                        label: const Text('Statement', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAddEditEntrySheet(context, defaultFriend: friendName);
                        },
                        icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                        label: const Text('+ Entry', style: TextStyle(color: Colors.white, fontSize: 12)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Divider(),
                const SizedBox(height: 8),
                Text('TRANSACTION HISTORY (${entries.length})', style: AppTypography.labelSmall(secondaryTextColor)),
                const SizedBox(height: 8),

                // Entries List
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Text('No transactions recorded with $friendName', style: AppTypography.bodySmall(secondaryTextColor)),
                        )
                      : ListView.separated(
                          itemCount: entries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final entry = entries[idx];
                            final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

                            return AppCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: entry.youGave
                                          ? AppColors.primary.withOpacity(0.12)
                                          : AppColors.coral.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      entry.youGave ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                      color: entry.youGave ? AppColors.primary : AppColors.coral,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.note.isNotEmpty ? entry.note : (entry.youGave ? 'You Gave' : 'You Took'),
                                          style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateFormat.format(entry.date),
                                          style: AppTypography.bodySmall(secondaryTextColor).copyWith(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${entry.youGave ? '+' : '-'}₹${(entry.amountPaise / 100).toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: entry.youGave ? AppColors.primary : AppColors.coral,
                                        ),
                                      ),
                                      if (entry.isSettled)
                                        const Text('Settled', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(width: 6),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, size: 18),
                                    onSelected: (val) async {
                                      if (val == 'edit') {
                                        Navigator.pop(ctx);
                                        _showAddEditEntrySheet(context, editEntry: entry);
                                      } else if (val == 'delete') {
                                        final confirmed = await DeleteConfirmationDialog.show(
                                          context,
                                          title: 'Delete Entry?',
                                          message: 'Remove this Patt entry of ₹${(entry.amountPaise / 100).toStringAsFixed(0)}?',
                                        );
                                        if (confirmed) {
                                          await AppDataRepository.instance.deletePattEntry(entry.id);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Entry deleted!')),
                                          );
                                        }
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit Entry')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete Entry', style: TextStyle(color: AppColors.coral))),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _shareFriendStatement(BuildContext context, String friendName, List<PattEntryItem> entries, int balancePaise) {
    AppSoundService.playSuccess();
    final buffer = StringBuffer()
      ..writeln('====================================')
      ..writeln('    SPENDMATE PATT BOOK STATEMENT   ')
      ..writeln('====================================')
      ..writeln('Friend: $friendName')
      ..writeln('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}')
      ..writeln('------------------------------------');

    if (balancePaise > 0) {
      buffer.writeln('STATUS: You will get ₹${(balancePaise / 100).toStringAsFixed(0)} from $friendName (കിട്ടാനുള്ളത്)');
    } else if (balancePaise < 0) {
      buffer.writeln('STATUS: You owe ₹${(balancePaise.abs() / 100).toStringAsFixed(0)} to $friendName (കൊടുക്കാനുള്ളത്)');
    } else {
      buffer.writeln('STATUS: Fully Settled up (₹0 balance)');
    }

    buffer.writeln('------------------------------------');
    buffer.writeln('ENTRY BREAKDOWN:');
    for (var e in entries) {
      final sign = e.youGave ? '(You gave)   +' : '(You took)   -';
      buffer.writeln('• ${DateFormat('dd/MM/yy').format(e.date)}: $sign₹${(e.amountPaise / 100).toStringAsFixed(0)} [${e.note}]');
    }
    buffer.writeln('------------------------------------');
    buffer.writeln('Tracked with SpendMate App');
    buffer.writeln('====================================');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Statement for $friendName copied to clipboard! You can paste and share via WhatsApp or SMS.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patt Book (കടം / പറ്റ് ബുക്ക്)'),
        actions: [
          IconButton(
            tooltip: 'Add Entry',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showAddEditEntrySheet(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: AppDataRepository.instance,
        builder: (context, _) {
          final repo = AppDataRepository.instance;
          final youWillGet = repo.totalYouWillGetPaise;
          final youWillGive = repo.totalYouWillGivePaise;
          final netBalance = repo.netPattBalancePaise;
          final friends = repo.pattFriends;

          final displayedFriends = friends.where((f) {
            final bal = repo.getFriendBalancePaise(f);
            if (_selectedFilter == 1) return bal > 0; // You will get
            if (_selectedFilter == 2) return bal < 0; // You will give
            return true;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patt Book Separate Hero Banner (Never mixed with bank balance!)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'FRIENDS IOU / KHATA LEDGER',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Separate from Net Worth',
                              style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Two-Column Grid: You Will Get vs You Will Give
                      Row(
                        children: [
                          // You Will Get (കിട്ടാനുള്ളത്)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      const Expanded(
                                        child: Text(
                                          'YOU WILL GET',
                                          style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('കിട്ടാനുള്ളത്', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${(youWillGet / 100).toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // You Will Give (കൊടുക്കാനുള്ളത്)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.coral.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.coral.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFFEF4444)),
                                      const SizedBox(width: 4),
                                      const Expanded(
                                        child: Text(
                                          'YOU WILL GIVE',
                                          style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('കൊടുക്കാനുള്ളത്', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${(youWillGive / 100).toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Net Patt Balance Strip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Net Patt Balance',
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              netBalance >= 0
                                  ? '+₹${(netBalance / 100).toStringAsFixed(0)}'
                                  : '-₹${(netBalance.abs() / 100).toStringAsFixed(0)}',
                              style: TextStyle(
                                color: netBalance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Filter Chips
                Row(
                  children: [
                    _filterChip('All Friends (${friends.length})', 0, isDark, primaryTextColor, secondaryTextColor),
                    const SizedBox(width: 8),
                    _filterChip('You Will Get', 1, isDark, primaryTextColor, secondaryTextColor),
                    const SizedBox(width: 8),
                    _filterChip('You Will Give', 2, isDark, primaryTextColor, secondaryTextColor),
                  ],
                ),
                const SizedBox(height: 18),

                // Friends List
                if (displayedFriends.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        children: [
                          Icon(Icons.people_outline_rounded, size: 48, color: secondaryTextColor),
                          const SizedBox(height: 12),
                          Text('No friends in this filter', style: AppTypography.titleMedium(primaryTextColor)),
                          const SizedBox(height: 4),
                          Text('Tap "+ Add Entry" to record money given or taken', style: AppTypography.bodySmall(secondaryTextColor)),
                        ],
                      ),
                    ),
                  )
                else
                  ...displayedFriends.map((friend) {
                    final balance = repo.getFriendBalancePaise(friend);
                    final initials = friend.split(' ').map((s) => s.isNotEmpty ? s[0].toUpperCase() : '').take(2).join();
                    final friendEntries = repo.pattEntries.where((p) => p.friendName.toLowerCase() == friend.toLowerCase()).toList();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: AppCard(
                        onTap: () => _showFriendLedgerSheet(context, friend),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: balance > 0
                                  ? AppColors.primary.withOpacity(0.15)
                                  : (balance < 0 ? AppColors.coral.withOpacity(0.15) : Colors.grey.shade200),
                              child: Text(
                                initials.isNotEmpty ? initials : 'FR',
                                style: TextStyle(
                                  color: balance > 0 ? AppColors.primary : (balance < 0 ? AppColors.coral : Colors.black87),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    friend,
                                    style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${friendEntries.length} ${friendEntries.length == 1 ? 'entry' : 'entries'} · Tap for ledger',
                                    style: AppTypography.bodySmall(secondaryTextColor).copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  balance > 0
                                      ? '₹${(balance / 100).toStringAsFixed(0)}'
                                      : (balance < 0 ? '₹${(balance.abs() / 100).toStringAsFixed(0)}' : '₹0'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: balance > 0
                                        ? AppColors.primary
                                        : (balance < 0 ? AppColors.coral : secondaryTextColor),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  balance > 0
                                      ? 'You will get'
                                      : (balance < 0 ? 'You will give' : 'Settled'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: balance > 0
                                        ? AppColors.primary
                                        : (balance < 0 ? AppColors.coral : secondaryTextColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 20),

                // Add Entry Button
                AppButton(
                  text: '+ Add New Patt / Kadam Entry',
                  onPressed: () => _showAddEditEntrySheet(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, int index, bool isDark, Color primaryColor, Color secondaryColor) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () {
        AppSoundService.playSuccess();
        setState(() => _selectedFilter = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : secondaryColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
