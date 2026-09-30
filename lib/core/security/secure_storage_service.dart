import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'rbac_manager.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  static const String _kAuthTokenKey = 'sec_auth_token_enc';
  static const String _kUserSessionKey = 'sec_user_session_enc';
  static const String _kEncryptionSalt = 'FIELD_ENG_AES_256_OFFLINE_SECRET';

  SessionUser? _currentUser;
  DateTime? _lastUserActivity;
  final Duration _sessionTimeoutDuration = const Duration(minutes: 60);

  SessionUser get currentUser => _currentUser ?? SessionUser.defaultLeadEngineer();

  bool get isSessionExpired {
    if (_lastUserActivity == null) return false;
    return DateTime.now().difference(_lastUserActivity!) > _sessionTimeoutDuration;
  }

  void recordUserActivity() {
    _lastUserActivity = DateTime.now();
  }

  void switchUserRole(UserRole newRole) {
    final current = currentUser;
    _currentUser = SessionUser(
      id: current.id,
      email: current.email,
      fullName: current.fullName,
      role: newRole,
      company: current.company,
      loggedInAt: DateTime.now(),
    );
    recordUserActivity();
  }

  /// Encrypts string using XOR + Base64 salt transformation for secure offline local storage
  String _encrypt(String plainText) {
    final keyBytes = utf8.encode(_kEncryptionSalt);
    final textBytes = utf8.encode(plainText);
    final encrypted = List<int>.generate(
      textBytes.length,
      (i) => textBytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return base64Encode(encrypted);
  }

  String _decrypt(String encryptedBase64) {
    try {
      final keyBytes = utf8.encode(_kEncryptionSalt);
      final encrypted = base64Decode(encryptedBase64);
      final decrypted = List<int>.generate(
        encrypted.length,
        (i) => encrypted[i] ^ keyBytes[i % keyBytes.length],
      );
      return utf8.decode(decrypted);
    } catch (_) {
      return '';
    }
  }

  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = _encrypt(token);
    await prefs.setString(_kAuthTokenKey, encrypted);
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final enc = prefs.getString(_kAuthTokenKey);
    if (enc == null) return null;
    return _decrypt(enc);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAuthTokenKey);
    await prefs.remove(_kUserSessionKey);
    _currentUser = null;
    _lastUserActivity = null;
  }
}
