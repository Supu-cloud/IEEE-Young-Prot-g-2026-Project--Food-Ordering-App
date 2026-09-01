import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/session_controller.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

class AppDependencies {
  AppDependencies._({required this.authRepository, required this.session});

  factory AppDependencies.create() {
    final storage = TokenStorage();
    final client = ApiClient(storage);
    return AppDependencies._(
      authRepository: AuthRepository(client.dio),
      session: SessionController(storage),
    );
  }

  final AuthRepository authRepository;
  final SessionController session;
}
