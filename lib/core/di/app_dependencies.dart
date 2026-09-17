import '../../features/operations/data/operations_repository.dart';
import '../../features/auth/domain/user_role.dart';
import '../theme/theme_controller.dart';
import '../localization/language_controller.dart';
import '../../features/owner/data/owner_restaurant_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/session_controller.dart';
import '../../features/customer/data/customer_repository.dart';
import '../../services/auth_service.dart';
import '../../features/admin/data/admin_repository.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

class AppDependencies {
  AppDependencies._({
    required this.client,
    required this.operations,
    required this.authRepository,
    required this.authService,
    required this.customerRepository,
    required this.session,
    required this.adminRepository,
    required this.ownerRestaurantRepository,
  });

  factory AppDependencies.create({required String serverClientId}) {
    final storage = TokenStorage();
    final session = SessionController(storage);
    final client = ApiClient(
      storage,
      onSessionExpired: session.signOut,
      onSessionRefreshed: session.save,
    );
    final ownerRestaurant = OwnerRestaurantRepository(client.dio);
    final operations = OperationsRepository(client.dio, onOrderChanged: ownerRestaurant.refreshOrderMetrics);
    session.validateRole = () async => UserRole.fromApi((await operations.object('/auth/me'))['role'] as String? ?? '');
    return AppDependencies._(
      client: client,
      operations: operations,
      authRepository: AuthRepository(client.dio),
      authService: AuthService(dio: client.dio, serverClientId: serverClientId),
      customerRepository: CustomerRepository(client.dio),
      session: session,
      adminRepository: AdminRepository(client.dio),
      ownerRestaurantRepository: ownerRestaurant,
    );
  }

  final OperationsRepository operations;
  final ApiClient client;
  final AuthRepository authRepository;
  final AuthService authService;
  final CustomerRepository customerRepository;
  final SessionController session;
  final AdminRepository adminRepository;
  final OwnerRestaurantRepository ownerRestaurantRepository;
  late final ThemeController theme = ThemeController(onChanged: (mode) => _syncPreferences(theme: mode.name));
  late final LanguageController language = LanguageController(onChanged: (locale) => _syncPreferences(language: locale.languageCode));
  Future<void> _syncPreferences({String? language, String? theme}) async {
    await client.dio.put('/users/profile', data: {'preferences': {'language': language ?? this.language.locale.languageCode, 'theme': theme ?? this.theme.mode.name}});
  }
}
