import 'dart:async';
import 'package:flutter/material.dart';
import '../models/income_model.dart';
import '../services/income_service.dart';

/// IncomeProvider manages income state using Provider pattern.
/// Handles CRUD operations and aggregations for the current user.
class IncomeProvider extends ChangeNotifier {
  final IncomeService _incomeService = IncomeService();

  List<IncomeModel> _incomes = [];
  double _totalIncomeToday = 0;
  double _totalIncomeThisMonth = 0;
  double _totalIncomeAllTime = 0;
  double _totalIncomePreviousMonth = 0;
  Map<String, double> _incomeCategoryBreakdown = {};
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _incomeSubscription;

  // ─── GETTERS ─────────────────────────────────────────────────────────

  List<IncomeModel> get incomes => _incomes;
  double get totalIncomeToday => _totalIncomeToday;
  double get totalIncomeThisMonth => _totalIncomeThisMonth;
  double get totalIncomeAllTime => _totalIncomeAllTime;
  double get totalIncomePreviousMonth => _totalIncomePreviousMonth;
  Map<String, double> get incomeCategoryBreakdown => _incomeCategoryBreakdown;
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

  // ─── LOAD INCOMES ───────────────────────────────────────────────────

  /// Listen to real-time income updates for the user.
  void listenToIncomes(String userId) {
    _incomeSubscription?.cancel();
    _incomeSubscription = _incomeService.getIncomes(userId).listen((incomes) {
      _incomes = incomes;
      notifyListeners();
    });
  }

  /// Load dashboard summary data.
  Future<void> loadDashboardData(String userId) async {
    _setLoading(true);
    try {
      _totalIncomeToday = await _incomeService.getTotalIncomeToday(userId);
      _totalIncomeThisMonth =
          await _incomeService.getTotalIncomeThisMonth(userId);
      _totalIncomeAllTime = await _incomeService.getTotalIncomeAllTime(userId);
      _totalIncomePreviousMonth =
          await _incomeService.getTotalIncomePreviousMonth(userId);
      _incomeCategoryBreakdown =
          await _incomeService.getCategoryBreakdown(userId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load income data.';
    }
    _setLoading(false);
  }

  // ─── ADD INCOME ──────────────────────────────────────────────────────

  /// Add a new income and refresh dashboard.
  Future<bool> addIncome(IncomeModel income) async {
    _setLoading(true);
    try {
      await _incomeService.addIncome(income);
      await loadDashboardData(income.userId);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Failed to add income.';
      _setLoading(false);
      return false;
    }
  }

  // ─── UPDATE INCOME ───────────────────────────────────────────────────

  /// Update an existing income and refresh dashboard.
  Future<bool> updateIncome(IncomeModel income) async {
    _setLoading(true);
    try {
      await _incomeService.updateIncome(income);
      await loadDashboardData(income.userId);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Failed to update income.';
      _setLoading(false);
      return false;
    }
  }

  // ─── DELETE INCOME ───────────────────────────────────────────────────

  /// Delete an income and refresh dashboard.
  Future<bool> deleteIncome(String userId, String incomeId) async {
    _setLoading(true);
    try {
      await _incomeService.deleteIncome(userId, incomeId);
      await loadDashboardData(userId);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Failed to delete income.';
      _setLoading(false);
      return false;
    }
  }

  // ─── GET BY DATE ─────────────────────────────────────────────────────

  /// Get incomes for a specific date.
  Future<List<IncomeModel>> getIncomesByDate(
      String userId, DateTime date) async {
    return await _incomeService.getIncomesByDate(userId, date);
  }

  /// Get incomes for a specific month.
  Future<List<IncomeModel>> getIncomesByMonth(
      String userId, int year, int month) async {
    return await _incomeService.getIncomesByMonth(userId, year, month);
  }

  /// Get recurring incomes.
  Future<List<IncomeModel>> getRecurringIncomes(String userId) async {
    return await _incomeService.getRecurringIncomes(userId);
  }

  /// Process any due recurring incomes.
  Future<void> processRecurringIncomes(String userId) async {
    try {
      await _incomeService.processRecurringIncomes(userId);
      await loadDashboardData(userId);
    } catch (e) {
      _error = 'Failed to process recurring incomes.';
      notifyListeners();
    }
  }

  // ─── ANALYTICS HELPERS ──────────────────────────────────────────────

  /// Monthly income change percentage.
  double get monthlyIncomeChange {
    if (_totalIncomePreviousMonth > 0) {
      return ((_totalIncomeThisMonth - _totalIncomePreviousMonth) /
              _totalIncomePreviousMonth) *
          100;
    }
    return 0;
  }

  /// Get daily income totals for charts.
  Future<Map<DateTime, double>> getDailyIncomeTotals(
      String userId, DateTime start, DateTime end) async {
    return await _incomeService.getDailyIncomeTotals(userId, start, end);
  }

  // ─── CLEAR ───────────────────────────────────────────────────────────

  /// Clear all income data (on logout).
  void clear() {
    _incomeSubscription?.cancel();
    _incomeSubscription = null;
    _incomes = [];
    _totalIncomeToday = 0;
    _totalIncomeThisMonth = 0;
    _totalIncomeAllTime = 0;
    _totalIncomePreviousMonth = 0;
    _incomeCategoryBreakdown = {};
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _incomeSubscription?.cancel();
    super.dispose();
  }
}
