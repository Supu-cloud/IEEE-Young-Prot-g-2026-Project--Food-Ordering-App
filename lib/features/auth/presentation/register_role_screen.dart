import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/user_role.dart';
import 'auth_scaffold.dart';
import 'registration_screen.dart';

class RegisterRoleScreen extends StatelessWidget {
  const RegisterRoleScreen({super.key, required this.dependencies});
  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: 'Create Account',
        subtitle: 'Choose how you will use Foodie. You can always sign in from the shared login screen.',
        showBackButton: true,
        child: Column(children: [
          _RoleOption(
            role: UserRole.customer,
            icon: Icons.shopping_bag_outlined,
            description: 'Discover restaurants, order meals and track deliveries.',
            dependencies: dependencies,
          ),
          const SizedBox(height: 14),
          _RoleOption(
            role: UserRole.restaurantOwner,
            icon: Icons.storefront_outlined,
            description: 'Apply to manage your restaurant, menu and incoming orders.',
            dependencies: dependencies,
          ),
          const SizedBox(height: 14),
          _RoleOption(
            role: UserRole.deliveryRider,
            icon: Icons.delivery_dining_outlined,
            description: 'Apply to accept deliveries and manage your daily route.',
            dependencies: dependencies,
          ),
        ]),
      );
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({required this.role, required this.icon, required this.description, required this.dependencies});
  final UserRole role;
  final IconData icon;
  final String description;
  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RegistrationScreen(role: role, dependencies: dependencies)),
        ),
        child: AppCard(
          child: Row(children: [
            CircleAvatar(radius: 25, child: Icon(icon)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(role.label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ])),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      );
}
