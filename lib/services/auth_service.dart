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
    required String role,
  }) async {
    final response = await _apiService.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      },
    );

    return _parseAuthResponse(
      response,
      fallbackName: name,
      fallbackEmail: email,
    );
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _apiService.get('/users/me');
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected user response');
    }

    return UserModel.fromJson(response);
  }

  Future<UserModel> updateCurrentUser(Map<String, dynamic> payload) async {
    final response = await _apiService.put('/users/me', body: payload);
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Unexpected user update response');
    }

    final userRaw = response['user'];
    if (userRaw is! Map<String, dynamic>) {
      throw const ApiException('Updated user payload missing');
    }

    return UserModel.fromJson(userRaw);
  }

  Future<void> logout() => _apiService.clearToken();

  Future<void> setToken(String token) => _apiService.setToken(token);

  Future<UserModel> _parseAuthResponse(
    dynamic response, {
    String? fallbackName,
    String? fallbackEmail,
  }) async {
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
      await _apiService.setToken(token);
    }

    return user;
  }
}
