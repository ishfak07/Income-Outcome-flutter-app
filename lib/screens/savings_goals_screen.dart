import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/financial_summary.dart';
import '../providers/currency_provider.dart';
import '../utils/app_theme.dart';

/// SavingsGoalsScreen - Create and track savings goals with progress bars,
/// daily savings needed calculations, and goal management.
class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  final List<SavingsGoal> _goals = [];

  @override
  void initState() {
    super.initState();
    // Load some demo goals — in production, load from Firestore
    _goals.addAll([
      SavingsGoal(
        id: '1',
        userId: '',
        name: 'Emergency Fund',
        targetAmount: 10000,
        currentAmount: 3500,
        targetDate: DateTime.now().add(const Duration(days: 180)),
        icon: '🛡️',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      SavingsGoal(
        id: '2',
        userId: '',
        name: 'Vacation',
        targetAmount: 3000,
        currentAmount: 1200,
        targetDate: DateTime.now().add(const Duration(days: 90)),
        icon: '✈️',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _goals.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _goals.length + 1, // +1 for summary header
              itemBuilder: (context, index) {
                if (index == 0) return _buildSummaryHeader(isDark);
                return _buildGoalCard(_goals[index - 1], isDark, index - 1);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(isDark),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal'),
      ).animate().scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
            duration: 400.ms,
            delay: 300.ms,
            curve: Curves.elasticOut,
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.savings_rounded,
              size: 64, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'No savings goals yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first savings goal',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(bool isDark) {
    final totalTarget = _goals.fold<double>(0, (s, g) => s + g.targetAmount);
    final totalSaved = _goals.fold<double>(0, (s, g) => s + g.currentAmount);
    final overallProgress = totalTarget > 0 ? totalSaved / totalTarget : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : AppTheme.primaryColor.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 50,
            lineWidth: 8,
            percent: overallProgress.clamp(0, 1),
            center: Text(
              '${(overallProgress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            progressColor: AppTheme.accentGreen,
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 12),
          Text(
            'Overall Progress',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${context.read<CurrencyProvider>().currencySymbol}${totalSaved.toStringAsFixed(2)} of ${context.read<CurrencyProvider>().currencySymbol}${totalTarget.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildGoalCard(SavingsGoal goal, bool isDark, int index) {
    final progress = goal.progressPercentage / 100;
    final daysLeft = goal.daysRemaining;
    final dailySavings = goal.dailySavingsNeeded;
    final progressColor = progress >= 1.0
        ? AppTheme.accentGreen
        : progress >= 0.5
            ? AppTheme.accentCyan
            : AppTheme.accentOrange;

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
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(goal.icon ?? '🎯', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '$daysLeft days remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    size: 20),
                onPressed: () {
                  setState(() => _goals.removeAt(index));
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${context.read<CurrencyProvider>().currencySymbol}${goal.currentAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: progressColor,
                ),
              ),
              Text(
                '${context.read<CurrencyProvider>().currencySymbol}${goal.targetAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(1)}% complete',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.speed_rounded, size: 14, color: progressColor),
                  const SizedBox(width: 4),
                  Text(
                    '${context.read<CurrencyProvider>().currencySymbol}${dailySavings.toStringAsFixed(2)}/day needed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddFundsDialog(goal, isDark),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Funds'),
              style: OutlinedButton.styleFrom(
                foregroundColor: progressColor,
                side: BorderSide(color: progressColor.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: 100 * index))
        .slideY(begin: 0.05, end: 0);
  }

  void _showAddGoalDialog(bool isDark) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    String selectedIcon = '🎯';
    DateTime deadline = DateTime.now().add(const Duration(days: 90));

    final icons = ['🎯', '🏠', '🚗', '✈️', '📱', '💍', '🎓', '🛡️', '💰', '🎁'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Savings Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon picker
                    Wrap(
                      spacing: 8,
                      children: icons.map((icon) {
                        final isSelected = icon == selectedIcon;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedIcon = icon),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: isSelected
                                  ? AppTheme.primaryColor.withOpacity(0.15)
                                  : Colors.transparent,
                              border: isSelected
                                  ? Border.all(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.5))
                                  : null,
                            ),
                            child: Text(icon,
                                style: const TextStyle(fontSize: 24)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Goal Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Target Amount',
                        prefixText:
                            '${context.read<CurrencyProvider>().currencySymbol} ',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Deadline'),
                      trailing: Text(
                        '${deadline.month}/${deadline.day}/${deadline.year}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: deadline,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setDialogState(() => deadline = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final target =
                        double.tryParse(targetController.text.trim()) ?? 0;
                    if (name.isNotEmpty && target > 0) {
                      setState(() {
                        _goals.add(SavingsGoal(
                          id: const Uuid().v4(),
                          userId: '',
                          name: name,
                          targetAmount: target,
                          currentAmount: 0,
                          targetDate: deadline,
                          icon: selectedIcon,
                          createdAt: DateTime.now(),
                        ));
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddFundsDialog(SavingsGoal goal, bool isDark) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Add Funds to ${goal.name}'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '${context.read<CurrencyProvider>().currencySymbol} ',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                if (amount > 0) {
                  setState(() {
                    final idx = _goals.indexWhere((g) => g.id == goal.id);
                    if (idx >= 0) {
                      final old = _goals[idx];
                      _goals[idx] = SavingsGoal(
                        id: old.id,
                        userId: old.userId,
                        name: old.name,
                        targetAmount: old.targetAmount,
                        currentAmount: old.currentAmount + amount,
                        targetDate: old.targetDate,
                        icon: old.icon,
                        createdAt: old.createdAt,
                      );
                    }
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
