import 'package:flutter/foundation.dart';

import 'flavor_config.dart';

class ApiConfig {
  static const String apiBaseUrl = 'http://localhost:5000';
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
        return 'https://your-production-domain.com';
      case AppFlavor.dev:
        // Web cannot reach Android emulator loopback (10.0.2.2).
        // Use localhost on web and keep emulator host for mobile dev.
        return kIsWeb ? apiBaseUrl : 'http://10.0.2.2:5000';
    }
  }

  static String get apiV1 => '$baseUrl/api/v1';
}
