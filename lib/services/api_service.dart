import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../utils/constants.dart';

class ApiService {
  String? _token;
  SharedPreferences? _prefs;

  Future<dynamic> get(String path) => _request('GET', path);

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) =>
      _request('POST', path, body: body);

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) =>
      _request('PUT', path, body: body);

  Future<dynamic> delete(String path, {Map<String, dynamic>? body}) =>
      _request('DELETE', path, body: body);

  Future<void> setToken(String token) async {
    _token = token;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(AppConstants.tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(AppConstants.tokenKey);
  }

  Future<void> _ensureTokenLoaded() async {
    if (_token != null) {
      return;
    }

    _prefs ??= await SharedPreferences.getInstance();
    _token = _prefs!.getString(AppConstants.tokenKey);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    await _ensureTokenLoaded();

    final uri = Uri.parse('${ApiConfig.apiV1}$path');
    if (kDebugMode) {
      debugPrint('API URL: $uri');
    }
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if ((_token ?? '').isNotEmpty) 'Authorization': 'Bearer $_token',
    };

    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(
                const Duration(seconds: 30),
              );
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 30));
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 30));
          break;
        case 'DELETE':
          response = await http
              .delete(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(const Duration(seconds: 30));
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }
    } on TimeoutException {
      throw const ApiException('Request timeout. Please try again.');
    } on http.ClientException catch (error) {
      throw ApiException('Network error: ${error.message}');
    }

    return _parseResponse(response);
  }

  dynamic _parseResponse(http.Response response) {
    final statusCode = response.statusCode;
    final rawBody = response.body.trim();
    if (kDebugMode) {
      debugPrint('Response: ${response.body}');
    }

    dynamic decoded;
    if (rawBody.isEmpty) {
      decoded = <String, dynamic>{};
    } else {
      try {
        decoded = jsonDecode(rawBody);
      } catch (_) {
        decoded = rawBody;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    }

    if (statusCode == 401) {
      _token = null;
    }

    throw ApiException(
      _extractErrorMessage(decoded) ??
          'Request failed with status code $statusCode',
      statusCode: statusCode,
    );
  }

  String? _extractErrorMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'] ??
          decoded['error'] ??
          decoded['detail'] ??
          decoded['description'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    if (decoded is String && decoded.trim().isNotEmpty) {
      return decoded;
    }

    return null;
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'ApiException(statusCode: ${statusCode ?? '-'}, message: $message)';
}