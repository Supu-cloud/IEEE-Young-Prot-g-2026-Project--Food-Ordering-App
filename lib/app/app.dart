import 'package:flutter/material.dart';

import '../core/di/app_dependencies.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_role_screen.dart';
import '../features/navigation/presentation/role_router.dart';

class FoodOrderingApp extends StatelessWidget {
  const FoodOrderingApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foodie',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: dependencies.session.isAuthenticated ? '/home' : '/login',
      routes: {
        '/login': (_) => LoginScreen(dependencies: dependencies),
        '/register': (_) => RegisterRoleScreen(dependencies: dependencies),
        '/home': (_) => RoleRouter(dependencies: dependencies),
      },
    );
  }
}
