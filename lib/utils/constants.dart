/// App-wide constants for Rumi Ishi Expense Tracker.
class AppConstants {
  static const String appName = 'Rumi Ishi';
  static const String appFullName = 'Rumi Ishi Expense Tracker';
  static const String appTagline = 'Track your expenses, simplify your life';

  // Route names
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String otpRoute = '/otp';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String homeRoute = '/home';
  static const String addExpenseRoute = '/add-expense';
  static const String editExpenseRoute = '/edit-expense';
  static const String historyRoute = '/history';
  static const String profileRoute = '/profile';
  static const String editProfileRoute = '/edit-profile';
  static const String statisticsRoute = '/statistics';
  static const String budgetRoute = '/budget';
  static const String settingsRoute = '/settings';
  static const String changePasswordRoute = '/change-password';
  static const String securitySettingsRoute = '/security-settings';
  static const String pinSetupRoute = '/pin-setup';
  static const String quickLoginRoute = '/quick-login';
  static const String addIncomeRoute = '/add-income';
  static const String editIncomeRoute = '/edit-income';
  static const String incomeHistoryRoute = '/income-history';
  static const String financialReportsRoute = '/financial-reports';
  static const String savingsGoalsRoute = '/savings-goals';
  static const String financialHealthRoute = '/financial-health';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String expensesCollection = 'expenses';
  static const String incomesCollection = 'incomes';
  static const String savingsGoalsCollection = 'savings_goals';

  // Currency
  static const String currencySymbol = '\$';

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);
}
