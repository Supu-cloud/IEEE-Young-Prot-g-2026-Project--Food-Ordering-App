import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../auth/domain/user_role.dart';
import 'role_shell.dart';
import '../../admin/presentation/admin_shell.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key, required this.dependencies});
  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: dependencies.session, builder: (context, _) {
    if (dependencies.session.validationError != null) return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(dependencies.session.validationError!), FilledButton(onPressed: dependencies.session.restore, child: const Text('Retry session')), TextButton(onPressed: dependencies.session.signOut, child: const Text('Sign out'))])));
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
      UserRole.admin => AdminShell(dependencies: dependencies),
    };
  });
}
