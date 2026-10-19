import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'api_endpoints.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({this.baseUrl = ApiEndpoints.baseUrl});

  Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/projects')).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> uploadDrawing({
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.drawings);
      final request = http.MultipartRequest('POST', uri);
      request.fields['name'] = fileName;

      if (fileBytes != null && fileBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: fileName,
          ),
        );
      } else if (filePath != null && filePath.isNotEmpty && !kIsWeb) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            filePath,
            filename: fileName,
          ),
        );
      } else {
        debugPrint('[ApiClient] No file data provided for upload');
        return null;
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[ApiClient] Drawing uploaded successfully: ${data['id']}');
        return data;
      } else {
        debugPrint('[ApiClient] Upload failed with HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[ApiClient] Upload error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getDrawings() async {
    try {
      final res = await http.get(Uri.parse(ApiEndpoints.drawings)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body) as List;
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint('[ApiClient] getDrawings error: $e');
    }
    return [];
  }

  Future<bool> deleteDrawing(String id) async {
    try {
      final res = await http.delete(Uri.parse(ApiEndpoints.drawingById(id))).timeout(const Duration(seconds: 4));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('[ApiClient] deleteDrawing error: $e');
      return false;
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});


