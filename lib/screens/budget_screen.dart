import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_button.dart';

/// BudgetScreen - Set and track monthly budgets with visual progress.
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null && user.monthlyBudget > 0) {
      _budgetController.text = user.monthlyBudget.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _updateBudget() async {
    final amount = double.tryParse(_budgetController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid budget amount'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final success = await context.read<AuthProvider>().updateBudget(amount);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Budget updated successfully!'),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Consumer2<AuthProvider, ExpenseProvider>(
            builder: (context, auth, expenseProvider, _) {
              final budget = auth.user?.monthlyBudget ?? 0;
              final spent = expenseProvider.totalThisMonth;
              final remaining = budget - spent;
              final progress =
                  budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
              final isOverBudget = spent > budget && budget > 0;

              return Column(
                children: [
                  // ─── BUDGET PROGRESS CIRCLE ─────────────────────────
                  _buildProgressSection(
                    isDark,
                    budget,
                    spent,
                    remaining,
                    progress,
                    isOverBudget,
                  ),
                  const SizedBox(height: 32),

                  // ─── SET BUDGET SECTION ─────────────────────────────
                  _buildSetBudgetSection(isDark, auth),
                  const SizedBox(height: 24),

                  // ─── CATEGORY BUDGET VIEW ───────────────────────────
                  _buildCategoryBreakdown(
                    isDark,
                    expenseProvider,
                    budget,
                  ),
                  const SizedBox(height: 24),

                  // ─── BUDGET TIPS ────────────────────────────────────
                  _buildBudgetTips(isDark, isOverBudget, progress),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(
    bool isDark,
    double budget,
    double spent,
    double remaining,
    double progress,
    bool isOverBudget,
  ) {
    final progressColor = isOverBudget
        ? Colors.red
        : progress > 0.8
            ? AppTheme.accentOrange
            : AppTheme.accentGreen;

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 90.0,
            lineWidth: 12.0,
            animation: true,
            animationDuration: 1200,
            percent: progress.toDouble(),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: progressColor,
                  ),
                ),
                Text(
                  'of budget',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: progressColor,
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BudgetStatItem(
                label: 'Budget',
                value:
                    '${context.read<CurrencyProvider>().currencySymbol}${budget.toStringAsFixed(0)}',
                color: AppTheme.primaryColor,
                isDark: isDark,
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
              _BudgetStatItem(
                label: 'Spent',
                value:
                    '${context.read<CurrencyProvider>().currencySymbol}${spent.toStringAsFixed(2)}',
                color: isOverBudget ? Colors.red : AppTheme.accentOrange,
                isDark: isDark,
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
              _BudgetStatItem(
                label: 'Remaining',
                value: remaining >= 0
                    ? '${context.read<CurrencyProvider>().currencySymbol}${remaining.toStringAsFixed(2)}'
                    : '-${context.read<CurrencyProvider>().currencySymbol}${remaining.abs().toStringAsFixed(2)}',
                color: remaining >= 0 ? AppTheme.accentGreen : Colors.red,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 400.ms,
        );
  }

  Widget _buildSetBudgetSection(bool isDark, AuthProvider auth) {
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Set Monthly Budget',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _budgetController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    prefixText:
                        '${context.read<CurrencyProvider>().currencySymbol} ',
                    prefixStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                    hintText: '0',
                    filled: true,
                    fillColor:
                        isDark ? AppTheme.darkCardAlt : const Color(0xFFF1F5F9),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _updateBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Set a monthly spending limit to stay on track',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildCategoryBreakdown(
    bool isDark,
    ExpenseProvider provider,
    double totalBudget,
  ) {
    final breakdown = provider.categoryBreakdown;
    if (breakdown.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Spending',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ...breakdown.entries.map((entry) {
            final color =
                AppTheme.categoryColors[entry.key] ?? AppTheme.primaryColor;
            final icon = ExpenseModel.categoryIcons[entry.key] ?? '📦';
            final percent = totalBudget > 0
                ? (entry.value / totalBudget * 100).clamp(0, 100)
                : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearPercentIndicator(
                    padding: EdgeInsets.zero,
                    lineHeight: 8,
                    percent: (percent / 100).toDouble(),
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.06)
                        : const Color(0xFFE2E8F0),
                    progressColor: color,
                    barRadius: const Radius.circular(4),
                    animation: true,
                    animationDuration: 800,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  Widget _buildBudgetTips(bool isDark, bool isOverBudget, double progress) {
    final tips = isOverBudget
        ? [
            '🚨 You\'ve exceeded your budget this month!',
            '💡 Review your top expenses and find areas to cut back.',
            '📊 Consider adjusting your budget for next month.',
          ]
        : progress > 0.8
            ? [
                '⚠️ You\'re close to your budget limit!',
                '💡 Be mindful of remaining spending this month.',
                '✨ Great job tracking your expenses consistently!',
              ]
            : [
                '✅ You\'re on track with your budget!',
                '💰 Keep up the smart spending habits.',
                '📈 Regular tracking helps build financial awareness.',
              ];

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tips_and_updates_rounded,
                  color: AppTheme.accentGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Budget Tips',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...tips.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                entry.value,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
  }
}

class _BudgetStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _BudgetStatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
