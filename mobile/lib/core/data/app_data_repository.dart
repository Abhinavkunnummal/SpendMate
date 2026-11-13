import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';
import '../auth/auth_session_manager.dart';

class TransactionModel {
  final String id;
  final String title;
  final String category;
  final String wallet;
  final int amountPaise;
  final bool isExpense;
  final DateTime date;
  final IconData icon;

  TransactionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.wallet,
    required this.amountPaise,
    required this.isExpense,
    required this.date,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'wallet': wallet,
    'amountPaise': amountPaise,
    'isExpense': isExpense,
    'date': date.toIso8601String(),
    'iconCode': icon.codePoint,
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    category: json['category'] ?? 'General',
    wallet: json['wallet'] ?? 'Main Wallet',
    amountPaise: json['amountPaise'] ?? 0,
    isExpense: json['isExpense'] ?? true,
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    icon: json['iconCode'] != null
        ? IconData(json['iconCode'], fontFamily: 'MaterialIcons')
        : Icons.payment_rounded,
  );
}

class WalletModelItem {
  final String id;
  final String name;
  final String type; // 'bank', 'cash', 'credit_card', 'debit_card'
  int balancePaise;
  final String color;
  final String accountNumberLast4;
  int limitPaise; // For credit cards
  int outstandingPaise; // Amount to pay to credit card
  String? dueDate; // e.g. "18th of month"

  WalletModelItem({
    required this.id,
    required this.name,
    required this.type,
    required this.balancePaise,
    required this.color,
    required this.accountNumberLast4,
    this.limitPaise = 0,
    this.outstandingPaise = 0,
    this.dueDate,
  });

  bool get isCreditCard => type == 'credit_card' || type == 'credit';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'balancePaise': balancePaise,
    'color': color,
    'accountNumberLast4': accountNumberLast4,
    'limitPaise': limitPaise,
    'outstandingPaise': outstandingPaise,
    'dueDate': dueDate,
  };

  factory WalletModelItem.fromJson(Map<String, dynamic> json) => WalletModelItem(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    type: json['type'] ?? 'bank',
    balancePaise: json['balancePaise'] ?? 0,
    color: json['color'] ?? '#16A878',
    accountNumberLast4: json['accountNumberLast4'] ?? '0000',
    limitPaise: json['limitPaise'] ?? 0,
    outstandingPaise: json['outstandingPaise'] ?? 0,
    dueDate: json['dueDate'],
  );
}

class EMIModelItem {
  final String id;
  final String title;
  final int totalAmountPaise;
  final int monthlyAmountPaise;
  final int remainingMonths;
  final String linkedCardOrBank;
  final String dueDate; // e.g. "5th of every month"
  final DateTime lastDate;
  bool reminderEnabled;

  EMIModelItem({
    required this.id,
    required this.title,
    required this.totalAmountPaise,
    required this.monthlyAmountPaise,
    required this.remainingMonths,
    required this.linkedCardOrBank,
    required this.dueDate,
    required this.lastDate,
    this.reminderEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'totalAmountPaise': totalAmountPaise,
    'monthlyAmountPaise': monthlyAmountPaise,
    'remainingMonths': remainingMonths,
    'linkedCardOrBank': linkedCardOrBank,
    'dueDate': dueDate,
    'lastDate': lastDate.toIso8601String(),
    'reminderEnabled': reminderEnabled,
  };

  factory EMIModelItem.fromJson(Map<String, dynamic> json) => EMIModelItem(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    totalAmountPaise: json['totalAmountPaise'] ?? 0,
    monthlyAmountPaise: json['monthlyAmountPaise'] ?? 0,
    remainingMonths: json['remainingMonths'] ?? 1,
    linkedCardOrBank: json['linkedCardOrBank'] ?? 'Primary Bank',
    dueDate: json['dueDate'] ?? '5th of month',
    lastDate: DateTime.tryParse(json['lastDate'] ?? '') ?? DateTime.now().add(const Duration(days: 90)),
    reminderEnabled: json['reminderEnabled'] ?? true,
  );
}

class TripModelItem {
  final String id;
  final String name;
  final String destination;
  final int budgetPaise; // 0 means open/flexible budget
  int spentPaise;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> members;
  final List<Map<String, dynamic>> expenses;

