import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) return _normalizeBaseUrl(_definedBaseUrl);

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }

    return 'http://127.0.0.1:8000/api';
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(trimmed);

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return trimmed;
    }

    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (path.isEmpty || path == '/') {
      return uri.replace(path: '/api').toString();
    }

    if (path == '/ap') {
      return uri.replace(path: '/api').toString();
    }

    return trimmed;
  }

  static String publicStorageUrl(String? pathOrUrl) {
    final value = pathOrUrl?.trim() ?? '';
    if (value.isEmpty) return '';

    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) return value;

    final apiUri = Uri.parse(baseUrl);
    var basePath = apiUri.path.replaceFirst(RegExp(r'/api/?$'), '');
    basePath = basePath.replaceFirst(RegExp(r'/+$'), '');
    final iconPath = value.replaceFirst(RegExp(r'^/+'), '');

    return apiUri
        .replace(path: '$basePath/storage/$iconPath', query: null, fragment: null)
        .toString();
  }
}
