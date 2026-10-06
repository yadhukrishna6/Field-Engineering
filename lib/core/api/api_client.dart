import 'api_endpoints.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({this.baseUrl = ApiEndpoints.baseUrl});

  Future<bool> checkHealth() async {
    try {
      return true;
    } catch (_) {
      return false;
    }
  }
}
