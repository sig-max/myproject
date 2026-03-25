import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthService {
  AuthService(this._apiService);

  final ApiService _apiService;

  Future<UserModel> login({required String email, required String password}) async {
    final response = await _apiService.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    return _parseAuthResponse(response);
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
    );

    return _parseAuthResponse(response, fallbackName: name, fallbackEmail: email);
  }

  Future<void> logout() => _apiService.clearToken();

  Future<void> setToken(String token) => _apiService.setToken(token);

  UserModel _parseAuthResponse(
    dynamic response, {
    String? fallbackName,
    String? fallbackEmail,
  }) {
    Map<String, dynamic> map;
    if (response is Map<String, dynamic>) {
      map = response;
    } else {
      throw const ApiException('Unexpected authentication response');
    }

    final token = (map['token'] ?? map['access_token'] ?? map['jwt'])?.toString();
    final userRaw = map['user'];
    final userMap = userRaw is Map<String, dynamic> ? userRaw : <String, dynamic>{};

    final user = UserModel.fromJson({
      ...userMap,
      'name': userMap['name'] ?? fallbackName ?? 'User',
      'email': userMap['email'] ?? fallbackEmail ?? '',
      if (token != null) 'token': token,
    });

    if (token != null && token.isNotEmpty) {
      _apiService.setToken(token);
    }

    return user;
  }
}
