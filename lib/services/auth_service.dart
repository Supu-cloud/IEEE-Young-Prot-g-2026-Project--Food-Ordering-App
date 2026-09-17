import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/network/api_exception.dart';
import '../features/auth/domain/auth_session.dart';

class AuthService {
  AuthService({
    required Dio dio,
    GoogleSignIn? googleSignIn,
    required String serverClientId,
  }) : _dio = dio,
       _serverClientId = serverClientId,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final Dio _dio;
  final GoogleSignIn _googleSignIn;
  final String _serverClientId;
  Future<void>? _initialization;

  Future<AuthSession> signInWithGoogle() async {
    await (_initialization ??= _googleSignIn.initialize(
      serverClientId: _serverClientId,
    ));

    final googleUser = await _googleSignIn.authenticate();

    final idToken = googleUser.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw const FormatException('Google did not return an ID token.');
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/google',
        data: {'idToken': idToken},
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const FormatException(
          'Google response does not contain session data.',
        );
      }
      return AuthSession.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