  TripModelItem({
    required this.id,
    required this.name,
    required this.destination,
    required this.budgetPaise,
    this.spentPaise = 0,
    required this.startDate,
    required this.endDate,
    required this.members,
    this.expenses = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'destination': destination,
    'budgetPaise': budgetPaise,
    'spentPaise': spentPaise,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'members': members,
    'expenses': expenses,
  };

  factory TripModelItem.fromJson(Map<String, dynamic> json) => TripModelItem(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    destination: json['destination'] ?? '',
    budgetPaise: json['budgetPaise'] ?? 0,
    spentPaise: json['spentPaise'] ?? 0,
    startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
    endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now().add(const Duration(days: 3)),
    members: List<String>.from(json['members'] ?? []),
    expenses: List<Map<String, dynamic>>.from(json['expenses'] ?? []),
  );
}

/// Patt Book (Friend Debts & IOU Ledger) Entry Model
/// Strictly kept separate from personal net worth and wallet balances.
class PattEntryItem {
  final String id;
  final String friendName;
  final String? friendPhone;
  int amountPaise;
  bool youGave; // true: You gave (To Receive / Lent), false: You took (To Pay / Borrowed)
  String note;
  DateTime date;
  bool isSettled;

  PattEntryItem({
    required this.id,
    required this.friendName,
    this.friendPhone,
    required this.amountPaise,
    required this.youGave,
    required this.note,
    required this.date,
    this.isSettled = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'friendName': friendName,
    'friendPhone': friendPhone,
    'amountPaise': amountPaise,
    'youGave': youGave,
    'note': note,
    'date': date.toIso8601String(),
    'isSettled': isSettled,
  };

  factory PattEntryItem.fromJson(Map<String, dynamic> json) => PattEntryItem(
    id: json['id'] ?? '',
    friendName: json['friendName'] ?? 'Friend',
    friendPhone: json['friendPhone'],
    amountPaise: json['amountPaise'] ?? 0,
    youGave: json['youGave'] ?? true,
    note: json['note'] ?? '',
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    isSettled: json['isSettled'] ?? false,
  );
}

/// Central reactive data repository for SpendMate.
/// Provides user-scoped persistence, CRUD with edit options, Patt Book separation,
/// and backend sync.
class AppDataRepository extends ChangeNotifier {
  static final AppDataRepository instance = AppDataRepository._internal();
  AppDataRepository._internal();

  static const String _txKey = 'spendmate_real_transactions';
  static const String _walletsKey = 'spendmate_real_wallets';
  static const String _tripsKey = 'spendmate_real_trips';
  static const String _emisKey = 'spendmate_real_emis';
  static const String _pattKey = 'spendmate_real_patt_entries';
  static const String _budgetCapKey = 'spendmate_budget_cap';

  List<TransactionModel> _transactions = [];
  List<WalletModelItem> _wallets = [];
  List<TripModelItem> _trips = [];
  List<EMIModelItem> _emis = [];
  List<PattEntryItem> _pattEntries = [];
  int _monthlyBudgetCapPaise = 500000; // Default ₹5,000 monthly limit (in paise)

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  List<WalletModelItem> get wallets => List.unmodifiable(_wallets);
  List<TripModelItem> get trips => List.unmodifiable(_trips);
  List<EMIModelItem> get emis => List.unmodifiable(_emis);
  List<PattEntryItem> get pattEntries => List.unmodifiable(_pattEntries);
  int get monthlyBudgetCapPaise => _monthlyBudgetCapPaise;

  /// User-specific storage key ensuring zero cross-user data leakage
  String _getUserKey(String baseKey) {
    final user = AuthSessionManager.instance;
    final uid = user.userId ?? user.phoneNumber ?? 'user_default';
    return '${baseKey}_$uid';
  }

  /// Pure bank & cash liquidity (excludes credit card debt)
  int get bankLiquidityPaise {
    return _wallets
        .where((w) => !w.isCreditCard)
        .fold(0, (sum, w) => sum + w.balancePaise);
  }

  /// Total credit card debt / outstanding to pay
  int get totalCreditOutstandingPaise {
    return _wallets
        .where((w) => w.isCreditCard)
        .fold(0, (sum, w) => sum + w.outstandingPaise);
  }

  /// Total Net Worth = Bank/Cash Liquidity - Credit Card Debt
  int get netWorthPaise {
    return bankLiquidityPaise - totalCreditOutstandingPaise;
  }

  int get totalIncomePaise {
    return _transactions
        .where((t) => !t.isExpense)
        .fold(0, (sum, t) => sum + t.amountPaise);
  }

  int get totalSpentPaise {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0, (sum, t) => sum + t.amountPaise);
  }

  /// Total spent in current calendar month
  int get totalSpentThisMonthPaise {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.isExpense && t.date.year == now.year && t.date.month == now.month)
        .fold(0, (sum, t) => sum + t.amountPaise);
  }

