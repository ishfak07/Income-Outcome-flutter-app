import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/currency_provider.dart';
import '../models/expense_model.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';

/// StatisticsScreen - Advanced analytics with charts and breakdowns.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  int _touchedPieIndex = -1;

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

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor:
              isDark ? Colors.white54 : const Color(0xFF94A3B8),
          tabs: const [
            Tab(
                text: 'Overview',
                icon: Icon(Icons.pie_chart_rounded, size: 20)),
            Tab(
                text: 'Cash Flow',
                icon: Icon(Icons.swap_vert_rounded, size: 20)),
            Tab(
                text: 'Trends',
                icon: Icon(Icons.trending_up_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(isDark),
          _buildCashFlowTab(isDark),
          _buildTrendsTab(isDark),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final cs = context.read<CurrencyProvider>().currencySymbol;
        final breakdown = provider.categoryBreakdown;
        final total = breakdown.values.fold<double>(0, (s, v) => s + v);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ─── MONTH SELECTOR ───────────────────────────────────
              _buildMonthSelector(isDark),
              const SizedBox(height: 20),

              // ─── OVERVIEW STATS ───────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Spent',
                      value: '$cs${provider.totalThisMonth.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppTheme.accentPink,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer<IncomeProvider>(
                      builder: (context, incomeProvider, _) {
                        return _StatCard(
                          title: 'Total Earned',
                          value:
                              '$cs${incomeProvider.totalIncomeThisMonth.toStringAsFixed(2)}',
                          icon: Icons.trending_up_rounded,
                          color: AppTheme.accentGreen,
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Avg / Day',
                      value: provider.totalThisMonth > 0
                          ? '$cs${(provider.totalThisMonth / DateTime.now().day).toStringAsFixed(2)}'
                          : '${cs}0.00',
                      icon: Icons.calendar_today_rounded,
                      color: AppTheme.accentCyan,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer<IncomeProvider>(
                      builder: (context, incomeProvider, _) {
                        final net = incomeProvider.totalIncomeThisMonth -
                            provider.totalThisMonth;
                        return _StatCard(
                          title: 'Net Balance',
                          value:
                              '${net >= 0 ? '+' : '-'}$cs${net.abs().toStringAsFixed(2)}',
                          icon: Icons.balance_rounded,
                          color: net >= 0
                              ? AppTheme.accentGreen
                              : Colors.redAccent,
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
              const SizedBox(height: 24),

              // ─── PIE CHART ────────────────────────────────────────
              if (breakdown.isNotEmpty) ...[
                GlassCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending by Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      response == null ||
                                      response.touchedSection == null) {
                                    _touchedPieIndex = -1;
                                    return;
                                  }
                                  _touchedPieIndex = response
                                      .touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            sections: _buildPieSections(breakdown, total),
                            sectionsSpace: 3,
                            centerSpaceRadius: 50,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Legend
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: breakdown.entries.map((entry) {
                          final color = AppTheme.categoryColors[entry.key] ??
                              AppTheme.primaryColor;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              ],

              const SizedBox(height: 24),

              // ─── TOP EXPENSES ─────────────────────────────────────
              if (provider.expenses.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Top Expenses This Month',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...(_getTopExpenses(provider.expenses, 5)
                    .asMap()
                    .entries
                    .map((entry) {
                  final expense = entry.value;
                  final index = entry.key;
                  return _TopExpenseItem(
                    expense: expense,
                    rank: index + 1,
                    isDark: isDark,
                  )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: (300 + index * 80).ms)
                      .slideX(begin: 0.05, end: 0);
                })),
              ],
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendsTab(bool isDark) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final cs = context.read<CurrencyProvider>().currencySymbol;
        final expenses = provider.expenses;

        // Group by day for last 7 days
        final now = DateTime.now();
        final dailyData = <String, double>{};
        for (int i = 6; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          final key = DateFormat('EEE').format(day);
          dailyData[key] = 0;
        }

        for (final expense in expenses) {
          final dayDiff = now.difference(expense.date).inDays;
          if (dayDiff >= 0 && dayDiff < 7) {
            final key = DateFormat('EEE').format(expense.date);
            dailyData[key] = (dailyData[key] ?? 0) + expense.amount;
          }
        }

        final maxValue = dailyData.values.isNotEmpty
            ? dailyData.values.reduce((a, b) => a > b ? a : b)
            : 1.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ─── WEEKLY BAR CHART ─────────────────────────────────
              GlassCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last 7 Days',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxValue * 1.2,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '$cs${rod.toY.toStringAsFixed(2)}',
                                  TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '$cs${value.toInt()}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark
                                          ? Colors.white38
                                          : const Color(0xFF94A3B8),
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final keys = dailyData.keys.toList();
                                  if (value.toInt() < keys.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        keys[value.toInt()],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white54
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: maxValue > 0 ? maxValue / 4 : 1,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : const Color(0xFFE2E8F0),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: dailyData.entries
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.value,
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor,
                                      AppTheme.accentPurple,
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  width: 22,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 20),

              // ─── SPENDING INSIGHTS ────────────────────────────────
              GlassCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentCyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: AppTheme.accentCyan,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Spending Insights',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InsightRow(
                      label: 'Highest day',
                      value: _getHighestDay(dailyData),
                      icon: Icons.arrow_upward_rounded,
                      color: AppTheme.accentPink,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _InsightRow(
                      label: 'Lowest day',
                      value: _getLowestDay(dailyData),
                      icon: Icons.arrow_downward_rounded,
                      color: AppTheme.accentGreen,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _InsightRow(
                      label: 'Weekly total',
                      value:
                          '$cs${dailyData.values.fold<double>(0, (s, v) => s + v).toStringAsFixed(2)}',
                      icon: Icons.summarize_rounded,
                      color: AppTheme.accentOrange,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _InsightRow(
                      label: 'Top category',
                      value: _getTopCategory(provider),
                      icon: Icons.category_rounded,
                      color: AppTheme.accentPurple,
                      isDark: isDark,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // ─── CASH FLOW TAB ─────────────────────────────────────────────────

  Widget _buildCashFlowTab(bool isDark) {
    return Consumer2<IncomeProvider, ExpenseProvider>(
      builder: (context, incomeProvider, expenseProvider, _) {
        final cs = context.read<CurrencyProvider>().currencySymbol;
        final totalIncome = incomeProvider.totalIncomeThisMonth;
        final totalExpense = expenseProvider.totalThisMonth;
        final netCashFlow = totalIncome - totalExpense;

        // Build daily cash flow for last 7 days
        final now = DateTime.now();
        final dailyIncome = <String, double>{};
        final dailyExpense = <String, double>{};
        for (int i = 6; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          final key = DateFormat('EEE').format(day);
          dailyIncome[key] = 0;
          dailyExpense[key] = 0;
        }

        for (final income in incomeProvider.incomes) {
          final dayDiff = now.difference(income.date).inDays;
          if (dayDiff >= 0 && dayDiff < 7) {
            final key = DateFormat('EEE').format(income.date);
            dailyIncome[key] = (dailyIncome[key] ?? 0) + income.amount;
          }
        }

        for (final expense in expenseProvider.expenses) {
          final dayDiff = now.difference(expense.date).inDays;
          if (dayDiff >= 0 && dayDiff < 7) {
            final key = DateFormat('EEE').format(expense.date);
            dailyExpense[key] = (dailyExpense[key] ?? 0) + expense.amount;
          }
        }

        final allValues = [
          ...dailyIncome.values,
          ...dailyExpense.values,
        ];
        final maxY = allValues.isNotEmpty
            ? allValues.reduce((a, b) => a > b ? a : b) * 1.3
            : 100.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Summary row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Income',
                      value: '$cs${totalIncome.toStringAsFixed(2)}',
                      icon: Icons.arrow_downward_rounded,
                      color: AppTheme.accentGreen,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Expenses',
                      value: '$cs${totalExpense.toStringAsFixed(2)}',
                      icon: Icons.arrow_upward_rounded,
                      color: AppTheme.accentPink,
                      isDark: isDark,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 12),
              // Net cash flow
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      (netCashFlow >= 0
                              ? AppTheme.accentGreen
                              : Colors.redAccent)
                          .withOpacity(0.12),
                      (netCashFlow >= 0
                              ? AppTheme.accentGreen
                              : Colors.redAccent)
                          .withOpacity(0.04),
                    ],
                  ),
                  border: Border.all(
                    color: (netCashFlow >= 0
                            ? AppTheme.accentGreen
                            : Colors.redAccent)
                        .withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      netCashFlow >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: netCashFlow >= 0
                          ? AppTheme.accentGreen
                          : Colors.redAccent,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Net Cash Flow',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '${netCashFlow >= 0 ? '+' : '-'}$cs${netCashFlow.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: netCashFlow >= 0
                                ? AppTheme.accentGreen
                                : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
              const SizedBox(height: 24),
              // Grouped bar chart: Income vs Expense by day
              GlassCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Cash Flow (Last 7 Days)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _LegendDot(
                            color: AppTheme.accentGreen, label: 'Income'),
                        const SizedBox(width: 16),
                        _LegendDot(
                            color: AppTheme.accentPink, label: 'Expenses'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxY == 0 ? 100 : maxY,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                final label =
                                    rodIndex == 0 ? 'Income' : 'Expense';
                                return BarTooltipItem(
                                  '$label\n$cs${rod.toY.toStringAsFixed(2)}',
                                  TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final keys = dailyIncome.keys.toList();
                                  if (value.toInt() < keys.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        keys[value.toInt()],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark
                                              ? Colors.white54
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: dailyIncome.keys
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                            final key = entry.value;
                            return BarChartGroupData(
                              x: entry.key,
                              barsSpace: 4,
                              barRods: [
                                BarChartRodData(
                                  toY: dailyIncome[key] ?? 0,
                                  color: AppTheme.accentGreen,
                                  width: 12,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                                BarChartRodData(
                                  toY: dailyExpense[key] ?? 0,
                                  color: AppTheme.accentPink,
                                  width: 12,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color:
            isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: Icon(
              Icons.chevron_left_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          IconButton(
            onPressed: _selectedMonth.month == DateTime.now().month &&
                    _selectedMonth.year == DateTime.now().year
                ? null
                : () => _changeMonth(1),
            icon: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
      Map<String, double> breakdown, double total) {
    final entries = breakdown.entries.toList();
    return entries.asMap().entries.map((mapEntry) {
      final index = mapEntry.key;
      final entry = mapEntry.value;
      final isTouched = index == _touchedPieIndex;
      final color = AppTheme.categoryColors[entry.key] ?? AppTheme.primaryColor;
      final percent = total > 0 ? (entry.value / total * 100) : 0.0;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percent.toStringAsFixed(0)}%',
        radius: isTouched ? 70 : 55,
        titlePositionPercentageOffset: 0.55,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<ExpenseModel> _getTopExpenses(List<ExpenseModel> expenses, int count) {
    final sorted = [...expenses]..sort((a, b) => b.amount.compareTo(a.amount));
    return sorted.take(count).toList();
  }

  String _getHighestDay(Map<String, double> data) {
    if (data.isEmpty) return '-';
    final max = data.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${max.key} (${context.read<CurrencyProvider>().currencySymbol}${max.value.toStringAsFixed(2)})';
  }

  String _getLowestDay(Map<String, double> data) {
    if (data.isEmpty) return '-';
    final nonZero = data.entries.where((e) => e.value > 0);
    if (nonZero.isEmpty) return '-';
    final min = nonZero.reduce((a, b) => a.value < b.value ? a : b);
    return '${min.key} (${context.read<CurrencyProvider>().currencySymbol}${min.value.toStringAsFixed(2)})';
  }

  String _getTopCategory(ExpenseProvider provider) {
    final breakdown = provider.categoryBreakdown;
    if (breakdown.isEmpty) return '-';
    final top = breakdown.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${top.key}';
  }
}

// ─── STAT CARD ──────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
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
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TOP EXPENSE ITEM ───────────────────────────────────────────────

class _TopExpenseItem extends StatelessWidget {
  final ExpenseModel expense;
  final int rank;
  final bool isDark;

  const _TopExpenseItem({
    required this.expense,
    required this.rank,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        AppTheme.categoryColors[expense.category] ?? AppTheme.primaryColor;
    final icon = ExpenseModel.categoryIcons[expense.category] ?? '📦';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.white.withOpacity(0.8),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: categoryColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description.isNotEmpty
                        ? expense.description
                        : expense.category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${expense.category} • ${DateFormat('MMM dd').format(expense.date)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${context.read<CurrencyProvider>().currencySymbol}${expense.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: categoryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── INSIGHT ROW ────────────────────────────────────────────────────

class _InsightRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _InsightRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

// ─── LEGEND DOT ─────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
