import 'package:flutter_stripe/flutter_stripe.dart';

/// Only a publishable TEST key may be included in the mobile build.
class StripeConfig {
  static const publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
  );
  static bool isTestKey(String key) =>
      RegExp(r'^pk_test_[A-Za-z0-9]+$').hasMatch(key.trim());
  static bool get configured => isTestKey(publishableKey);
  static Future<void>? _initialization;

  static Future<void> initialize() async {
    if (!configured) {
      throw StateError(
        'Stripe TEST payments need STRIPE_PUBLISHABLE_KEY. '
        'Restart using scripts/build-sandbox.ps1 -Run, or rebuild with '
        '--dart-define=STRIPE_PUBLISHABLE_KEY=<your test publishable key>.',
      );
    }
    try {
      await (_initialization ??= _apply());
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  static Future<void> _apply() async {
    Stripe.publishableKey = publishableKey.trim();
    Stripe.urlScheme = 'foodie';
    await Stripe.instance.applySettings();
  }
}
