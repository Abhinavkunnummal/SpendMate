import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'scaffold_with_nav_bar.dart';

// Screens
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/phone_login_screen.dart';
import '../../features/auth/presentation/profile_setup_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/transactions/presentation/add_transaction_screen.dart';
import '../../features/transactions/presentation/transaction_details_screen.dart';
import '../../features/wallets/presentation/wallets_screen.dart';
import '../../features/budgets/presentation/budgets_screen.dart';
import '../../features/savings/presentation/savings_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/trips/presentation/trips_screen.dart';
import '../../features/trips/presentation/trip_details_screen.dart';
import '../../features/trips/presentation/trip_itinerary_screen.dart';
import '../../features/group_expenses/presentation/group_expenses_screen.dart';
import '../../features/group_expenses/presentation/add_group_expense_screen.dart';
import '../../features/group_expenses/presentation/split_expense_screen.dart';
import '../../features/settlements/presentation/balances_screen.dart';
import '../../features/settlements/presentation/settlement_details_screen.dart';
import '../../features/ai_assistant/presentation/ai_assistant_screen.dart';
import '../../features/receipts/presentation/receipt_scanner_screen.dart';
import '../../features/recurring/presentation/recurring_expenses_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDashboardKey = GlobalKey<NavigatorState>();
final _shellNavigatorTransactionsKey = GlobalKey<NavigatorState>();
final _shellNavigatorTripsKey = GlobalKey<NavigatorState>();
final _shellNavigatorAnalyticsKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/welcome',
  routes: [
    // Auth Routes
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(), // Screen 1
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const PhoneLoginScreen(), // Screen 2
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(), // Screen 3
    ),

    // Stateful Navigation Shell with Bottom Nav Bar
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Home Dashboard (Screen 4)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorDashboardKey,
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),

        // Tab 2: All Transactions (Screen 5)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorTransactionsKey,
          routes: [
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionsScreen(),
            ),
          ],
        ),

        // Tab 3: Trips (Screen 12)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorTripsKey,
          routes: [
            GoRoute(
              path: '/trips',
              builder: (context, state) => const TripsScreen(),
            ),
          ],
        ),

        // Tab 4: Analytics (Screen 11)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorAnalyticsKey,
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Modals & Standalone Feature Routes
    GoRoute(
      path: '/add-transaction',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final type = state.uri.queryParameters['type'];
        return AddTransactionScreen(initialType: type); // Screen 6
      },
    ),
    GoRoute(
      path: '/transactions/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return TransactionDetailsScreen(transactionId: id); // Screen 7
      },
    ),
    GoRoute(
      path: '/wallets',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WalletsScreen(), // Screen 8
    ),
    GoRoute(
      path: '/budgets',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BudgetsScreen(), // Screen 9
    ),
    GoRoute(
      path: '/savings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SavingsScreen(), // Screen 10
    ),
    GoRoute(
      path: '/trips/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return TripDetailsScreen(tripId: id); // Screen 13
      },
    ),
    GoRoute(
      path: '/trips/:id/itinerary',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return TripItineraryScreen(tripId: id); // Screen 14
      },
    ),
    GoRoute(
      path: '/trips/:id/expenses',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return GroupExpensesScreen(tripId: id); // Screen 15
      },
    ),
    GoRoute(
      path: '/trips/:id/add-expense',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return AddGroupExpenseScreen(tripId: id); // Screen 16
      },
    ),
    GoRoute(
      path: '/trips/:id/split-expense',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return SplitExpenseScreen(tripId: id); // Screen 17
      },
    ),
    GoRoute(
      path: '/trips/:id/balances',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return BalancesScreen(tripId: id); // Screen 18
      },
    ),
    GoRoute(
      path: '/settlements/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return SettlementDetailsScreen(settlementId: id); // Screen 19
      },
    ),
    GoRoute(
      path: '/ai-assistant',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AiAssistantScreen(), // Screen 20
    ),
    GoRoute(
      path: '/receipt-scanner',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReceiptScannerScreen(), // Screen 21
    ),
    GoRoute(
      path: '/recurring-expenses',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RecurringExpensesScreen(), // Screen 22
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsScreen(), // Screen 23
    ),
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileScreen(), // Screen 24
    ),
  ],
);
