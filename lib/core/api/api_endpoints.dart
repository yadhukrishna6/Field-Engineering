class ApiEndpoints {
  static const String baseUrl = 'http://localhost:8080/api/v1';

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String currentUser = '$baseUrl/auth/me';

  // Projects
  static const String projects = '$baseUrl/projects';
  static String projectById(String id) => '$baseUrl/projects/$id';

  // Drawings
  static const String drawings = '$baseUrl/drawings';
  static String drawingById(String id) => '$baseUrl/drawings/$id';
  static String drawingRevisions(String drawingId) => '$baseUrl/drawings/$drawingId/revisions';

  // Markups & Measurements
  static const String markups = '$baseUrl/markups';
  static const String measurements = '$baseUrl/measurements';

  // Issues & Inspections
  static const String issues = '$baseUrl/issues';
  static const String inspections = '$baseUrl/inspections';
  static const String equipment = '$baseUrl/equipment';

  // Media
  static const String photos = '$baseUrl/photos';
  static const String voiceNotes = '$baseUrl/voice-notes';

  // Sync Batch
  static const String syncPush = '$baseUrl/sync/push';
  static const String syncPull = '$baseUrl/sync/pull';

  // Reports & Audit
  static const String reports = '$baseUrl/reports';
  static const String auditLogs = '$baseUrl/audit-logs';
}
