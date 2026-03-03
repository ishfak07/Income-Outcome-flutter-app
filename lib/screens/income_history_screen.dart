import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/income_provider.dart';
import '../providers/currency_provider.dart';
import '../models/income_model.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/income_card.dart';
import '../widgets/empty_state.dart';

/// IncomeHistoryScreen - Displays all income records with filtering,
/// sorting, search, and total income calculations.
class IncomeHistoryScreen extends StatefulWidget {
  const IncomeHistoryScreen({super.key});

  @override
  State<IncomeHistoryScreen> createState() => _IncomeHistoryScreenState();
}

class _IncomeHistoryScreenState extends State<IncomeHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date'; // date, amount, category
  bool _sortDescending = true;
  String? _filterCategory;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<IncomeModel> _filterAndSort(List<IncomeModel> incomes) {
    var filtered = incomes.where((income) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!income.description.toLowerCase().contains(query) &&
            !income.category.toLowerCase().contains(query) &&
            !income.amount.toStringAsFixed(2).contains(query)) {
          return false;
        }
      }
      // Category filter
      if (_filterCategory != null && income.category != _filterCategory) {
        return false;
      }
      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'amount':
          result = a.amount.compareTo(b.amount);
          break;
        case 'category':
          result = a.category.compareTo(b.category);
          break;
        case 'date':
        default:
          result = a.date.compareTo(b.date);
      }
      return _sortDescending ? -result : result;
    });

    return filtered;
  }

  List<IncomeModel> _filterByMonth(List<IncomeModel> incomes) {
    return incomes.where((income) {
      return income.date.year == _selectedMonth.year &&
          income.date.month == _selectedMonth.month;
    }).toList();
  }

  Map<String, List<IncomeModel>> _groupByDate(List<IncomeModel> incomes) {
    final grouped = <String, List<IncomeModel>>{};
    for (final income in incomes) {
      final key = DateFormat('yyyy-MM-dd').format(income.date);
      grouped.putIfAbsent(key, () => []).add(income);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGreen,
          labelColor: AppTheme.accentGreen,
          unselectedLabelColor:
              isDark ? Colors.white38 : const Color(0xFF94A3B8),
          tabs: const [
            Tab(text: 'All Income'),
            Tab(text: 'Monthly View'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.sort_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortDescending = !_sortDescending;
                } else {
                  _sortBy = value;
                  _sortDescending = true;
                }
              });
            },
            itemBuilder: (context) => [
              _buildSortMenuItem('date', 'Sort by Date'),
              _buildSortMenuItem('amount', 'Sort by Amount'),
              _buildSortMenuItem('category', 'Sort by Category'),
            ],
          ),
          PopupMenuButton<String?>(
            icon: Icon(
              Icons.filter_list_rounded,
              color: _filterCategory != null
                  ? AppTheme.accentGreen
                  : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
            onSelected: (value) => setState(() => _filterCategory = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Categories')),
              ...IncomeModel.categories.map(
                (cat) => PopupMenuItem(
                  value: cat,
                  child: Row(
                    children: [
                      Text(IncomeModel.categoryIcons[cat] ?? '📦'),
                      const SizedBox(width: 8),
                      Text(cat),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search incomes...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),

          // Total income bar
          Consumer<IncomeProvider>(
            builder: (context, provider, _) {
              final filtered = _filterAndSort(provider.incomes);
              final total =
                  filtered.fold<double>(0, (sum, i) => sum + i.amount);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentGreen.withOpacity(0.15),
                      AppTheme.accentGreen.withOpacity(0.05),
                    ],
                  ),
                  border:
                      Border.all(color: AppTheme.accentGreen.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_rounded,
                        color: AppTheme.accentGreen, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Total: ',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      '${context.read<CurrencyProvider>().currencySymbol}${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${filtered.length} entries',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllTab(),
                _buildMonthlyTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTab() {
    return Consumer2<IncomeProvider, AuthProvider>(
      builder: (context, incomeProvider, authProvider, _) {
        final filtered = _filterAndSort(incomeProvider.incomes);

        if (filtered.isEmpty) {
          return const EmptyState(
            icon: Icons.account_balance_wallet_rounded,
            title: 'No income records',
            subtitle: 'Your income entries will appear here',
          );
        }

        final grouped = _groupByDate(filtered);
        final dates = grouped.keys.toList();

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final dateKey = dates[index];
            final dayIncomes = grouped[dateKey]!;
            final date = DateTime.parse(dateKey);
            final dayTotal =
                dayIncomes.fold<double>(0, (sum, i) => sum + i.amount);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDateHeader(date),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54
                              : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '+${context.read<CurrencyProvider>().currencySymbol}${dayTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                ...dayIncomes.asMap().entries.map((entry) {
                  return IncomeCard(
                    income: entry.value,
                    index: entry.key,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppConstants.editIncomeRoute,
                      arguments: entry.value,
                    ),
                    onDelete: () {
                      final uid = authProvider.currentUid;
                      if (uid != null) {
                        incomeProvider.deleteIncome(uid, entry.value.id);
                      }
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

  Widget _buildMonthlyTab(bool isDark) {
    return Consumer2<IncomeProvider, AuthProvider>(
      builder: (context, incomeProvider, authProvider, _) {
        final monthlyIncomes =
            _filterByMonth(_filterAndSort(incomeProvider.incomes));
        final monthTotal =
            monthlyIncomes.fold<double>(0, (sum, i) => sum + i.amount);

        return Column(
          children: [
            // Month selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                        );
                      });
                    },
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedMonth,
                        firstDate: DateTime(2020),
                        lastDate: now,
                        initialEntryMode: DatePickerEntryMode.calendarOnly,
                      );
                      if (picked != null) {
                        setState(() => _selectedMonth = picked);
                      }
                    },
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
                    onPressed: () {
                      final next = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month + 1,
                      );
                      if (!next.isAfter(DateTime.now())) {
                        setState(() => _selectedMonth = next);
                      }
                    },
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),

            // Monthly total
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentGreen.withOpacity(0.12),
                    AppTheme.accentGreen.withOpacity(0.04),
                  ],
                ),
                border:
                    Border.all(color: AppTheme.accentGreen.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded,
                      color: AppTheme.accentGreen, size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Income',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${context.read<CurrencyProvider>().currencySymbol}${monthTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${monthlyIncomes.length} entries',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: monthlyIncomes.isEmpty
                  ? const EmptyState(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'No income this month',
                      subtitle:
                          'Income records for this month will appear here',
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: monthlyIncomes.length,
                      itemBuilder: (context, index) {
                        return IncomeCard(
                          income: monthlyIncomes[index],
                          index: index,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppConstants.editIncomeRoute,
                            arguments: monthlyIncomes[index],
                          ),
                          onDelete: () {
                            final uid = authProvider.currentUid;
                            if (uid != null) {
                              incomeProvider.deleteIncome(
                                  uid, monthlyIncomes[index].id);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    return DateFormat('EEEE, MMM dd').format(date);
  }

  PopupMenuItem<String> _buildSortMenuItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (_sortBy == value)
            Icon(
              _sortDescending
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 16,
              color: AppTheme.accentGreen,
            )
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
