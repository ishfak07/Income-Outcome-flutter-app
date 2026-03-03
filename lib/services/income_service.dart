import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/income_model.dart';

/// IncomeService handles all Firestore CRUD operations for incomes.
/// Each user's incomes are stored in a subcollection: users/{uid}/incomes
class IncomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reference to a user's incomes collection.
  CollectionReference _incomesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('incomes');
  }

  // ─── CREATE ──────────────────────────────────────────────────────────

  /// Add a new income for the given user.
  Future<IncomeModel> addIncome(IncomeModel income) async {
    final docRef = await _incomesRef(income.userId).add(income.toMap());
    return IncomeModel.fromMap(income.toMap(), docRef.id);
  }

  // ─── READ ────────────────────────────────────────────────────────────

  /// Get all incomes for a user, ordered by date descending.
  Stream<List<IncomeModel>> getIncomes(String userId) {
    return _incomesRef(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return IncomeModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Get incomes for a specific date.
  Future<List<IncomeModel>> getIncomesByDate(
      String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _incomesRef(userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThan: endOfDay.toIso8601String())
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return IncomeModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  /// Get incomes for a specific month.
  Future<List<IncomeModel>> getIncomesByMonth(
      String userId, int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final snapshot = await _incomesRef(userId)
        .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('date', isLessThan: endOfMonth.toIso8601String())
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return IncomeModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  /// Get incomes for a specific year.
  Future<List<IncomeModel>> getIncomesByYear(String userId, int year) async {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);

    final snapshot = await _incomesRef(userId)
        .where('date', isGreaterThanOrEqualTo: startOfYear.toIso8601String())
        .where('date', isLessThan: endOfYear.toIso8601String())
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return IncomeModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  /// Get recurring incomes.
  Future<List<IncomeModel>> getRecurringIncomes(String userId) async {
    final snapshot = await _incomesRef(userId)
        .where('isRecurring', isEqualTo: true)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return IncomeModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  // ─── UPDATE ──────────────────────────────────────────────────────────

  /// Update an existing income.
  Future<void> updateIncome(IncomeModel income) async {
    await _incomesRef(income.userId).doc(income.id).update(income.toMap());
  }

  // ─── DELETE ──────────────────────────────────────────────────────────

  /// Delete an income by ID.
  Future<void> deleteIncome(String userId, String incomeId) async {
    await _incomesRef(userId).doc(incomeId).delete();
  }

  // ─── AGGREGATIONS ────────────────────────────────────────────────────

  /// Calculate total income today.
  Future<double> getTotalIncomeToday(String userId) async {
    final today = DateTime.now();
    final incomes = await getIncomesByDate(userId, today);
    return incomes.fold<double>(0, (total, i) => total + i.amount);
  }

  /// Calculate total income this month.
  Future<double> getTotalIncomeThisMonth(String userId) async {
    final now = DateTime.now();
    final incomes = await getIncomesByMonth(userId, now.year, now.month);
    return incomes.fold<double>(0, (total, i) => total + i.amount);
  }

  /// Calculate total income for previous month.
  Future<double> getTotalIncomePreviousMonth(String userId) async {
    final now = DateTime.now();
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final incomes = await getIncomesByMonth(userId, prevYear, prevMonth);
    return incomes.fold<double>(0, (total, i) => total + i.amount);
  }

  /// Get category-wise breakdown for current month.
  Future<Map<String, double>> getCategoryBreakdown(String userId) async {
    final now = DateTime.now();
    final incomes = await getIncomesByMonth(userId, now.year, now.month);

    final breakdown = <String, double>{};
    for (final income in incomes) {
      breakdown[income.category] =
          (breakdown[income.category] ?? 0) + income.amount;
    }
    return breakdown;
  }

  /// Get daily income totals for a date range (for charts).
  Future<Map<DateTime, double>> getDailyIncomeTotals(
      String userId, DateTime start, DateTime end) async {
    final snapshot = await _incomesRef(userId)
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThan: end.toIso8601String())
        .orderBy('date')
        .get();

    final dailyTotals = <DateTime, double>{};
    for (final doc in snapshot.docs) {
      final income = IncomeModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
      final day =
          DateTime(income.date.year, income.date.month, income.date.day);
      dailyTotals[day] = (dailyTotals[day] ?? 0) + income.amount;
    }
    return dailyTotals;
  }

  // ─── RECURRING INCOME PROCESSING ────────────────────────────────────

  /// Process recurring incomes - creates new income entries for due items.
  Future<void> processRecurringIncomes(String userId) async {
    final recurring = await getRecurringIncomes(userId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final income in recurring) {
      if (income.nextRecurringDate != null &&
          !income.nextRecurringDate!.isAfter(today)) {
        // Create new income entry
        final newIncome = IncomeModel(
          id: '',
          userId: userId,
          amount: income.amount,
          category: income.category,
          description: '${income.description} (Recurring)',
          date: today,
          time: income.time,
          paymentMethod: income.paymentMethod,
          isRecurring: false,
          createdAt: now,
        );
        await addIncome(newIncome);

        // Update next recurring date
        final nextDate = _calculateNextRecurringDate(
          today,
          income.recurringFrequency ?? 'Monthly',
        );
        await _incomesRef(userId).doc(income.id).update({
          'nextRecurringDate': nextDate.toIso8601String(),
        });
      }
    }
  }

  /// Calculate the next recurring date based on frequency.
  DateTime _calculateNextRecurringDate(DateTime from, String frequency) {
    switch (frequency.toLowerCase()) {
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'bi-weekly':
        return from.add(const Duration(days: 14));
      case 'monthly':
        return DateTime(from.year, from.month + 1, from.day);
      case 'quarterly':
        return DateTime(from.year, from.month + 3, from.day);
      case 'yearly':
        return DateTime(from.year + 1, from.month, from.day);
      default:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }
}
