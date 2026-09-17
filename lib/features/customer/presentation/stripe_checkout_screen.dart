import 'package:flutter/material.dart';
import '../../../core/config/stripe_config.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// The only gateway presentation path. Orders are confirmed separately by Express.
Future<void> presentFoodiePayment(
  Map<String, dynamic> attempt,
  Brightness brightness,
) async {
  try {
    await StripeConfig.initialize();
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: attempt['clientSecret'] as String,
        merchantDisplayName: 'Foodie',
        returnURL: 'foodie://stripe-redirect',
        allowsDelayedPaymentMethods: false,
        style: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      ),
    );
    await Stripe.instance.presentPaymentSheet();
  } on StripeException catch (error) {
    throw StateError(
      error.error.code == FailureCode.Canceled
          ? 'Payment cancelled. Your cart is saved; you can retry in Wallet.'
          : error.error.localizedMessage ??
                error.error.message ??
                'The payment gateway could not complete the payment. Please retry.',
    );
  }
}
