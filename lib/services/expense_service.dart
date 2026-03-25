import '../models/expense_model.dart';
import '../services/api_service.dart';

class ExpenseService {
  ExpenseService(this._apiService);

  final ApiService _apiService;

  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    final response = await _apiService.post('/expenses', body: expense.toJson());
    final map = _extractMap(response);
    return ExpenseModel.fromJson(map);
  }

  Future<List<ExpenseModel>> fetchExpenses() async {
    final response = await _apiService.get('/expenses');
    final data = response is List
      ? response
      : (response is Map<String, dynamic>
        ? (response['data'] is List
          ? response['data']
          : (response['data'] is Map<String, dynamic>
            ? response['data']['items']
            : null) ?? response['expenses'])
        : []);

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((item) => ExpenseModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<double> fetchMonthlySummary() async {
    final response = await _apiService.get('/expenses/summary');
    if (response is Map<String, dynamic>) {
      final total = response['monthly_total'] ??
          response['total'] ??
          response['amount'] ??
          (response['data'] is Map<String, dynamic>
              ? (response['data']['monthly_total'] ??
                  response['data']['total'] ??
                  response['data']['amount'])
              : null);

      return double.tryParse((total ?? 0).toString()) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response['data']);
      }
      return response;
    }
    return {};
  }
}
