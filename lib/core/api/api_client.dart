import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ApiResponse<T> {
  final bool isSuccess;
  final int statusCode;
  final T? data;
  final String? errorMessage;

  const ApiResponse({
    required this.isSuccess,
    required this.statusCode,
    this.data,
    this.errorMessage,
  });

  factory ApiResponse.success(T data, {int statusCode = 200}) {
    return ApiResponse(isSuccess: true, statusCode: statusCode, data: data);
  }

  factory ApiResponse.error(String message, {int statusCode = 500}) {
    return ApiResponse(isSuccess: false, statusCode: statusCode, errorMessage: message);
  }
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _authToken;
  bool _mockCloudFallback = true;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void setMockCloudFallback(bool enabled) {
    _mockCloudFallback = enabled;
  }

  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<ApiResponse<Map<String, dynamic>>> get(String url) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(uri);
      
      _buildHeaders().forEach((key, value) {
        request.headers.set(key, value);
      });

      final response = await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
        return ApiResponse.success(decoded, statusCode: response.statusCode);
      } else {
        if (_mockCloudFallback) {
          return _handleMockFallbackGet(url);
        }
        return ApiResponse.error(
          'Server returned code ${response.statusCode}: $responseBody',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (_mockCloudFallback) {
        return _handleMockFallbackGet(url);
      }
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> post(String url, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final request = await client.postUrl(uri);
      
      _buildHeaders().forEach((key, value) {
        request.headers.set(key, value);
      });

      final encodedBody = utf8.encode(jsonEncode(body));
      request.add(encodedBody);

      final response = await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
        return ApiResponse.success(decoded, statusCode: response.statusCode);
      } else {
        if (_mockCloudFallback) {
          return _handleMockFallbackPost(url, body);
        }
        return ApiResponse.error(
          'Server returned code ${response.statusCode}: $responseBody',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (_mockCloudFallback) {
        return _handleMockFallbackPost(url, body);
      }
      return ApiResponse.error('Network error: $e');
    }
  }

  ApiResponse<Map<String, dynamic>> _handleMockFallbackGet(String url) {
    // Cloud sync simulation for testing & offline field emulation
    if (url.contains('/sync/pull')) {
      return ApiResponse.success({
        'serverTimestamp': DateTime.now().toIso8601String(),
        'projects': [],
        'drawings': [],
        'revisions': [],
        'markups': [],
        'measurements': [],
        'issues': [],
        'inspections': [],
        'equipment': [],
      });
    }
    return ApiResponse.success({'status': 'ok', 'mock': true});
  }

  ApiResponse<Map<String, dynamic>> _handleMockFallbackPost(String url, Map<String, dynamic> body) {
    if (url.contains('/sync/push')) {
      final ops = (body['operations'] as List<dynamic>?) ?? [];
      final appliedIds = ops.map((e) => (e as Map<String, dynamic>)['id'] as String).toList();
      return ApiResponse.success({
        'serverTimestamp': DateTime.now().toIso8601String(),
        'appliedOperationIds': appliedIds,
        'conflicts': [],
      });
    }
    return ApiResponse.success({'status': 'ok', 'mock': true});
  }
}
