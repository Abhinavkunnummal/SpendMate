import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';

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
  final int budgetPaise;
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

/// Central reactive data repository for SpendMate.
/// Persists real user finances, wallets, cards, EMIs, and trips locally, surviving app restarts,
/// and synchronizes with the MongoDB Atlas backend whenever connected.
class AppDataRepository extends ChangeNotifier {
  static final AppDataRepository instance = AppDataRepository._internal();
  AppDataRepository._internal();

  static const String _txKey = 'spendmate_real_transactions';
  static const String _walletsKey = 'spendmate_real_wallets';
  static const String _tripsKey = 'spendmate_real_trips';
  static const String _emisKey = 'spendmate_real_emis';
  static const String _budgetCapKey = 'spendmate_budget_cap';

  List<TransactionModel> _transactions = [];
  List<WalletModelItem> _wallets = [];
  List<TripModelItem> _trips = [];
  List<EMIModelItem> _emis = [];
  int _monthlyBudgetCapPaise = 500000; // Default ₹5,000 monthly limit (in paise)

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  List<WalletModelItem> get wallets => List.unmodifiable(_wallets);
  List<TripModelItem> get trips => List.unmodifiable(_trips);
  List<EMIModelItem> get emis => List.unmodifiable(_emis);
  int get monthlyBudgetCapPaise => _monthlyBudgetCapPaise;

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

  bool get isBudgetCapExceeded => totalSpentThisMonthPaise > _monthlyBudgetCapPaise;

  int get budgetRemainingPaise => _monthlyBudgetCapPaise - totalSpentThisMonthPaise;

  /// Initializes repo on app launch from SharedPreferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Monthly Budget Cap
      final savedCap = prefs.getInt(_budgetCapKey);
      if (savedCap != null && savedCap > 0) {
        _monthlyBudgetCapPaise = savedCap;
      }

      // Load Wallets
      final walletsJson = prefs.getString(_walletsKey);
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
            balancePaise: 7500000, // Available limit
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
      final txJson = prefs.getString(_txKey);
      if (txJson != null && txJson.isNotEmpty) {
        final List decoded = jsonDecode(txJson);
        _transactions = decoded.map((t) => TransactionModel.fromJson(t)).toList();
      } else {
        _transactions = [];
      }

      // Load Trips
      final tripsJson = prefs.getString(_tripsKey);
      if (tripsJson != null && tripsJson.isNotEmpty) {
        final List decoded = jsonDecode(tripsJson);
        _trips = decoded.map((t) => TripModelItem.fromJson(t)).toList();
      } else {
        _trips = [];
      }

      // Load EMIs
      final emisJson = prefs.getString(_emisKey);
      if (emisJson != null && emisJson.isNotEmpty) {
        final List decoded = jsonDecode(emisJson);
        _emis = decoded.map((e) => EMIModelItem.fromJson(e)).toList();
      } else {
        _emis = [
          EMIModelItem(
            id: 'emi-1',
            title: 'MacBook Air M3 EMI',
            totalAmountPaise: 9600000, // ₹96,000
            monthlyAmountPaise: 800000, // ₹8,000 / month
            remainingMonths: 5,
            linkedCardOrBank: 'HDFC Regalia Credit Card',
            dueDate: '5th of every month',
            lastDate: DateTime.now().add(const Duration(days: 150)),
            reminderEnabled: true,
          ),
        ];
        await _saveEMIs();
      }

      _isInitialized = true;
      notifyListeners();

      // Background sync with MongoDB backend
      _syncWithBackend();
    } catch (_) {
      _isInitialized = true;
    }
  }

  Future<void> setMonthlyBudgetCap(int capPaise) async {
    _monthlyBudgetCapPaise = capPaise;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_budgetCapKey, capPaise);
    notifyListeners();
  }

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

    // Update corresponding wallet balance
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

    await _saveTransactions();
    notifyListeners();

    _pushTransactionToBackend(newTx);
  }

  /// Deletes a transaction and reverses its financial impact on the associated wallet
  Future<void> deleteTransaction(String id) async {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final tx = _transactions[idx];
      // Reverse balance change
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

  Future<void> deleteWallet(String id) async {
    _wallets.removeWhere((w) => w.id == id);
    await _saveWallets();
    notifyListeners();
  }

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

  /// Retrieves day-specific statistics for calendar day filtering
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

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _transactions.map((t) => t.toJson()).toList();
    await prefs.setString(_txKey, jsonEncode(jsonList));
  }

  Future<void> _saveWallets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _wallets.map((w) => w.toJson()).toList();
    await prefs.setString(_walletsKey, jsonEncode(jsonList));
  }

  Future<void> _saveTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _trips.map((t) => t.toJson()).toList();
    await prefs.setString(_tripsKey, jsonEncode(jsonList));
  }

  Future<void> _saveEMIs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _emis.map((e) => e.toJson()).toList();
    await prefs.setString(_emisKey, jsonEncode(jsonList));
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
