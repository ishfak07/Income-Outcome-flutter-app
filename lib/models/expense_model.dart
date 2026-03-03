/// Expense model for Rumi Ishi Expense Tracker.
/// Represents a single expense entry linked to a user.
class ExpenseModel {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String time;
  final String paymentMethod;
  final bool isRecurring;
  final String? recurringFrequency; // weekly, biweekly, monthly, yearly
  final DateTime? nextRecurringDate;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.time,
    this.paymentMethod = 'Cash',
    this.isRecurring = false,
    this.recurringFrequency,
    this.nextRecurringDate,
    required this.createdAt,
  });

  /// Predefined expense categories.
  static const List<String> categories = [
    'Food',
    'Transport',
    'Bills',
    'Shopping',
    'Entertainment',
    'Health',
    'Education',
    'Travel',
    'Groceries',
    'Subscriptions',
    'Other',
  ];

  /// Category icon mapping.
  static const Map<String, String> categoryIcons = {
    'Food': '🍔',
    'Transport': '🚗',
    'Bills': '📄',
    'Shopping': '🛍️',
    'Entertainment': '🎬',
    'Health': '💊',
    'Education': '📚',
    'Travel': '✈️',
    'Groceries': '🛒',
    'Subscriptions': '📱',
    'Other': '📦',
  };

  /// Payment method options.
  static const List<String> paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'Digital Wallet',
    'UPI',
    'Other',
  ];

  /// Recurring frequency options.
  static const List<String> recurringFrequencies = [
    'Weekly',
    'Bi-Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];

  /// Create ExpenseModel from Firestore document map.
  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? 'Other',
      description: map['description'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      time: map['time'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      isRecurring: map['isRecurring'] ?? false,
      recurringFrequency: map['recurringFrequency'],
      nextRecurringDate: map['nextRecurringDate'] != null
          ? DateTime.tryParse(map['nextRecurringDate'])
          : null,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Convert ExpenseModel to Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'paymentMethod': paymentMethod,
      'isRecurring': isRecurring,
      'recurringFrequency': recurringFrequency,
      'nextRecurringDate': nextRecurringDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with optional overrides.
  ExpenseModel copyWith({
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? time,
    String? paymentMethod,
    bool? isRecurring,
    String? recurringFrequency,
    DateTime? nextRecurringDate,
  }) {
    return ExpenseModel(
      id: id,
      userId: userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      nextRecurringDate: nextRecurringDate ?? this.nextRecurringDate,
      createdAt: createdAt,
    );
  }
}
