import 'package:flutter/material.dart';

import 'app/foodie_startup.dart';
import 'core/config/stripe_config.dart';
import 'core/di/app_dependencies.dart';

// 1. Google Cloud Console හි ඇති WEB Client ID එක මෙතැනට යොදන්න
const String _googleWebClientId =
    '414573498143-3lqq4na92dnos65ik9r9tda9rcjo4are.apps.googleusercontent.com';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppDependencies.create(
    serverClientId: _googleWebClientId,
  );
  runApp(
    FoodieStartup(
      dependencies: dependencies,
      initialize: () async {
        await Future.wait([
          dependencies.theme.restore(),
          dependencies.language.restore(),
          dependencies.session.restore(),
          _initializePayments(),
        ]);
      },
    ),
  );
}

Future<void> _initializePayments() async {
  if (StripeConfig.configured) {
    try {
      await StripeConfig.initialize();
    } catch (_) {
      // Retry at payment time; browsing remains available.
      debugPrint('Stripe initialization failed; Wallet will retry.');
    }
  }
}
