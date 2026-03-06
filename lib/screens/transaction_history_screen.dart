import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import 'expense_history_screen.dart';
import 'income_history_screen.dart';

/// TransactionHistoryScreen - Combined view for both expense and income history
/// with tab navigation between the two.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
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
              icon: Icon(Icons.arrow_upward_rounded),
              text: 'Expenses',
            ),
            Tab(
              icon: Icon(Icons.arrow_downward_rounded),
              text: 'Incomes',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ExpenseHistoryTab(),
          _IncomeHistoryTab(),
        ],
      ),
    );
  }
}

/// Wrapper widget for ExpenseHistoryScreen content
class _ExpenseHistoryTab extends StatelessWidget {
  const _ExpenseHistoryTab();

  @override
  Widget build(BuildContext context) {
    // Navigate to the full expense history screen
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 80,
            color: AppTheme.accentPink.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Expense History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap to view detailed expense records',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExpenseHistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.trending_up_rounded),
            label: const Text('View Expenses'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper widget for IncomeHistoryScreen content
class _IncomeHistoryTab extends StatelessWidget {
  const _IncomeHistoryTab();

  @override
  Widget build(BuildContext context) {
    // Navigate to the full income history screen
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.attach_money_rounded,
            size: 80,
            color: AppTheme.accentGreen.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Income History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap to view detailed income records',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IncomeHistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.trending_down_rounded),
            label: const Text('View Incomes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
