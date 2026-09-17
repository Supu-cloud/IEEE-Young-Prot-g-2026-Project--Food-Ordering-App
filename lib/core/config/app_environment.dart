enum AppEnvironment { development, staging, production }

class AppConfig {
  const AppConfig._();

  static const environmentName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static AppEnvironment get environment => switch (environmentName) {
        'production' => AppEnvironment.production,
        'staging' => AppEnvironment.staging,
        _ => AppEnvironment.development,
      };

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://young-prot-g-backend-repository-production.up.railway.app/api',
  );
}
