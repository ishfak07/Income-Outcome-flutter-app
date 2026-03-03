import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/currency_provider.dart';
import '../utils/app_theme.dart';
import '../models/expense_model.dart';

/// FinancialReportsScreen - Displays monthly/weekly financial reports
/// with charts for income vs expenses, category breakdowns, and trends.
class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isBefore(DateTime(now.year, now.month + 1))) {
      setState(() {
        _selectedMonth = next;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor:
              isDark ? Colors.white54 : const Color(0xFF94A3B8),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Income'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Month Selector
          _buildMonthSelector(isDark),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(isDark),
                _buildIncomeTab(isDark),
                _buildExpensesTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: Icon(Icons.chevron_left_rounded,
                color: isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppTheme.primaryColor.withOpacity(0.1),
            ),
            child: Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: Icon(Icons.chevron_right_rounded,
                color: isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildOverviewTab(bool isDark) {
    return Consumer2<IncomeProvider, ExpenseProvider>(
      builder: (context, incomeProvider, expenseProvider, _) {
        final totalIncome = incomeProvider.totalIncomeThisMonth;
        final totalExpense = expenseProvider.totalThisMonth;
        final netBalance = totalIncome - totalExpense;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _ReportCard(
                      title: 'Total Income',
                      amount: totalIncome,
                      color: AppTheme.accentGreen,
                      icon: Icons.trending_up_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ReportCard(
                      title: 'Total Expenses',
                      amount: totalExpense,
                      color: AppTheme.accentPink,
                      icon: Icons.trending_down_rounded,
                      isDark: isDark,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 12),
              _ReportCard(
                title: 'Net Balance',
                amount: netBalance,
                color:
                    netBalance >= 0 ? AppTheme.accentGreen : Colors.redAccent,
                icon: Icons.account_balance_rounded,
                isDark: isDark,
                isWide: true,
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
              const SizedBox(height: 24),
              // Income vs Expense Bar Chart
              Text(
                'Income vs Expenses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: _buildComparisonChart(totalIncome, totalExpense, isDark),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              const SizedBox(height: 24),
              // Savings Info
              _buildSavingsInfo(totalIncome, totalExpense, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComparisonChart(double income, double expense, bool isDark) {
    final maxY = (income > expense ? income : expense) * 1.2;
    if (maxY == 0) {
      return Center(
        child: Text(
          'No data for this period',
          style: TextStyle(
            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
          ),
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = groupIndex == 0 ? 'Income' : 'Expenses';
              return BarTooltipItem(
                '$label\n${context.read<CurrencyProvider>().currencySymbol}${rod.toY.toStringAsFixed(2)}',
                TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final labels = ['Income', 'Expenses'];
                if (value.toInt() < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[value.toInt()],
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white54 : const Color(0xFF94A3B8),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: income,
                color: AppTheme.accentGreen,
                width: 40,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: expense,
                color: AppTheme.accentPink,
                width: 40,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsInfo(double income, double expense, bool isDark) {
    final savings = income - expense;
    final savingsRate = income > 0 ? (savings / income * 100) : 0.0;
    final isPositive = savings >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            (isPositive ? AppTheme.accentGreen : Colors.redAccent)
                .withOpacity(0.12),
            (isPositive ? AppTheme.accentGreen : Colors.redAccent)
                .withOpacity(0.04),
          ],
        ),
        border: Border.all(
          color: (isPositive ? AppTheme.accentGreen : Colors.redAccent)
              .withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.savings_rounded : Icons.warning_rounded,
            color: isPositive ? AppTheme.accentGreen : Colors.redAccent,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPositive ? 'You\'re saving!' : 'Overspending!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  isPositive
                      ? 'You saved ${context.read<CurrencyProvider>().currencySymbol}${savings.toStringAsFixed(2)} (${savingsRate.toStringAsFixed(1)}% of income)'
                      : 'You overspent by ${context.read<CurrencyProvider>().currencySymbol}${savings.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  Widget _buildIncomeTab(bool isDark) {
    return Consumer<IncomeProvider>(
      builder: (context, provider, _) {
        final breakdown = provider.incomeCategoryBreakdown;
        if (breakdown.isEmpty) {
          return _buildEmptyTab(
              'No income recorded this month', Icons.trending_up_rounded);
        }

        final total = breakdown.values.fold<double>(0, (s, v) => s + v);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pie Chart
              SizedBox(
                height: 200,
                child: _buildPieChart(breakdown, true, isDark),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 24),
              Text(
                'Income by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              ...breakdown.entries.map((e) {
                final percent = total > 0 ? (e.value / total * 100) : 0.0;
                return _CategoryRow(
                  category: e.key,
                  amount: e.value,
                  percent: percent,
                  color: _getIncomeCategoryColor(e.key),
                  isDark: isDark,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpensesTab(bool isDark) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final breakdown = provider.categoryBreakdown;
        if (breakdown.isEmpty) {
          return _buildEmptyTab(
              'No expenses recorded this month', Icons.trending_down_rounded);
        }

        final total = breakdown.values.fold<double>(0, (s, v) => s + v);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pie Chart
              SizedBox(
                height: 200,
                child: _buildPieChart(breakdown, false, isDark),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 24),
              Text(
                'Expenses by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              ...breakdown.entries.map((e) {
                final percent = total > 0 ? (e.value / total * 100) : 0.0;
                return _CategoryRow(
                  category: e.key,
                  amount: e.value,
                  percent: percent,
                  color:
                      AppTheme.categoryColors[e.key] ?? AppTheme.primaryColor,
                  isDark: isDark,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieChart(
      Map<String, double> breakdown, bool isIncome, bool isDark) {
    final total = breakdown.values.fold<double>(0, (s, v) => s + v);
    if (total == 0) return const SizedBox.shrink();

    final sections = breakdown.entries.map((e) {
      final percent = e.value / total * 100;
      final color = isIncome
          ? _getIncomeCategoryColor(e.key)
          : (AppTheme.categoryColors[e.key] ?? AppTheme.primaryColor);
      return PieChartSectionData(
        value: e.value,
        title: '${percent.toStringAsFixed(0)}%',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 30,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildEmptyTab(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getIncomeCategoryColor(String category) {
    const colors = {
      'Salary': Color(0xFF4CAF50),
      'Freelance': Color(0xFF2196F3),
      'Investments': Color(0xFF9C27B0),
      'Rental Income': Color(0xFFFF9800),
      'Business': Color(0xFF00BCD4),
      'Gifts': Color(0xFFE91E63),
      'Refunds': Color(0xFF607D8B),
      'Side Hustle': Color(0xFFFFEB3B),
      'Dividends': Color(0xFF3F51B5),
      'Other': Color(0xFF795548),
    };
    return colors[category] ?? AppTheme.primaryColor;
  }
}

// ─── HELPER WIDGETS ──────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isDark;
  final bool isWide;

  const _ReportCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    required this.isDark,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.2)),
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
            '${amount < 0 ? '-' : ''}${context.read<CurrencyProvider>().currencySymbol}${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isWide ? 28 : 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final double amount;
  final double percent;
  final Color color;
  final bool isDark;

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.percent,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
              Text(
                '${context.read<CurrencyProvider>().currencySymbol}${amount.toStringAsFixed(2)}',
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
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
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
              minHeight: 5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.03, end: 0);
  }
}
