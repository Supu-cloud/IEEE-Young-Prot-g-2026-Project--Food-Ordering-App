import '../../../core/storage/token_storage.dart';
import 'auth_session.dart';
import 'user_role.dart';

class SessionController {
  SessionController(this._storage);
  final TokenStorage _storage;

  UserRole? role;
  bool get isAuthenticated => role != null;

  Future<void> restore() async {
    final token = await _storage.readAccessToken();
    final storedRole = await _storage.readRole();
    if (token != null && token.isNotEmpty && storedRole != null) {
      role = UserRole.fromApi(storedRole);
    }
  }

  Future<void> save(AuthSession session) async {
    await _storage.saveSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      role: session.role.apiValue,
    );
    role = session.role;
  }

  Future<void> signOut() async {
    await _storage.clear();
    role = null;
  }
}
