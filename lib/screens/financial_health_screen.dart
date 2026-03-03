import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/income_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

/// FinancialHealthScreen - Provides an overall financial health score
/// based on savings rate, budget adherence, income stability, and
/// expense diversity. Shows actionable tips for improvement.
class FinancialHealthScreen extends StatelessWidget {
  const FinancialHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Health'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer3<IncomeProvider, ExpenseProvider, AuthProvider>(
        builder: (context, incomeProvider, expenseProvider, authProvider, _) {
          final totalIncome = incomeProvider.totalIncomeThisMonth;
          final totalExpense = expenseProvider.totalThisMonth;
          final budget = authProvider.user?.monthlyBudget ?? 0;

          // Calculate health score components
          final savingsRate = totalIncome > 0
              ? ((totalIncome - totalExpense) / totalIncome)
              : 0.0;
          final budgetAdherence = budget > 0
              ? (1 - (totalExpense / budget)).clamp(0.0, 1.0)
              : 0.5; // neutral if no budget set
          final incomeExpenseRatio = totalExpense > 0
              ? (totalIncome / totalExpense).clamp(0.0, 2.0) / 2
              : 0.5;

          // Weighted score: 40% savings, 30% budget, 30% ratio
          final healthScore = ((savingsRate.clamp(0, 1) * 40) +
                  (budgetAdherence * 30) +
                  (incomeExpenseRatio * 30))
              .clamp(0, 100)
              .toDouble();

          final scoreColor = healthScore >= 70
              ? AppTheme.accentGreen
              : healthScore >= 40
                  ? AppTheme.accentOrange
                  : Colors.redAccent;

          final scoreLabel = healthScore >= 70
              ? 'Excellent'
              : healthScore >= 40
                  ? 'Fair'
                  : 'Needs Improvement';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Overall Score
                _buildScoreCard(
                  healthScore,
                  scoreColor,
                  scoreLabel,
                  isDark,
                ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                    ),
                const SizedBox(height: 24),
                // Score Breakdown
                Text(
                  'Score Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMetric(
                  'Savings Rate',
                  '${(savingsRate * 100).toStringAsFixed(1)}%',
                  savingsRate.clamp(0, 1).toDouble(),
                  savingsRate >= 0.2
                      ? AppTheme.accentGreen
                      : savingsRate >= 0
                          ? AppTheme.accentOrange
                          : Colors.redAccent,
                  Icons.savings_rounded,
                  isDark,
                  0,
                ),
                _buildMetric(
                  'Budget Adherence',
                  budget > 0
                      ? '${(budgetAdherence * 100).toStringAsFixed(0)}%'
                      : 'No budget set',
                  budgetAdherence.toDouble(),
                  budgetAdherence >= 0.5
                      ? AppTheme.accentGreen
                      : AppTheme.accentOrange,
                  Icons.account_balance_wallet_rounded,
                  isDark,
                  1,
                ),
                _buildMetric(
                  'Income/Expense Ratio',
                  totalExpense > 0
                      ? '${(totalIncome / totalExpense).toStringAsFixed(2)}x'
                      : 'N/A',
                  incomeExpenseRatio.toDouble(),
                  incomeExpenseRatio >= 0.5
                      ? AppTheme.accentGreen
                      : Colors.redAccent,
                  Icons.compare_arrows_rounded,
                  isDark,
                  2,
                ),
                const SizedBox(height: 24),
                // Tips
                Text(
                  'Tips to Improve',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                ..._getTips(savingsRate, budgetAdherence, budget, totalIncome,
                        totalExpense)
                    .asMap()
                    .entries
                    .map((entry) {
                  return _buildTipCard(entry.value, isDark, entry.key);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreCard(double score, Color color, String label, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [color.withOpacity(0.08), color.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.1) : color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 70,
            lineWidth: 10,
            percent: (score / 100).clamp(0, 1),
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  score.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  '/100',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            progressColor: color,
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: color.withOpacity(0.15),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Financial Health Score',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String title, String value, double progress, Color color,
      IconData icon, bool isDark, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
            duration: 400.ms, delay: Duration(milliseconds: 200 + index * 100))
        .slideX(begin: 0.05, end: 0);
  }

  List<_Tip> _getTips(double savingsRate, double budgetAdherence, double budget,
      double income, double expense) {
    final tips = <_Tip>[];

    if (savingsRate < 0.2) {
      tips.add(_Tip(
        icon: Icons.savings_rounded,
        title: 'Increase Savings',
        description:
            'Aim to save at least 20% of your income. Consider automating transfers to a savings account.',
        color: AppTheme.accentOrange,
      ));
    }
    if (budget <= 0) {
      tips.add(_Tip(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Set a Monthly Budget',
        description:
            'Creating a budget helps you track spending and avoid overspending.',
        color: AppTheme.accentCyan,
      ));
    } else if (budgetAdherence < 0.3) {
      tips.add(_Tip(
        icon: Icons.warning_rounded,
        title: 'Review Your Budget',
        description:
            'You\'re significantly over budget. Consider cutting non-essential expenses.',
        color: Colors.redAccent,
      ));
    }
    if (income <= 0 && expense > 0) {
      tips.add(_Tip(
        icon: Icons.trending_up_rounded,
        title: 'Track Your Income',
        description:
            'Start recording your income to get a complete picture of your finances.',
        color: AppTheme.accentGreen,
      ));
    }
    if (expense > income && income > 0) {
      tips.add(_Tip(
        icon: Icons.trending_down_rounded,
        title: 'Reduce Expenses',
        description:
            'Your expenses exceed your income. Review subscriptions and discretionary spending.',
        color: AppTheme.accentPink,
      ));
    }
    if (tips.isEmpty) {
      tips.add(_Tip(
        icon: Icons.check_circle_rounded,
        title: 'Keep It Up!',
        description:
            'Your financial health is looking good. Keep maintaining your current habits.',
        color: AppTheme.accentGreen,
      ));
    }

    return tips;
  }

  Widget _buildTipCard(_Tip tip, bool isDark, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            tip.color.withOpacity(0.1),
            tip.color.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: tip.color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(tip.icon, color: tip.color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.description,
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
    )
        .animate()
        .fadeIn(
            duration: 400.ms, delay: Duration(milliseconds: 400 + index * 100))
        .slideY(begin: 0.05, end: 0);
  }
}

class _Tip {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _Tip({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