  /// Total income in current calendar month
  int get totalIncomeThisMonthPaise {
    final now = DateTime.now();
    return _transactions
        .where((t) => !t.isExpense && t.date.year == now.year && t.date.month == now.month)
        .fold(0, (sum, t) => sum + t.amountPaise);
  }

  /// Total spent today (calendar day)
  int get totalSpentTodayPaise {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.isExpense && t.date.year == now.year && t.date.month == now.month && t.date.day == now.day)
        .fold(0, (sum, t) => sum + t.amountPaise);
  }

  /// Total income today (calendar day)
  int get totalIncomeTodayPaise {
    final now = DateTime.now();
    return _transactions
        .where((t) => !t.isExpense && t.date.year == now.year && t.date.month == now.month && t.date.day == now.day)
        .fold(0, (sum, t) => sum + t.amountPaise);
  }

  bool get isBudgetCapExceeded => totalSpentThisMonthPaise > _monthlyBudgetCapPaise;
  int get budgetRemainingPaise => _monthlyBudgetCapPaise - totalSpentThisMonthPaise;

  /// Total active EMI monthly installment commitment
  int get totalMonthlyEMIPaise => _emis.fold(0, (sum, e) => sum + e.monthlyAmountPaise);

  /// Total remaining EMI obligations
  int get totalRemainingEMIObligationPaise =>
      _emis.fold(0, (sum, e) => sum + (e.monthlyAmountPaise * e.remainingMonths));

  // -------------------------------------------------------------
  // PATT BOOK (FRIEND LEDGER) GETTERS (SEPARATE TOTALS!)
  // -------------------------------------------------------------

  /// Total money you will get back from friends (To Receive / Lent)
  int get totalYouWillGetPaise {
    return _pattEntries
        .where((p) => !p.isSettled && p.youGave)
        .fold(0, (sum, p) => sum + p.amountPaise);
  }

  /// Total money you need to give to friends (To Pay / Borrowed)
  int get totalYouWillGivePaise {
    return _pattEntries
        .where((p) => !p.isSettled && !p.youGave)
        .fold(0, (sum, p) => sum + p.amountPaise);
  }

  /// Net Patt Balance = (You Will Get - You Will Give)
  int get netPattBalancePaise => totalYouWillGetPaise - totalYouWillGivePaise;

  /// Unique list of friends recorded in Patt Book
  List<String> get pattFriends {
    final Set<String> friends = {};
    for (var p in _pattEntries) {
      if (p.friendName.trim().isNotEmpty) {
        friends.add(p.friendName.trim());
      }
    }
    return friends.toList()..sort();
  }

  /// Balance with a single friend (Positive = friend owes you, Negative = you owe friend)
  int getFriendBalancePaise(String friendName) {
    int balance = 0;
    for (var p in _pattEntries.where((e) => e.friendName == friendName && !e.isSettled)) {
      if (p.youGave) {
        balance += p.amountPaise;
      } else {
        balance -= p.amountPaise;
      }
    }
    return balance;
  }

  // -------------------------------------------------------------
  // INITIALIZATION & USER ISOLATION
  // -------------------------------------------------------------

  /// Initializes repo for the currently authenticated user
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Monthly Budget Cap
      final savedCap = prefs.getInt(_getUserKey(_budgetCapKey));
      if (savedCap != null && savedCap > 0) {
        _monthlyBudgetCapPaise = savedCap;
      } else {
        _monthlyBudgetCapPaise = 500000;
      }

      // Load Wallets
      final walletsJson = prefs.getString(_getUserKey(_walletsKey));
      if (walletsJson != null && walletsJson.isNotEmpty) {
        final List decoded = jsonDecode(walletsJson);
        _wallets = decoded.map((w) => WalletModelItem.fromJson(w)).toList();
      } else {
        _wallets = [
          WalletModelItem(
            id: 'wallet-1',
            name: 'Primary Bank Account',
            type: 'bank',
            balancePaise: 4500000, // ₹45,000.00
            color: '#16A878',
            accountNumberLast4: '4821',
          ),
          WalletModelItem(
            id: 'wallet-2',
            name: 'Cash In Hand',
            type: 'cash',
            balancePaise: 500000, // ₹5,000.00
            color: '#FFA94D',
            accountNumberLast4: '0000',
          ),
          WalletModelItem(
            id: 'wallet-3',
            name: 'HDFC Regalia Credit Card',
            type: 'credit_card',
            balancePaise: 7500000,
            color: '#FF6B6B',
            accountNumberLast4: '9204',
            limitPaise: 10000000, // ₹1,00,000 Limit
            outstandingPaise: 2500000, // ₹25,000 Due
            dueDate: '18th of month',
          ),
        ];
        await _saveWallets();
      }

