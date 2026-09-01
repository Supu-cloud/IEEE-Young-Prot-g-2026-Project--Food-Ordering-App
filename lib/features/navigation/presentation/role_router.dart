import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../auth/domain/user_role.dart';
import 'role_shell.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key, required this.dependencies});
  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    final role = dependencies.session.role;
    if (role == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return switch (role) {
      UserRole.customer => CustomerShell(dependencies: dependencies),
      UserRole.restaurantOwner => OwnerShell(dependencies: dependencies),
      UserRole.deliveryRider => RiderShell(dependencies: dependencies),
    };
  }
}
