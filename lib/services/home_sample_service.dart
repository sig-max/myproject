import '../models/home_sample_request_model.dart';
import 'api_service.dart';

class HomeSampleService {
  HomeSampleService(this._apiService);

  final ApiService _apiService;

  Future<HomeSampleRequestModel> createRequest({
    required String testName,
    required String preferredDate,
    required String preferredTime,
    required String address,
    required String city,
    required String phone,
    String notes = '',
  }) async {
    final response = await _apiService.post(
      '/home-samples',
      body: {
        'test_name': testName,
        'preferred_date': preferredDate,
        'preferred_time': preferredTime,
        'address': address,
        'city': city,
        'phone': phone,
        'notes': notes,
      },
    );
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected home sample response');
    }
    final item = response['item'];
    if (item is! Map<String, dynamic>) {
      throw const ApiException('Home sample item missing');
    }
    return HomeSampleRequestModel.fromJson(item);
  }

  Future<List<HomeSampleRequestModel>> fetchMyRequests() async {
    final response = await _apiService.get('/home-samples/mine');
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected home sample list response');
    }
    final items = response['items'];
    if (items is! List) {
      return [];
    }
    return items
        .whereType<Map>()
        .map((item) => HomeSampleRequestModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<HomeSampleRequestModel> updateStatus({
    required String requestId,
    required String status,
  }) async {
    final response = await _apiService.put(
      '/home-samples/$requestId/status',
      body: {'status': status},
    );
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected home sample update response');
    }
    final item = response['item'];
    if (item is! Map<String, dynamic>) {
      throw const ApiException('Updated home sample item missing');
    }
    return HomeSampleRequestModel.fromJson(item);
  }
}
