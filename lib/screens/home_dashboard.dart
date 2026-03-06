import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/currency_provider.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/glass_card.dart';
import '../widgets/expense_card.dart';
import '../widgets/income_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/profile_avatar.dart';

/// HomeDashboard - Main screen showing financial overview with income,
/// expenses, and net balance summary cards plus recent transactions.
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final incomeProvider = context.read<IncomeProvider>();
    final uid = authProvider.currentUid;
    if (uid != null) {
      expenseProvider.listenToExpenses(uid);
      expenseProvider.loadDashboardData(uid);
      incomeProvider.listenToIncomes(uid);
      incomeProvider.loadDashboardData(uid);
      incomeProvider.processRecurringIncomes(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ─── APP BAR ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildHeader(isDark),
              ),
              // ─── SUMMARY CARDS ──────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildFinancialOverview(isDark),
              ),
              // ─── QUICK STATS ────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildSummaryCards(isDark, size),
              ),
              // ─── BUDGET PROGRESS ────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildBudgetProgress(isDark),
              ),
              // ─── CATEGORY BREAKDOWN ─────────────────────────────────
              SliverToBoxAdapter(
                child: _buildCategorySection(isDark),
              ),
              // ─── RECENT EXPENSES HEADER ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppConstants.historyRoute,
                        ),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
              ),
              // ─── EXPENSES LIST ──────────────────────────────────────
              _buildRecentTransactions(),
              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              // Profile avatar with photo support
              ProfileAvatar(
                avatarId: auth.user?.avatarId,
                name: auth.user?.fullName ?? 'U',
                size: 48,
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.profileRoute),
              ),
              const SizedBox(width: 12),
              // Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      auth.user?.fullName ?? 'User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              // Theme toggle
              Consumer<ThemeProvider>(
                builder: (context, theme, _) {
                  return IconButton(
                    onPressed: () => theme.toggleTheme(),
                    icon: Icon(
                      theme.isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  );
                },
              ),
              // Notification-style settings button
              IconButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppConstants.settingsRoute),
                icon: Icon(
                  Icons.settings_rounded,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  size: 22,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: -0.1, end: 0, duration: 400.ms);
      },
    );
  }

  /// Returns a time-of-day greeting.
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  // ─── FINANCIAL OVERVIEW ───────────────────────────────────────────

  Widget _buildFinancialOverview(bool isDark) {
    return Consumer2<IncomeProvider, ExpenseProvider>(
      builder: (context, incomeProvider, expenseProvider, _) {
        final totalIncome = incomeProvider.totalIncomeThisMonth;
        final totalExpense = expenseProvider.totalThisMonth;
        final netBalance = totalIncome - totalExpense;
        final savingsRate =
            totalIncome > 0 ? ((netBalance / totalIncome) * 100) : 0.0;

        final allTimeIncome = incomeProvider.totalIncomeAllTime;
        final allTimeExpense = expenseProvider.totalAllTime;
        final allTimeBalance = allTimeIncome - allTimeExpense;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              // All-Time Cumulative Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0D1B2A), const Color(0xFF1B2838)]
                        : [
                            AppTheme.accentPurple.withOpacity(0.08),
                            AppTheme.primaryColor.withOpacity(0.04),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : AppTheme.accentPurple.withOpacity(0.12),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'All-Time Balance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${allTimeBalance >= 0 ? '+' : '-'}${context.read<CurrencyProvider>().currencySymbol}${allTimeBalance.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: allTimeBalance >= 0
                            ? AppTheme.accentGreen
                            : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.trending_up_rounded,
                                  color: AppTheme.accentGreen, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${context.read<CurrencyProvider>().currencySymbol}${allTimeIncome.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 20,
                          width: 1,
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : const Color(0xFFE2E8F0),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.trending_down_rounded,
                                  color: AppTheme.accentPink, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${context.read<CurrencyProvider>().currencySymbol}${allTimeExpense.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentPink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // This Month Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                        : [
                            AppTheme.primaryColor.withOpacity(0.08),
                            AppTheme.accentPurple.withOpacity(0.05),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : AppTheme.primaryColor.withOpacity(0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Net Balance (This Month)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${netBalance >= 0 ? '+' : '-'}${context.read<CurrencyProvider>().currencySymbol}${netBalance.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: netBalance >= 0
                            ? AppTheme.accentGreen
                            : Colors.redAccent,
                      ),
                    ),
                    if (totalIncome > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: (savingsRate >= 0
                                  ? AppTheme.accentGreen
                                  : Colors.redAccent)
                              .withOpacity(0.15),
                        ),
                        child: Text(
                          'Savings Rate: ${savingsRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: savingsRate >= 0
                                ? AppTheme.accentGreen
                                : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.trending_up_rounded,
                                      color: AppTheme.accentGreen, size: 16),
                                  const SizedBox(width: 4),
                                  Text('Income',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white54
                                              : const Color(0xFF64748B))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${context.read<CurrencyProvider>().currencySymbol}${totalIncome.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : const Color(0xFFE2E8F0),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.trending_down_rounded,
                                      color: AppTheme.accentPink, size: 16),
                                  const SizedBox(width: 4),
                                  Text('Expenses',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white54
                                              : const Color(0xFF64748B))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${context.read<CurrencyProvider>().currencySymbol}${totalExpense.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentPink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 100.ms)
            .slideY(begin: 0.05, end: 0);
      },
    );
  }

  // ─── SUMMARY CARDS ─────────────────────────────────────────────────

  Widget _buildSummaryCards(bool isDark, Size size) {
    return Consumer2<IncomeProvider, ExpenseProvider>(
      builder: (context, incomeProvider, expenseProvider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Today Income',
                  amount: incomeProvider.totalIncomeToday,
                  icon: Icons.arrow_downward_rounded,
                  color: AppTheme.accentGreen,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  title: 'Today Expense',
                  amount: expenseProvider.totalToday,
                  icon: Icons.arrow_upward_rounded,
                  color: AppTheme.accentPink,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .slideY(begin: 0.1, end: 0, duration: 400.ms);
      },
    );
  }

  // ─── BUDGET PROGRESS ─────────────────────────────────────────────

  Widget _buildBudgetProgress(bool isDark) {
    return Consumer2<AuthProvider, ExpenseProvider>(
      builder: (context, auth, expenses, _) {
        final budget = auth.user?.monthlyBudget ?? 0;
        if (budget <= 0) return const SizedBox.shrink();

        final spent = expenses.totalThisMonth;
        final percent = (spent / budget).clamp(0.0, 1.0);
        final remaining = (budget - spent).clamp(0, budget);
        final barColor = percent > 0.9
            ? Colors.red
            : percent > 0.7
                ? AppTheme.accentOrange
                : AppTheme.accentGreen;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppConstants.budgetRoute),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    barColor.withOpacity(0.12),
                    barColor.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: barColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded,
                          color: barColor, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Budget',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(percent * 100).toStringAsFixed(0)}% used',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: barColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.08)
                          : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation(barColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${context.read<CurrencyProvider>().currencySymbol}${remaining.toStringAsFixed(2)} remaining of ${context.read<CurrencyProvider>().currencySymbol}${budget.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 300.ms)
            .slideY(begin: 0.05, end: 0);
      },
    );
  }

  // ─── CATEGORY BREAKDOWN ───────────────────────────────────────────

  Widget _buildCategorySection(bool isDark) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final breakdown = provider.categoryBreakdown;
        if (breakdown.isEmpty) return const SizedBox.shrink();

        final total = breakdown.values.fold<double>(0, (sum, v) => sum + v);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: GlassCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                ...breakdown.entries.map((entry) {
                  final percent = total > 0 ? (entry.value / total * 100) : 0.0;
                  final color = AppTheme.categoryColors[entry.key] ??
                      AppTheme.primaryColor;
                  final icon = ExpenseModel.categoryIcons[entry.key] ?? '📦';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(icon, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            Text(
                              '${context.read<CurrencyProvider>().currencySymbol}${entry.value.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${percent.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white38
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent / 100,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.05)
                                : const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.05, end: 0, duration: 300.ms);
                }),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
      },
    );
  }

  // ─── RECENT TRANSACTIONS (MERGED INCOME + EXPENSES) ─────────────────

  Widget _buildRecentTransactions() {
    return Consumer3<ExpenseProvider, IncomeProvider, AuthProvider>(
      builder: (context, expenseProvider, incomeProvider, authProvider, _) {
        final expenses = expenseProvider.expenses;
        final incomes = incomeProvider.incomes;

        if (expenses.isEmpty && incomes.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(),
          );
        }

        // Build a merged list of transactions sorted by date descending
        final List<_Transaction> transactions = [];

        for (final e in expenses) {
          transactions.add(_Transaction(
            type: _TransactionType.expense,
            date: e.date,
            expense: e,
          ));
        }
        for (final i in incomes) {
          transactions.add(_Transaction(
            type: _TransactionType.income,
            date: i.date,
            income: i,
          ));
        }

        transactions.sort((a, b) => b.date.compareTo(a.date));
        final recent = transactions.length > 12
            ? transactions.sublist(0, 12)
            : transactions;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final txn = recent[index];
              if (txn.type == _TransactionType.expense) {
                return ExpenseCard(
                  expense: txn.expense!,
                  index: index,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppConstants.editExpenseRoute,
                    arguments: txn.expense,
                  ),
                  onDelete: () {
                    final uid = authProvider.currentUid;
                    if (uid != null) {
                      expenseProvider.deleteExpense(uid, txn.expense!.id);
                    }
                  },
                );
              } else {
                return IncomeCard(
                  income: txn.income!,
                  index: index,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppConstants.editIncomeRoute,
                    arguments: txn.income,
                  ),
                  onDelete: () {
                    final uid = authProvider.currentUid;
                    if (uid != null) {
                      incomeProvider.deleteIncome(uid, txn.income!.id);
                    }
                  },
                );
              }
            },
            childCount: recent.length,
          ),
        );
      },
    );
  }

  // ─── FAB ─────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => _showAddTransactionSheet(),
      backgroundColor: AppTheme.primaryColor,
      child: const Icon(Icons.add_rounded, size: 28),
    ).animate().scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: 400.ms,
          delay: 800.ms,
          curve: Curves.elasticOut,
        );
  }

  void _showAddTransactionSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Transaction',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _TransactionTypeButton(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Expense',
                      color: AppTheme.accentPink,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(
                            context, AppConstants.addExpenseRoute);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TransactionTypeButton(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Income',
                      color: AppTheme.accentGreen,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(
                            context, AppConstants.addIncomeRoute);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── BOTTOM NAV ──────────────────────────────────────────────────────

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'History',
                isActive: false,
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.historyRoute),
              ),
              const SizedBox(width: 56), // Space for FAB
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Analytics',
                isActive: false,
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.statisticsRoute),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                isActive: false,
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.profileRoute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SUMMARY CARD WIDGET ─────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${context.read<CurrencyProvider>().currencySymbol}${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── NAV ITEM WIDGET ─────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive
                ? AppTheme.primaryColor
                : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? AppTheme.primaryColor
                  : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TRANSACTION TYPE BUTTON (bottom sheet) ─────────────────────────

class _TransactionTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _TransactionTypeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TRANSACTION HELPER TYPES ───────────────────────────────────────

enum _TransactionType { income, expense }

class _Transaction {
  final _TransactionType type;
  final DateTime date;
  final ExpenseModel? expense;
  final IncomeModel? income;

  _Transaction({
    required this.type,
    required this.date,
    this.expense,
    this.income,
  });
}
