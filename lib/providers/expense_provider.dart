import 'package:flutter/foundation.dart';

import '../models/expense_model.dart';
import '../services/api_service.dart';
import '../services/expense_service.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider({required ExpenseService expenseService})
      : _expenseService = expenseService;

  final ExpenseService _expenseService;

  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String? _error;
  double _monthlyTotal = 0;

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get monthlyTotal => _monthlyTotal;

  DateTime get _now => DateTime.now();

  int get currentYear => _now.year;

  double get currentYearTotal {
    final year = currentYear;
    return _expenses
        .where((expense) => expense.date.year == year)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double get currentMonthTotalFromList {
    final now = _now;
    return _expenses
        .where(
          (expense) =>
              expense.date.year == now.year && expense.date.month == now.month,
        )
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  int get expenseCount => _expenses.length;

  List<double> get currentYearMonthlyTotals {
    final totals = List<double>.filled(12, 0);
    final year = currentYear;

    for (final expense in _expenses) {
      if (expense.date.year == year) {
        totals[expense.date.month - 1] += expense.amount;
      }
    }

    return totals;
  }

  Map<String, double> get currentYearCategoryTotals {
    final year = currentYear;
    final totals = <String, double>{};

    for (final expense in _expenses) {
      if (expense.date.year != year) {
        continue;
      }
      final category = expense.category.trim().isEmpty
          ? 'Other'
          : expense.category.trim();
      totals[category] = (totals[category] ?? 0) + expense.amount;
    }

    return totals;
  }

  List<MapEntry<String, double>> get topExpenseItems {
    final totalsByTitle = <String, double>{};

    for (final expense in _expenses) {
      final title = expense.title.trim().isEmpty ? 'Untitled' : expense.title;
      totalsByTitle[title] = (totalsByTitle[title] ?? 0) + expense.amount;
    }

    final sorted = totalsByTitle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).toList();
  }

  Future<void> fetchExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _expenses = await _expenseService.fetchExpenses();
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Failed to fetch expenses';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMonthlySummary() async {
    _error = null;
    notifyListeners();

    try {
      _monthlyTotal = await _expenseService.fetchMonthlySummary();
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Failed to fetch expense summary';
    }

    notifyListeners();
  }

  Future<bool> addExpense(ExpenseModel expense) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _expenseService.addExpense(expense);
      _expenses = [created, ..._expenses];
      await fetchMonthlySummary();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Failed to add expense';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
