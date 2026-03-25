import '../models/medicine_model.dart';
import '../services/api_service.dart';

class MedicineService {
  MedicineService(this._apiService);

  final ApiService _apiService;

  Future<List<MedicineModel>> fetchMedicines() async {
    final response = await _apiService.get('/medicines');
    final data = _extractList(response);

    return data
        .whereType<Map>()
        .map((item) => MedicineModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        return data;
      }

      if (data is Map<String, dynamic> && data['items'] is List) {
        return List<dynamic>.from(data['items'] as List);
      }

      if (response['medicines'] is List) {
        return List<dynamic>.from(response['medicines'] as List);
      }
    }

    return const [];
  }

  Future<MedicineModel> addMedicine(MedicineModel medicine) async {
    final response = await _apiService.post('/medicines', body: medicine.toJson());
    final map = _extractMap(response);
    return MedicineModel.fromJson(map);
  }

  Future<MedicineModel> updateMedicine(MedicineModel medicine) async {
    final response = await _apiService.put('/medicines/${medicine.id}', body: medicine.toJson());
    final map = _extractMap(response);
    return MedicineModel.fromJson(map);
  }

  Future<void> deleteMedicine(String id) async {
    await _apiService.delete('/medicines/$id');
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
