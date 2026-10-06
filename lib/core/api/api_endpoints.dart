class ApiEndpoints {
  static const String baseUrl = 'http://localhost:8080/api/v1';

  // Drawings Endpoints
  static const String drawings = '$baseUrl/drawings';
  static String drawingById(String id) => '$drawings/$id';
  static String drawingFile(String id) => '$drawings/$id/file';
  static String pageMarkup(String id, int page) => '$drawings/$id/pages/$page/markup';
}
