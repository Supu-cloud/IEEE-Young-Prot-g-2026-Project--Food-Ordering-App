import '../features/auth/domain/user_role.dart';
import 'package:flutter/material.dart';

import '../core/di/app_dependencies.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_role_screen.dart';
import '../features/navigation/presentation/role_router.dart';

class FoodOrderingApp extends StatefulWidget {
  const FoodOrderingApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<FoodOrderingApp> createState() => _FoodOrderingAppState();
}

class _FoodOrderingAppState extends State<FoodOrderingApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  UserRole? _lastRole;
  AppDependencies get dependencies => widget.dependencies;

  @override
  void initState() {
    super.initState();
    _lastRole = dependencies.session.role;
    dependencies.session.addListener(_sessionChanged);
  }

  void _sessionChanged() {
    final previous = _lastRole;
    _lastRole = dependencies.session.role;
    if (dependencies.session.validationError != null) return;
    if (!dependencies.session.isAuthenticated) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (_) => false,
      );
    } else if (previous != null && previous != _lastRole) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (_) => false);
    }
  }

  @override
  void dispose() {
    dependencies.session.removeListener(_sessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([dependencies.theme, dependencies.language]),
      builder: (context, _) => MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Foodie',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: dependencies.theme.mode,
        locale: dependencies.language.locale,
        supportedLocales: supportedLanguages,
        localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        builder: (context, child) => ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          // Protect every route, including pushed detail screens. App bars
          // handle the top inset; SafeArea consumes the other insets once.
          child: SafeArea(top: false, child: child ?? const SizedBox.shrink()),
        ),
        initialRoute: dependencies.session.isAuthenticated || dependencies.session.validationError != null ? '/home' : '/login',
        routes: {
          '/login': (_) => LoginScreen(dependencies: dependencies),
          '/register': (_) => RegisterRoleScreen(dependencies: dependencies),
          '/home': (_) => RoleRouter(dependencies: dependencies),
        },
      ),
    );
  }
}
