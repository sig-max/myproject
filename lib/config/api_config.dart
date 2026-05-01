import 'package:flutter/foundation.dart';

import 'flavor_config.dart';

class ApiConfig {
  static const String _renderBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://myproject-xfbc.onrender.com',
  );

  static const String apiBaseUrl = _renderBaseUrl;
  static const String apiV1Local = '$apiBaseUrl/api/v1';

  static const String _overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    switch (FlavorConfig.flavor) {
      case AppFlavor.prod:
        return _renderBaseUrl;
      case AppFlavor.dev:
        // Keep the emulator host for local development.
        return kIsWeb ? apiBaseUrl : 'http://10.0.2.2:5000';
    }
  }

  static String get apiV1 => '$baseUrl/api/v1';
}
