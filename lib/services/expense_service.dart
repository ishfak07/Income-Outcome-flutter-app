import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

/// ExpenseService handles all Firestore CRUD operations for expenses.
/// Each user's expenses are stored in a subcollection: users/{uid}/expenses
class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reference to a user's expenses collection.
  CollectionReference _expensesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('expenses');
  }

  // ─── CREATE ──────────────────────────────────────────────────────────

  /// Add a new expense for the given user.
  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    final docRef = await _expensesRef(expense.userId).add(expense.toMap());
    return ExpenseModel.fromMap(expense.toMap(), docRef.id);
  }

  // ─── READ ────────────────────────────────────────────────────────────

  /// Get all expenses for a user, ordered by date descending.
  Stream<List<ExpenseModel>> getExpenses(String userId) {
    return _expensesRef(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExpenseModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Get expenses for a specific date.
  Future<List<ExpenseModel>> getExpensesByDate(
      String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _expensesRef(userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThan: endOfDay.toIso8601String())
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return ExpenseModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  /// Get expenses for a specific month.
  Future<List<ExpenseModel>> getExpensesByMonth(
      String userId, int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final snapshot = await _expensesRef(userId)
        .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('date', isLessThan: endOfMonth.toIso8601String())
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return ExpenseModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  // ─── UPDATE ──────────────────────────────────────────────────────────

  /// Update an existing expense.
  Future<void> updateExpense(ExpenseModel expense) async {
    await _expensesRef(expense.userId).doc(expense.id).update(expense.toMap());
  }

  // ─── DELETE ──────────────────────────────────────────────────────────

  /// Delete an expense by ID.
  Future<void> deleteExpense(String userId, String expenseId) async {
    await _expensesRef(userId).doc(expenseId).delete();
  }

  // ─── AGGREGATIONS ────────────────────────────────────────────────────

  /// Calculate total spent today.
  Future<double> getTotalSpentToday(String userId) async {
    final today = DateTime.now();
    final expenses = await getExpensesByDate(userId, today);
    return expenses.fold<double>(0, (total, e) => total + e.amount);
  }

  /// Calculate total spent this month.
  Future<double> getTotalSpentThisMonth(String userId) async {
    final now = DateTime.now();
    final expenses = await getExpensesByMonth(userId, now.year, now.month);
    return expenses.fold<double>(0, (total, e) => total + e.amount);
  }

  /// Calculate total spent across all time.
  Future<double> getTotalSpentAllTime(String userId) async {
    final snapshot = await _expensesRef(userId).get();
    double total = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  /// Get category-wise breakdown for current month.
  Future<Map<String, double>> getCategoryBreakdown(String userId) async {
    final now = DateTime.now();
    final expenses = await getExpensesByMonth(userId, now.year, now.month);

    final breakdown = <String, double>{};
    for (final expense in expenses) {
      breakdown[expense.category] =
          (breakdown[expense.category] ?? 0) + expense.amount;
    }
    return breakdown;
  }
}
