import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_session.dart';
import 'user_role.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._storage);

  final TokenStorage _storage;

  UserRole? role;
  Future<UserRole> Function()? validateRole;
  String? validationError;

  bool get isAuthenticated => role != null;

  Future<void> restore() async {
    final token = await _storage.readAccessToken();
    final storedRole = await _storage.readRole();

    if (token == null || token.isEmpty) {
      return;
    }

    validationError = null;

    try {
      if (validateRole != null) {
        role = await validateRole!();
      } else {
        role = UserRole.fromApi(storedRole ?? '');
      }

      await _storage.saveRole(role!.apiValue);
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await signOut();
        return;
      }

      // Keep saved credentials, but do not allow entry into a privileged
      // dashboard until the session can be verified successfully.
      validationError = error.message;
    } on FormatException {
      await signOut();
      return;
    } catch (_) {
      validationError =
          'Unable to verify your session. Please retry.';
    }

    notifyListeners();
  }

  Future<void> save(AuthSession session) async {
    await _storage.saveSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      role: session.role.apiValue,
    );

    validationError = null;
    role = session.role;

    notifyListeners();
  }

  Future<void> signOut() async {
    await _storage.clear();

    validationError = null;
    role = null;

    notifyListeners();
  }
}