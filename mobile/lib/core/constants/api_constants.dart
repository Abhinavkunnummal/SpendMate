class ApiConstants {
  // Use Android emulator 10.0.2.2 or production domain
  static const String baseUrl = 'http://10.0.2.2:5000/api/v1';
  static const String socketUrl = 'http://10.0.2.2:5000';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh';
  static const String profile = '/auth/profile';

  // Personal Finance
  static const String wallets = '/wallets';
  static const String categories = '/categories';
  static const String transactions = '/transactions';
  static const String budgets = '/budgets';
  static const String savings = '/savings';
  static const String analytics = '/analytics';

  // Trips & Group Expenses
  static const String trips = '/trips';
  static const String groupExpenses = '/trip-expenses';
  static const String settlements = '/settlements';
  static const String itineraries = '/itineraries';

  // Smart Features
  static const String receipts = '/receipts';
  static const String aiAssistant = '/ai-assistant';
  static const String recurring = '/recurring-expenses';
  static const String notifications = '/notifications';
  static const String sync = '/sync';
}