      // Load Transactions
      final txJson = prefs.getString(_getUserKey(_txKey));
      if (txJson != null && txJson.isNotEmpty) {
        final List decoded = jsonDecode(txJson);
        _transactions = decoded.map((t) => TransactionModel.fromJson(t)).toList();
      } else {
        _transactions = [];
      }

      // Load Trips
      final tripsJson = prefs.getString(_getUserKey(_tripsKey));
      if (tripsJson != null && tripsJson.isNotEmpty) {
        final List decoded = jsonDecode(tripsJson);
        _trips = decoded.map((t) => TripModelItem.fromJson(t)).toList();
      } else {
        _trips = [];
      }

      // Load EMIs
      final emisJson = prefs.getString(_getUserKey(_emisKey));
      if (emisJson != null && emisJson.isNotEmpty) {
        final List decoded = jsonDecode(emisJson);
        _emis = decoded.map((e) => EMIModelItem.fromJson(e)).toList();
      } else {
        _emis = [
          EMIModelItem(
            id: 'emi-1',
            title: 'MacBook Air M3 EMI',
            totalAmountPaise: 9600000,
            monthlyAmountPaise: 800000,
            remainingMonths: 5,
            linkedCardOrBank: 'HDFC Regalia Credit Card',
            dueDate: '5th of every month',
            lastDate: DateTime.now().add(const Duration(days: 150)),
            reminderEnabled: true,
          ),
        ];
        await _saveEMIs();
      }

      // Load Patt Book Entries
      final pattJson = prefs.getString(_getUserKey(_pattKey));
      if (pattJson != null && pattJson.isNotEmpty) {
        final List decoded = jsonDecode(pattJson);
        _pattEntries = decoded.map((p) => PattEntryItem.fromJson(p)).toList();
      } else {
        _pattEntries = [
          PattEntryItem(
            id: 'patt-1',
            friendName: 'Rahul',
            amountPaise: 120000, // ₹1,200
            youGave: true, // You gave -> Kittan ullath (Friend owes you)
            note: 'Dinner bill split share',
            date: DateTime.now().subtract(const Duration(days: 2)),
          ),
          PattEntryItem(
            id: 'patt-2',
            friendName: 'Sneha',
            amountPaise: 50000, // ₹500
            youGave: false, // You took -> Kodukkan ullath (You owe friend)
            note: 'Cab share from airport',
            date: DateTime.now().subtract(const Duration(days: 4)),
          ),
        ];
        await _savePattEntries();
      }

      _isInitialized = true;
      notifyListeners();

