import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import '../models/expense_model.dart';
import '../services/export_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/expense_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';

/// ExpenseHistoryScreen - View all expenses with filtering by date/month.
/// Supports export to CSV/PDF and monthly summary.
class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  // ignore: unused_field
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  Future<void> _exportData(String format) async {
    final authProvider = context.read<AuthProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final uid = authProvider.currentUid;
    if (uid == null) return;

    setState(() => _isExporting = true);

    try {
      final expenses = await expenseProvider.getExpensesByMonth(
        uid,
        _selectedMonth.year,
        _selectedMonth.month,
      );

      if (expenses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No expenses to export for this month.'),
              backgroundColor: AppTheme.accentOrange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        setState(() => _isExporting = false);
        return;
      }

      if (format == 'csv') {
        await ExportService.exportToCsv(expenses);
      } else {
        await ExportService.exportToPdf(expenses,
            currencySymbol: context.read<CurrencyProvider>().currencySymbol);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.file_download_outlined,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
            onSelected: _exportData,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Export as CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor:
              isDark ? Colors.white54 : const Color(0xFF94A3B8),
          tabs: const [
            Tab(text: 'All Expenses'),
            Tab(text: 'Monthly View'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllExpenses(isDark),
          _buildMonthlyView(isDark),
        ],
      ),
    );
  }

  // ─── ALL EXPENSES TAB ────────────────────────────────────────────────

  Widget _buildAllExpenses(bool isDark) {
    return Consumer2<ExpenseProvider, AuthProvider>(
      builder: (context, expenseProvider, authProvider, _) {
        final expenses = expenseProvider.expenses;

        if (expenses.isEmpty) {
          return const EmptyState(
            title: 'No expenses found',
            subtitle: 'Start tracking your expenses from the home screen',
          );
        }

        // Group expenses by date
        final grouped = <String, List<ExpenseModel>>{};
        for (final expense in expenses) {
          final key = DateFormat('yyyy-MM-dd').format(expense.date);
          grouped.putIfAbsent(key, () => []).add(expense);
        }

        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 16, bottom: 80),
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            final dateKey = sortedKeys[index];
            final dayExpenses = grouped[dateKey]!;
            final date = DateTime.parse(dateKey);
            final dayTotal =
                dayExpenses.fold<double>(0, (sum, e) => sum + e.amount);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDateHeader(date),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      Text(
                        '-${context.read<CurrencyProvider>().currencySymbol}${dayTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentPink,
                        ),
                      ),
                    ],
                  ),
                ),
                ...dayExpenses.asMap().entries.map((entry) {
                  return ExpenseCard(
                    expense: entry.value,
                    index: entry.key,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppConstants.editExpenseRoute,
                      arguments: entry.value,
                    ),
                    onDelete: () {
                      final uid = authProvider.currentUid;
                      if (uid == null) return;
                      expenseProvider.deleteExpense(
                        uid,
                        entry.value.id,
                      );
                    },
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  // ─── MONTHLY VIEW TAB ────────────────────────────────────────────────

  Widget _buildMonthlyView(bool isDark) {
    return Consumer2<ExpenseProvider, AuthProvider>(
      builder: (context, expenseProvider, authProvider, _) {
        return Column(
          children: [
            // Month selector
            _buildMonthSelector(isDark),
            // Monthly expenses
            Expanded(
              child: FutureBuilder<List<ExpenseModel>>(
                future: authProvider.currentUid != null
                    ? expenseProvider.getExpensesByMonth(
                        authProvider.currentUid!,
                        _selectedMonth.year,
                        _selectedMonth.month,
                      )
                    : Future.value([]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    );
                  }

                  final expenses = snapshot.data ?? [];
                  if (expenses.isEmpty) {
                    return EmptyState(
                      title: 'No expenses',
                      subtitle:
                          'No expenses for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                    );
                  }

                  final total =
                      expenses.fold<double>(0, (sum, e) => sum + e.amount);

                  return Column(
                    children: [
                      // Monthly total card
                      GlassCard(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        glowColor: AppTheme.primaryColor,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Spent',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${context.read<CurrencyProvider>().currencySymbol}${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${expenses.length}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  'transactions',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Expenses list
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            return ExpenseCard(
                              expense: expenses[index],
                              index: index,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppConstants.editExpenseRoute,
                                arguments: expenses[index],
                              ),
                              onDelete: () {
                                final uid = authProvider.currentUid;
                                if (uid == null) return;
                                expenseProvider.deleteExpense(
                                  uid,
                                  expenses[index].id,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          )
              .animate(key: ValueKey(_selectedMonth))
              .fadeIn(duration: 200.ms)
              .slideX(begin: 0.05, end: 0),
          IconButton(
            onPressed: _selectedMonth.isBefore(
                    DateTime(DateTime.now().year, DateTime.now().month))
                ? () => _changeMonth(1)
                : null,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: _selectedMonth.isBefore(
                      DateTime(DateTime.now().year, DateTime.now().month))
                  ? (isDark ? Colors.white70 : const Color(0xFF475569))
                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return DateFormat('EEEE, MMM dd').format(date);
  }
}
