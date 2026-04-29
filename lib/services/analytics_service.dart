import '../models/specialist_analytics_model.dart';
import 'api_service.dart';

class AnalyticsService {
  AnalyticsService(this._apiService);

  final ApiService _apiService;

  Future<SpecialistAnalyticsModel> fetchSpecialistAnalytics() async {
    final response = await _apiService.get('/analytics/specialist/me');
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected analytics response');
    }
    return SpecialistAnalyticsModel.fromJson(response);
  }
}
