import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _roleKey = 'user_role';

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);
  Future<String?> readRole() => _storage.read(key: _roleKey);

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String role,
  }) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
      _storage.write(key: _roleKey, value: role),
    ]);
  }

  Future<void> clear() => _storage.deleteAll();
}
