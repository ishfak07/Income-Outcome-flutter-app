/// Financial summary model for dashboard aggregations.
/// Combines income and expense data for unified display.
class FinancialSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netBalance;
  final double savingsRate;
  final Map<String, double> incomeByCategory;
  final Map<String, double> expenseByCategory;
  final List<DailyBalance> dailyBalances;
  final double previousPeriodIncome;
  final double previousPeriodExpenses;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netBalance,
    required this.savingsRate,
    required this.incomeByCategory,
    required this.expenseByCategory,
    this.dailyBalances = const [],
    this.previousPeriodIncome = 0,
    this.previousPeriodExpenses = 0,
  });

  /// Income change percentage compared to previous period.
  double get incomeChange => previousPeriodIncome > 0
      ? ((totalIncome - previousPeriodIncome) / previousPeriodIncome) * 100
      : 0;

  /// Expense change percentage compared to previous period.
  double get expenseChange => previousPeriodExpenses > 0
      ? ((totalExpenses - previousPeriodExpenses) / previousPeriodExpenses) *
          100
      : 0;

  factory FinancialSummary.empty() {
    return FinancialSummary(
      totalIncome: 0,
      totalExpenses: 0,
      netBalance: 0,
      savingsRate: 0,
      incomeByCategory: {},
      expenseByCategory: {},
    );
  }
}

/// Represents daily income/expense totals for trend charts.
class DailyBalance {
  final DateTime date;
  final double income;
  final double expense;

  DailyBalance({
    required this.date,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;
}

/// Budget model for income-based planning.
class BudgetPlan {
  final String id;
  final String userId;
  final String category;
  final double allocatedAmount;
  final double allocatedPercentage;
  final double spentAmount;
  final DateTime month;

  BudgetPlan({
    required this.id,
    required this.userId,
    required this.category,
    required this.allocatedAmount,
    required this.allocatedPercentage,
    required this.spentAmount,
    required this.month,
  });

  double get remainingAmount => allocatedAmount - spentAmount;
  double get usagePercentage =>
      allocatedAmount > 0 ? (spentAmount / allocatedAmount) * 100 : 0;
  bool get isOverBudget => spentAmount > allocatedAmount;

  factory BudgetPlan.fromMap(Map<String, dynamic> map, String id) {
    return BudgetPlan(
      id: id,
      userId: map['userId'] ?? '',
      category: map['category'] ?? '',
      allocatedAmount: (map['allocatedAmount'] ?? 0).toDouble(),
      allocatedPercentage: (map['allocatedPercentage'] ?? 0).toDouble(),
      spentAmount: (map['spentAmount'] ?? 0).toDouble(),
      month: DateTime.tryParse(map['month'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'allocatedAmount': allocatedAmount,
      'allocatedPercentage': allocatedPercentage,
      'spentAmount': spentAmount,
      'month': month.toIso8601String(),
    };
  }
}

/// Savings goal model.
class SavingsGoal {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final DateTime createdAt;
  final String? icon;
  final String? color;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.createdAt,
    this.icon,
    this.color,
  });

  double get progressPercentage =>
      targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;
  double get remainingAmount =>
      (targetAmount - currentAmount).clamp(0, targetAmount);
  bool get isCompleted => currentAmount >= targetAmount;

  /// Days remaining to target date.
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;

  /// Projected daily savings needed to reach goal.
  double get dailySavingsNeeded =>
      daysRemaining > 0 ? remainingAmount / daysRemaining : remainingAmount;

  factory SavingsGoal.fromMap(Map<String, dynamic> map, String id) {
    return SavingsGoal(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      currentAmount: (map['currentAmount'] ?? 0).toDouble(),
      targetDate: DateTime.tryParse(map['targetDate'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      icon: map['icon'],
      color: map['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'icon': icon,
      'color': color,
    };
  }
}
