class ApiConfig {
  const ApiConfig._();

  static const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _productionBaseUrl =
      'https://sistemmanajemendangamifikasi-production.up.railway.app/api';

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) return _normalizeBaseUrl(_definedBaseUrl);
    return _productionBaseUrl;
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
