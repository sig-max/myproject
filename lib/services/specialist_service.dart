import '../models/user_model.dart';
import 'api_service.dart';

class SpecialistService {
  SpecialistService(this._apiService);

  final ApiService _apiService;

  Future<List<UserModel>> fetchSpecialists({
    String specialization = '',
    String city = '',
    String language = '',
    String minFee = '',
    String maxFee = '',
  }) async {
    final query = <String, String>{};
    if (specialization.trim().isNotEmpty) {
      query['specialization'] = specialization.trim();
    }
    if (city.trim().isNotEmpty) {
      query['city'] = city.trim();
    }
    if (language.trim().isNotEmpty) {
      query['language'] = language.trim();
    }
    if (minFee.trim().isNotEmpty) {
      query['min_fee'] = minFee.trim();
    }
    if (maxFee.trim().isNotEmpty) {
      query['max_fee'] = maxFee.trim();
    }

    final suffix = query.isEmpty
        ? ''
        : '?${Uri(queryParameters: query).query}';

    final response = await _apiService.get('/users/specialists$suffix');
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected specialist response');
    }

    final items = response['items'];
    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map>()
        .map((item) => UserModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
