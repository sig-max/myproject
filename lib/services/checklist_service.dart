import '../models/checklist_model.dart';
import '../services/api_service.dart';

class ChecklistService {
  ChecklistService(this._apiService);

  final ApiService _apiService;

  Future<List<ChecklistModel>> fetchTodayChecklist() async {
    final response = await _apiService.get('/intake-logs/today');
    final data = response is List
        ? response
        : (response is Map<String, dynamic>
            ? response['data'] ?? response['checklist'] ?? response['logs']
            : []);

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((item) => ChecklistModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> markMedicineTaken(String medicineId) async {
    await _apiService.post(
      '/intake-logs',
      body: {
        'medicine_id': medicineId,
        'medicineId': medicineId,
        'taken_at': DateTime.now().toIso8601String(),
        'date': DateTime.now().toIso8601String(),
      },
    );
  }
}
