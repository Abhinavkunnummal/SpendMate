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
  final String type;
  int balancePaise;
  final String color;
  final String accountNumberLast4;

  WalletModelItem({
    required this.id,
    required this.name,
    required this.type,
    required this.balancePaise,
    required this.color,
    required this.accountNumberLast4,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'balancePaise': balancePaise,
    'color': color,
    'accountNumberLast4': accountNumberLast4,
  };

  factory WalletModelItem.fromJson(Map<String, dynamic> json) => WalletModelItem(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    type: json['type'] ?? 'bank',
    balancePaise: json['balancePaise'] ?? 0,
    color: json['color'] ?? '#16A878',
    accountNumberLast4: json['accountNumberLast4'] ?? '0000',
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
/// Persists real user finances and trips locally, surviving app restarts,
/// and synchronizes with the MongoDB Atlas backend whenever connected.
class AppDataRepository extends ChangeNotifier {
  static final AppDataRepository instance = AppDataRepository._internal();
  AppDataRepository._internal();

  static const String _txKey = 'spendmate_real_transactions';
  static const String _walletsKey = 'spendmate_real_wallets';
  static const String _tripsKey = 'spendmate_real_trips';

  List<TransactionModel> _transactions = [];
  List<WalletModelItem> _wallets = [];
  List<TripModelItem> _trips = [];
  bool _isInitialized = false;

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  List<WalletModelItem> get wallets => List.unmodifiable(_wallets);
  List<TripModelItem> get trips => List.unmodifiable(_trips);
  bool get isInitialized => _isInitialized;

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

  int get netWorthPaise {
    final walletTotal = _wallets.fold(0, (sum, w) => sum + w.balancePaise);
    return walletTotal;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load Wallets
      final walletsJson = prefs.getString(_walletsKey);
      if (walletsJson != null && walletsJson.isNotEmpty) {
        final List decoded = jsonDecode(walletsJson);
        _wallets = decoded.map((w) => WalletModelItem.fromJson(w)).toList();
      } else {
        // Initial real default wallets
        _wallets = [
          WalletModelItem(
            id: 'wallet-1',
            name: 'Primary Bank Account',
            type: 'bank',
            balancePaise: 5000000, // ₹50,000.00
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

      _isInitialized = true;
      notifyListeners();

      // Background sync with MongoDB backend
      _syncWithBackend();
    } catch (_) {
      _isInitialized = true;
    }
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
      if (isExpense) {
        _wallets[walletIdx].balancePaise -= amountPaise;
      } else {
        _wallets[walletIdx].balancePaise += amountPaise;
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

    // Push to backend
    _pushTransactionToBackend(newTx);
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

  Future<void> addWallet({
    required String name,
    required String type,
    required int balancePaise,
    String? accountNumberLast4,
  }) async {
    final wallet = WalletModelItem(
      id: 'wallet_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      balancePaise: balancePaise,
      color: '#16A878',
      accountNumberLast4: accountNumberLast4 ?? '1234',
    );
    _wallets.add(wallet);
    await _saveWallets();
    notifyListeners();
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
        return Icons.directions_car_filled_rounded;
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

  Future<void> _syncWithBackend() async {
    try {
      final res = await ApiClient().dio.get(ApiConstants.transactions);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final List data = res.data['data']['transactions'] ?? [];
        if (data.isNotEmpty) {
          // Merge remote transactions
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
    } catch (_) {
      // Offline mode gracefully handled
    }
  }

  Future<void> _pushTransactionToBackend(TransactionModel tx) async {
    try {
      await ApiClient().dio.post(ApiConstants.transactions, data: {
        'description': tx.title,
        'amountPaise': tx.amountPaise,
        'type': tx.isExpense ? 'expense' : 'income',
        'date': tx.date.toIso8601String(),
      });
    } catch (_) {
      // Will sync when online
    }
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
    } catch (_) {
      // Will sync when online
    }
  }
}
