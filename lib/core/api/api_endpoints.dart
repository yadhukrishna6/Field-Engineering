class ApiEndpoints {
  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081/api/v1',
  );

  /// Automatically ensures /api/v1 is appended even if the user provides just the domain
  static final String baseUrl = _normalizeBaseUrl(_rawBaseUrl);

  static String _normalizeBaseUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.endsWith('/api/v1')) return trimmed;
    return '$trimmed/api/v1';
  }

  // Drawings Endpoints
  static String get drawings => '$baseUrl/drawings';
  static String drawingById(String id) => '$drawings/$id';
  static String drawingFile(String id) => '$drawings/$id/file';
  static String pageMarkup(String id, int page) => '$drawings/$id/pages/$page/markup';

  /// Resolves relative URLs to the backend host origin
  static String resolveUrl(String path) {
    if (path.startsWith('http')) return path;
    final uri = Uri.parse(baseUrl);
    final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$origin$cleanPath';
  }
}