      // Background sync with MongoDB backend
      _syncWithBackend();
    } catch (_) {
      _isInitialized = true;
    }
  }

  /// Wipes in-memory user data when logging out
  Future<void> clearUserData() async {
    _transactions = [];
    _wallets = [];
    _trips = [];
    _emis = [];
    _pattEntries = [];
    _isInitialized = false;
    notifyListeners();
  }

  /// Reloads user data when logging in as a different user
  Future<void> reloadUserData() async {
    _isInitialized = false;
    await initialize();
  }

  Future<void> setMonthlyBudgetCap(int capPaise) async {
    _monthlyBudgetCapPaise = capPaise;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_getUserKey(_budgetCapKey), capPaise);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // TRANSACTIONS CRUD (ADD, EDIT, DELETE)
  // -------------------------------------------------------------

  Future<void> addTransaction({
    required String title,
    required int amountPaise,
    required bool isExpense,
    required String category,
    required String wallet,
    DateTime? date,
    IconData? icon,
  }) async {
    final newTx = TransactionModel(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      wallet: wallet,
      amountPaise: amountPaise,
      isExpense: isExpense,
      date: date ?? DateTime.now(),
      icon: icon ?? _resolveCategoryIcon(category),
    );

    _transactions.insert(0, newTx);

    // Update corresponding wallet balance (unless it is a friend patt book entry)
    if (!wallet.toLowerCase().contains('patt') && !wallet.toLowerCase().contains('friend')) {
      final walletIdx = _wallets.indexWhere((w) => w.name == wallet);
      if (walletIdx != -1) {
        final targetWallet = _wallets[walletIdx];
        if (targetWallet.isCreditCard) {
          if (isExpense) {
            targetWallet.outstandingPaise += amountPaise;
          } else {
            targetWallet.outstandingPaise = (targetWallet.outstandingPaise - amountPaise).clamp(0, targetWallet.limitPaise);
          }
        } else {
          if (isExpense) {
            targetWallet.balancePaise -= amountPaise;
          } else {
            targetWallet.balancePaise += amountPaise;
          }
        }
        await _saveWallets();
      } else if (_wallets.isNotEmpty) {
        if (isExpense) {
          _wallets[0].balancePaise -= amountPaise;
        } else {
          _wallets[0].balancePaise += amountPaise;
        }
        await _saveWallets();
      }
    }

    await _saveTransactions();
    notifyListeners();
    _pushTransactionToBackend(newTx);
  }

  Future<void> updateTransaction({
    required String id,
    required String title,
    required int amountPaise,
    required bool isExpense,
    required String category,
    required String wallet,
    DateTime? date,
  }) async {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final oldTx = _transactions[idx];

      // 1. Revert previous wallet impact
      final oldWIdx = _wallets.indexWhere((w) => w.name == oldTx.wallet);
      if (oldWIdx != -1) {
        final w = _wallets[oldWIdx];
        if (w.isCreditCard) {
          if (oldTx.isExpense) {
            w.outstandingPaise = (w.outstandingPaise - oldTx.amountPaise).clamp(0, w.limitPaise);
          } else {
            w.outstandingPaise += oldTx.amountPaise;
          }
        } else {
          if (oldTx.isExpense) {
            w.balancePaise += oldTx.amountPaise;
          } else {
            w.balancePaise -= oldTx.amountPaise;
          }
        }
      }

      // 2. Apply new wallet impact
      final newWIdx = _wallets.indexWhere((w) => w.name == wallet);
      if (newWIdx != -1) {
        final w = _wallets[newWIdx];
        if (w.isCreditCard) {
          if (isExpense) {
            w.outstandingPaise += amountPaise;
          } else {
            w.outstandingPaise = (w.outstandingPaise - amountPaise).clamp(0, w.limitPaise);
          }
        } else {
          if (isExpense) {
            w.balancePaise -= amountPaise;
          } else {
            w.balancePaise += amountPaise;
          }
        }
      }

      await _saveWallets();

      _transactions[idx] = TransactionModel(
        id: id,
        title: title,
        category: category,
        wallet: wallet,
        amountPaise: amountPaise,
        isExpense: isExpense,
        date: date ?? oldTx.date,
        icon: _resolveCategoryIcon(category),
      );

      await _saveTransactions();
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final tx = _transactions[idx];
      final walletIdx = _wallets.indexWhere((w) => w.name == tx.wallet);
      if (walletIdx != -1) {
        final targetWallet = _wallets[walletIdx];
        if (targetWallet.isCreditCard) {
          if (tx.isExpense) {
            targetWallet.outstandingPaise = (targetWallet.outstandingPaise - tx.amountPaise).clamp(0, targetWallet.limitPaise);
          } else {
            targetWallet.outstandingPaise += tx.amountPaise;
          }
        } else {
          if (tx.isExpense) {
            targetWallet.balancePaise += tx.amountPaise;
          } else {
            targetWallet.balancePaise -= tx.amountPaise;
          }
        }
        await _saveWallets();
      }

      _transactions.removeAt(idx);
      await _saveTransactions();
      notifyListeners();
    }
  }

  // -------------------------------------------------------------
  // WALLETS & CARDS CRUD (ADD, EDIT, DELETE)
  // -------------------------------------------------------------

  Future<void> addWallet({
    required String name,
    required String type,
    required int balancePaise,
    String? accountNumberLast4,
    int? limitPaise,
    int? outstandingPaise,
    String? dueDate,
  }) async {
    final isCredit = type == 'credit_card' || type == 'credit';
    final wallet = WalletModelItem(
      id: 'wallet_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      balancePaise: balancePaise,
      color: isCredit ? '#FF6B6B' : (type == 'cash' ? '#FFA94D' : '#16A878'),
      accountNumberLast4: accountNumberLast4 ?? '1234',
      limitPaise: limitPaise ?? (isCredit ? balancePaise : 0),
      outstandingPaise: outstandingPaise ?? 0,
      dueDate: dueDate,
    );
    _wallets.add(wallet);
    await _saveWallets();
    notifyListeners();
  }

  Future<void> updateWallet({
    required String id,
    required String name,
    required String type,
    required int balancePaise,
    String? accountNumberLast4,
    int? limitPaise,
    int? outstandingPaise,
    String? dueDate,
  }) async {
    final idx = _wallets.indexWhere((w) => w.id == id);
    if (idx != -1) {
      final isCredit = type == 'credit_card' || type == 'credit';
      _wallets[idx] = WalletModelItem(
        id: id,
        name: name,
        type: type,
        balancePaise: balancePaise,
        color: isCredit ? '#FF6B6B' : (type == 'cash' ? '#FFA94D' : '#16A878'),
        accountNumberLast4: accountNumberLast4 ?? _wallets[idx].accountNumberLast4,
        limitPaise: limitPaise ?? _wallets[idx].limitPaise,
        outstandingPaise: outstandingPaise ?? _wallets[idx].outstandingPaise,
        dueDate: dueDate ?? _wallets[idx].dueDate,
      );
      await _saveWallets();
      notifyListeners();
    }
  }

  Future<void> deleteWallet(String id) async {
    _wallets.removeWhere((w) => w.id == id);
    await _saveWallets();
    notifyListeners();
  }

  // -------------------------------------------------------------
  // TRIPS & GROUP EXPENSES CRUD (ADD, EDIT, DELETE)
  // -------------------------------------------------------------

  Future<void> addTrip({
    required String name,
    required String destination,
    required int budgetPaise,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? members,
  }) async {
    final trip = TripModelItem(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      destination: destination,
      budgetPaise: budgetPaise,
      startDate: startDate,
      endDate: endDate,
      members: members ?? ['You'],
    );

    _trips.insert(0, trip);
    await _saveTrips();
    notifyListeners();

    _pushTripToBackend(trip);
  }

  Future<void> updateTrip({
    required String id,
    required String name,
    required String destination,
    required int budgetPaise,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? members,
  }) async {
    final idx = _trips.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final trip = _trips[idx];
      _trips[idx] = TripModelItem(
        id: id,
        name: name,
        destination: destination,
        budgetPaise: budgetPaise,
        spentPaise: trip.spentPaise,
        startDate: startDate,
        endDate: endDate,
        members: members ?? trip.members,
        expenses: trip.expenses,
      );
      await _saveTrips();
      notifyListeners();
    }
  }

  Future<void> deleteTrip(String tripId) async {
    _trips.removeWhere((t) => t.id == tripId);
    await _saveTrips();
    notifyListeners();
  }

  Future<void> addTripExpense({
    required String tripId,
    required String title,
    required int amountPaise,
    required String paidBy,
  }) async {
    final tripIdx = _trips.indexWhere((t) => t.id == tripId);
    if (tripIdx != -1) {
      final trip = _trips[tripIdx];
      final newExpenses = List<Map<String, dynamic>>.from(trip.expenses);
      newExpenses.add({
        'id': 'exp_${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'amountPaise': amountPaise,
        'paidBy': paidBy,
        'createdAt': DateTime.now().toIso8601String(),
      });

      _trips[tripIdx] = TripModelItem(
        id: trip.id,
        name: trip.name,
        destination: trip.destination,
        budgetPaise: trip.budgetPaise,
        spentPaise: trip.spentPaise + amountPaise,
        startDate: trip.startDate,
        endDate: trip.endDate,
        members: trip.members,
        expenses: newExpenses,
      );

      await _saveTrips();
      notifyListeners();
    }
  }

  Future<void> updateTripExpense({
    required String tripId,
    required String expenseId,
    required String title,
    required int amountPaise,
    required String paidBy,
  }) async {
    final tripIdx = _trips.indexWhere((t) => t.id == tripId);
    if (tripIdx != -1) {
      final trip = _trips[tripIdx];
      final newExpenses = List<Map<String, dynamic>>.from(trip.expenses);
      final expIdx = newExpenses.indexWhere((e) => e['id'] == expenseId);
      if (expIdx != -1) {
        newExpenses[expIdx] = {
          'id': expenseId,
          'title': title,
          'amountPaise': amountPaise,
          'paidBy': paidBy,
          'createdAt': newExpenses[expIdx]['createdAt'] ?? DateTime.now().toIso8601String(),
        };

        final newSpent = newExpenses.fold<int>(0, (sum, e) => sum + (e['amountPaise'] as int? ?? 0));

        _trips[tripIdx] = TripModelItem(
          id: trip.id,
          name: trip.name,
          destination: trip.destination,
          budgetPaise: trip.budgetPaise,
          spentPaise: newSpent,
          startDate: trip.startDate,
          endDate: trip.endDate,
          members: trip.members,
          expenses: newExpenses,
        );

        await _saveTrips();
        notifyListeners();
      }
    }
  }

  Future<void> deleteTripExpense(String tripId, String expenseId) async {
    final tripIdx = _trips.indexWhere((t) => t.id == tripId);
    if (tripIdx != -1) {
      final trip = _trips[tripIdx];
      final newExpenses = List<Map<String, dynamic>>.from(trip.expenses);
      final expIdx = newExpenses.indexWhere((e) => e['id'] == expenseId);
      if (expIdx != -1) {
        final amountPaise = (newExpenses[expIdx]['amountPaise'] as num).toInt();
        newExpenses.removeAt(expIdx);

        _trips[tripIdx] = TripModelItem(
          id: trip.id,
          name: trip.name,
          destination: trip.destination,
          budgetPaise: trip.budgetPaise,
          spentPaise: (trip.spentPaise - amountPaise).clamp(0, 999999999),
          startDate: trip.startDate,
          endDate: trip.endDate,
          members: trip.members,
          expenses: newExpenses,
        );

        await _saveTrips();
        notifyListeners();
      }
    }
  }

  // -------------------------------------------------------------
  // EMIs & REMINDERS CRUD (ADD, EDIT, DELETE)
  // -------------------------------------------------------------

  Future<void> addEMI({
    required String title,
    required int totalAmountPaise,
    required int monthlyAmountPaise,
    required int remainingMonths,
    required String linkedCardOrBank,
    required String dueDate,
    required DateTime lastDate,
  }) async {
    final emi = EMIModelItem(
      id: 'emi_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      totalAmountPaise: totalAmountPaise,
      monthlyAmountPaise: monthlyAmountPaise,
      remainingMonths: remainingMonths,
      linkedCardOrBank: linkedCardOrBank,
      dueDate: dueDate,
      lastDate: lastDate,
    );
    _emis.add(emi);
    await _saveEMIs();
    notifyListeners();
  }

  Future<void> updateEMI({
    required String id,
    required String title,
    required int totalAmountPaise,
    required int monthlyAmountPaise,
    required int remainingMonths,
    required String linkedCardOrBank,
    required String dueDate,
    required DateTime lastDate,
  }) async {
    final idx = _emis.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _emis[idx] = EMIModelItem(
        id: id,
        title: title,
        totalAmountPaise: totalAmountPaise,
        monthlyAmountPaise: monthlyAmountPaise,
        remainingMonths: remainingMonths,
        linkedCardOrBank: linkedCardOrBank,
        dueDate: dueDate,
        lastDate: lastDate,
        reminderEnabled: _emis[idx].reminderEnabled,
      );
      await _saveEMIs();
      notifyListeners();
    }
  }

  Future<void> deleteEMI(String id) async {
    _emis.removeWhere((e) => e.id == id);
    await _saveEMIs();
    notifyListeners();
  }

  Future<void> toggleEMIReminder(String id) async {
    final idx = _emis.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _emis[idx].reminderEnabled = !_emis[idx].reminderEnabled;
      await _saveEMIs();
      notifyListeners();
    }
  }

  // -------------------------------------------------------------
  // PATT BOOK (FRIEND LEDGER) CRUD
  // -------------------------------------------------------------

  Future<void> addPattEntry({
    required String friendName,
    String? friendPhone,
    required int amountPaise,
    required bool youGave,
    required String note,
    DateTime? date,
  }) async {
    final entry = PattEntryItem(
      id: 'patt_${DateTime.now().millisecondsSinceEpoch}',
      friendName: friendName.trim(),
      friendPhone: friendPhone?.trim(),
      amountPaise: amountPaise,
      youGave: youGave,
      note: note.trim(),
      date: date ?? DateTime.now(),
    );
    _pattEntries.insert(0, entry);
    await _savePattEntries();
    notifyListeners();
  }

  Future<void> updatePattEntry({
    required String id,
    required String friendName,
    String? friendPhone,
    required int amountPaise,
    required bool youGave,
    required String note,
    DateTime? date,
  }) async {
    final idx = _pattEntries.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _pattEntries[idx] = PattEntryItem(
        id: id,
        friendName: friendName.trim(),
        friendPhone: friendPhone?.trim(),
        amountPaise: amountPaise,
        youGave: youGave,
        note: note.trim(),
        date: date ?? _pattEntries[idx].date,
        isSettled: _pattEntries[idx].isSettled,
      );
      await _savePattEntries();
      notifyListeners();
    }
  }

  Future<void> deletePattEntry(String id) async {
    _pattEntries.removeWhere((p) => p.id == id);
    await _savePattEntries();
    notifyListeners();
  }

  Future<void> settlePattFriend(String friendName) async {
    for (int i = 0; i < _pattEntries.length; i++) {
      if (_pattEntries[i].friendName.toLowerCase() == friendName.toLowerCase()) {
        final old = _pattEntries[i];
        _pattEntries[i] = PattEntryItem(
          id: old.id,
          friendName: old.friendName,
          friendPhone: old.friendPhone,
          amountPaise: old.amountPaise,
          youGave: old.youGave,
          note: '${old.note} (Settled)',
          date: old.date,
          isSettled: true,
        );
      }
    }
    await _savePattEntries();
    notifyListeners();
  }

  // -------------------------------------------------------------
  // DAY SUMMARY FOR CALENDAR FILTERING
  // -------------------------------------------------------------

  Map<String, dynamic> getDaySummary(DateTime date) {
    final dayTxs = _transactions.where((t) {
      return t.date.year == date.year && t.date.month == date.month && t.date.day == date.day;
    }).toList();

    int expense = 0;
    int income = 0;
    TransactionModel? topExpense;
    TransactionModel? topIncome;

    for (var tx in dayTxs) {
      if (tx.isExpense) {
        expense += tx.amountPaise;
        if (topExpense == null || tx.amountPaise > topExpense.amountPaise) {
          topExpense = tx;
        }
      } else {
        income += tx.amountPaise;
        if (topIncome == null || tx.amountPaise > topIncome.amountPaise) {
          topIncome = tx;
        }
      }
    }

    return {
      'transactions': dayTxs,
      'totalExpensePaise': expense,
      'totalIncomePaise': income,
      'netPaise': income - expense,
      'topExpense': topExpense,
      'topIncome': topIncome,
    };
  }

  IconData _resolveCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
      case 'food':
        return Icons.restaurant_rounded;
      case 'travel & trips':
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'groceries':
        return Icons.shopping_basket_rounded;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'bills & utilities':
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'transport':
      case 'fuel':
        return Icons.directions_car_filled_rounded;
      case 'movies & cinema':
      case 'movies':
        return Icons.movie_creation_outlined;
      case 'gaming & fun':
      case 'gaming':
        return Icons.sports_esports_outlined;
      case 'health & pharmacy':
      case 'medical':
        return Icons.medical_services_outlined;
      case 'education & books':
        return Icons.school_outlined;
      case 'personal care & salon':
        return Icons.spa_outlined;
      case 'investments':
        return Icons.trending_up_rounded;
      case 'salary':
      case 'freelance':
      case 'income':
        return Icons.payments_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }

  // -------------------------------------------------------------
  // PERSISTENCE (USER-SCOPED)
  // -------------------------------------------------------------

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _transactions.map((t) => t.toJson()).toList();
    await prefs.setString(_getUserKey(_txKey), jsonEncode(jsonList));
  }

  Future<void> _saveWallets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _wallets.map((w) => w.toJson()).toList();
    await prefs.setString(_getUserKey(_walletsKey), jsonEncode(jsonList));
  }

  Future<void> _saveTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _trips.map((t) => t.toJson()).toList();
    await prefs.setString(_getUserKey(_tripsKey), jsonEncode(jsonList));
  }

  Future<void> _saveEMIs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _emis.map((e) => e.toJson()).toList();
    await prefs.setString(_getUserKey(_emisKey), jsonEncode(jsonList));
  }

  Future<void> _savePattEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _pattEntries.map((p) => p.toJson()).toList();
    await prefs.setString(_getUserKey(_pattKey), jsonEncode(jsonList));
  }

  Future<void> _syncWithBackend() async {
    try {
      final res = await ApiClient().dio.get(ApiConstants.transactions);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final List data = res.data['data']['transactions'] ?? [];
        if (data.isNotEmpty) {
          for (var item in data) {
            final id = item['_id'] ?? item['id'];
            if (!_transactions.any((t) => t.id == id)) {
              _transactions.add(TransactionModel(
                id: id,
                title: item['description'] ?? item['title'] ?? 'Transaction',
                category: item['categoryId'] ?? 'General',
                wallet: 'Bank',
                amountPaise: item['amountPaise'] ?? 0,
                isExpense: item['type'] == 'expense',
                date: DateTime.tryParse(item['date'] ?? '') ?? DateTime.now(),
                icon: Icons.payment_rounded,
              ));
            }
          }
          await _saveTransactions();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _pushTransactionToBackend(TransactionModel tx) async {
    try {
      await ApiClient().dio.post(ApiConstants.transactions, data: {
        'description': tx.title,
        'amountPaise': tx.amountPaise,
        'type': tx.isExpense ? 'expense' : 'income',
        'date': tx.date.toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> _pushTripToBackend(TripModelItem trip) async {
    try {
      await ApiClient().dio.post(ApiConstants.trips, data: {
        'title': trip.name,
        'destination': trip.destination,
        'budgetPaise': trip.budgetPaise,
        'startDate': trip.startDate.toIso8601String(),
        'endDate': trip.endDate.toIso8601String(),
      });
    } catch (_) {}
  }
}
