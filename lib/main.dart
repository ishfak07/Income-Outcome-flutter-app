import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/income_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/currency_provider.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_dashboard.dart';
import 'screens/add_expense_screen.dart';
import 'screens/edit_expense_screen.dart';
import 'screens/expense_history_screen.dart';
import 'screens/add_income_screen.dart';
import 'screens/edit_income_screen.dart';
import 'screens/income_history_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/security_settings_screen.dart';
import 'screens/pin_setup_screen.dart';
import 'screens/quick_login_screen.dart';
import 'screens/financial_reports_screen.dart';
import 'screens/savings_goals_screen.dart';
import 'screens/financial_health_screen.dart';

/// Global flag to track Firebase initialization status.
bool firebaseInitialized = false;
String? firebaseError;

/// Entry point for Rumi Ishi Expense Tracker.
/// Initializes Firebase, theme, and sets up providers.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialize Firebase, but don't crash if it fails
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e) {
    firebaseError = e.toString();
    debugPrint('⚠️ Firebase initialization failed: $e');
    debugPrint('📌 Please follow FIREBASE_SETUP.md to configure Firebase.');
  }

  // Lock to portrait mode for consistent mobile experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const RumiIshiApp());
}

class RumiIshiApp extends StatelessWidget {
  const RumiIshiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => IncomeProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()..initialize()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appFullName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // ─── ROUTES ───────────────────────────────────────────
            initialRoute: AppConstants.splashRoute,
            routes: {
              AppConstants.splashRoute: (_) => const SplashScreen(),
              AppConstants.loginRoute: (_) => const LoginScreen(),
              AppConstants.registerRoute: (_) => const RegisterScreen(),
              AppConstants.otpRoute: (_) => const OtpVerificationScreen(),
              AppConstants.forgotPasswordRoute: (_) =>
                  const ForgotPasswordScreen(),
              AppConstants.homeRoute: (_) => const HomeDashboard(),
              AppConstants.addExpenseRoute: (_) => const AddExpenseScreen(),
              AppConstants.editExpenseRoute: (_) => const EditExpenseScreen(),
              AppConstants.historyRoute: (_) =>
                  const TransactionHistoryScreen(),
              AppConstants.addIncomeRoute: (_) => const AddIncomeScreen(),
              AppConstants.editIncomeRoute: (_) => const EditIncomeScreen(),
              AppConstants.incomeHistoryRoute: (_) =>
                  const IncomeHistoryScreen(),
              AppConstants.profileRoute: (_) => const ProfileScreen(),
              AppConstants.editProfileRoute: (_) => const EditProfileScreen(),
              AppConstants.statisticsRoute: (_) => const StatisticsScreen(),
              AppConstants.budgetRoute: (_) => const BudgetScreen(),
              AppConstants.settingsRoute: (_) => const SettingsScreen(),
              AppConstants.changePasswordRoute: (_) =>
                  const ChangePasswordScreen(),
              AppConstants.securitySettingsRoute: (_) =>
                  const SecuritySettingsScreen(),
              AppConstants.pinSetupRoute: (_) => const PinSetupScreen(),
              AppConstants.quickLoginRoute: (_) => const QuickLoginScreen(),
              AppConstants.financialReportsRoute: (_) =>
                  const FinancialReportsScreen(),
              AppConstants.savingsGoalsRoute: (_) => const SavingsGoalsScreen(),
              AppConstants.financialHealthRoute: (_) =>
                  const FinancialHealthScreen(),
            },

            // ─── PAGE TRANSITIONS ─────────────────────────────────
            onGenerateRoute: (settings) {
              // Smooth slide transitions for all routes
              final routes = {
                AppConstants.splashRoute: const SplashScreen(),
                AppConstants.loginRoute: const LoginScreen(),
                AppConstants.registerRoute: const RegisterScreen(),
                AppConstants.otpRoute: const OtpVerificationScreen(),
                AppConstants.forgotPasswordRoute: const ForgotPasswordScreen(),
                AppConstants.homeRoute: const HomeDashboard(),
                AppConstants.addExpenseRoute: const AddExpenseScreen(),
                AppConstants.editExpenseRoute: const EditExpenseScreen(),
                AppConstants.historyRoute: const TransactionHistoryScreen(),
                AppConstants.addIncomeRoute: const AddIncomeScreen(),
                AppConstants.editIncomeRoute: const EditIncomeScreen(),
                AppConstants.incomeHistoryRoute: const IncomeHistoryScreen(),
                AppConstants.profileRoute: const ProfileScreen(),
                AppConstants.editProfileRoute: const EditProfileScreen(),
                AppConstants.statisticsRoute: const StatisticsScreen(),
                AppConstants.budgetRoute: const BudgetScreen(),
                AppConstants.settingsRoute: const SettingsScreen(),
                AppConstants.changePasswordRoute: const ChangePasswordScreen(),
                AppConstants.securitySettingsRoute:
                    const SecuritySettingsScreen(),
                AppConstants.pinSetupRoute: const PinSetupScreen(),
                AppConstants.quickLoginRoute: const QuickLoginScreen(),
                AppConstants.financialReportsRoute:
                    const FinancialReportsScreen(),
                AppConstants.savingsGoalsRoute: const SavingsGoalsScreen(),
                AppConstants.financialHealthRoute:
                    const FinancialHealthScreen(),
              };

              final page = routes[settings.name];
              if (page != null) {
                return PageRouteBuilder(
                  settings: settings,
                  pageBuilder: (_, __, ___) => page,
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
