import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/income_model.dart';
import '../providers/currency_provider.dart';
import '../utils/app_theme.dart';

/// IncomeCard - Displays a single income entry with swipe-to-delete.
class IncomeCard extends StatelessWidget {
  final IncomeModel income;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const IncomeCard({
    super.key,
    required this.income,
    this.index = 0,
    this.onTap,
    this.onDelete,
  });

  static const Map<String, Color> incomeCategoryColors = {
    'Salary': Color(0xFF00E676),
    'Freelance': Color(0xFF448AFF),
    'Investments': Color(0xFFFFD740),
    'Rental Income': Color(0xFF26A69A),
    'Business': Color(0xFF7C4DFF),
    'Gifts': Color(0xFFFF6B9D),
    'Refunds': Color(0xFF00E5FF),
    'Side Hustle': Color(0xFFFF9100),
    'Dividends': Color(0xFF69F0AE),
    'Other': Color(0xFF94A3B8),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = incomeCategoryColors[income.category] ?? AppTheme.accentGreen;
    final icon = IncomeModel.categoryIcons[income.category] ?? '📦';

    return Dismissible(
      key: Key(income.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.red.withOpacity(0.2),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? AppTheme.darkCard : Colors.white,
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withOpacity(0.15),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      income.description,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          income.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (income.isRecurring) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.repeat_rounded,
                              size: 12, color: color.withOpacity(0.7)),
                        ],
                        const SizedBox(width: 6),
                        Text(
                          '• ${DateFormat('MMM dd').format(income.date)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                '+${context.watch<CurrencyProvider>().currencySymbol}${income.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 50).ms)
        .slideX(begin: 0.05, end: 0, duration: 300.ms);
  }
}
