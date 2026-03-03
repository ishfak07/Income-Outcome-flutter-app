import 'dart:async';
import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';

/// ExpenseProvider manages expense state using Provider pattern.
/// Handles CRUD operations and aggregations for the current user.
class ExpenseProvider extends ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  List<ExpenseModel> _expenses = [];
  double _totalToday = 0;
  double _totalThisMonth = 0;
  Map<String, double> _categoryBreakdown = {};
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _expenseSubscription;

  // ─── GETTERS ─────────────────────────────────────────────────────────

  List<ExpenseModel> get expenses => _expenses;
  double get totalToday => _totalToday;
  double get totalThisMonth => _totalThisMonth;
  Map<String, double> get categoryBreakdown => _categoryBreakdown;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── STATE HELPERS ───────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── LOAD EXPENSES ──────────────────────────────────────────────────

  /// Listen to real-time expense updates for the user.
  void listenToExpenses(String userId) {
    // Cancel previous subscription to prevent memory leaks
    _expenseSubscription?.cancel();
    _expenseSubscription = _expenseService.getExpenses(userId).listen((expenses) {
      _expenses = expenses;
      notifyListeners();
    });
  }

  /// Load dashboard summary data.
  Future<void> loadDashboardData(String userId) async {
    _setLoading(true);
    try {
      _totalToday = await _expenseService.getTotalSpentToday(userId);
      _totalThisMonth = await _expenseService.getTotalSpentThisMonth(userId);
      _categoryBreakdown = await _expenseService.getCategoryBreakdown(userId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load dashboard data.';
    }
    _setLoading(false);
  }

  // ─── ADD EXPENSE ─────────────────────────────────────────────────────

  /// Add a new expense and refresh dashboard.
  Future<bool> addExpense(ExpenseModel expense) async {
    _setLoading(true);
    try {
      await _expenseService.addExpense(expense);
      await loadDashboardData(expense.userId);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Failed to add expense.';
      _setLoading(false);
      return false;
    }
  }

  // ─── UPDATE EXPENSE ──────────────────────────────────────────────────

  /// Update an existing expense and refresh dashboard.
  Future<bool> updateExpense(ExpenseModel expense) async {
    _setLoading(true);
    try {
      await _expenseService.updateExpense(expense);
      await loadDashboardData(expense.userId);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Failed to update expense.';
      _setLoading(false);
      return false;
    }
  }

  // ─── DELETE EXPENSE ──────────────────────────────────────────────────

  /// Delete an expense and refresh dashboard.
  Future<bool> deleteExpense(String userId, String expenseId) async {
    _setLoading(true);
    try {
      await _expenseService.deleteExpense(userId, expenseId);
      await loadDashboardData(userId);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Failed to delete expense.';
      _setLoading(false);
      return false;
    }
  }

  // ─── GET BY DATE ─────────────────────────────────────────────────────

  /// Get expenses for a specific date.
  Future<List<ExpenseModel>> getExpensesByDate(
      String userId, DateTime date) async {
    return await _expenseService.getExpensesByDate(userId, date);
  }

  /// Get expenses for a specific month.
  Future<List<ExpenseModel>> getExpensesByMonth(
      String userId, int year, int month) async {
    return await _expenseService.getExpensesByMonth(userId, year, month);
  }

  // ─── CLEAR ───────────────────────────────────────────────────────────

  /// Clear all expense data (on logout).
  void clear() {
    _expenseSubscription?.cancel();
    _expenseSubscription = null;
    _expenses = [];
    _totalToday = 0;
    _totalThisMonth = 0;
    _categoryBreakdown = {};
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _expenseSubscription?.cancel();
    super.dispose();
  }
}
