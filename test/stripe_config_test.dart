import 'package:flutter_test/flutter_test.dart';
import 'package:food_ordering_app/core/config/stripe_config.dart';

void main() {
  test('mobile configuration accepts only publishable test keys', () {
    expect(StripeConfig.isTestKey('pk_test_fixture'), isTrue);
    for (final value in [
      '',
      'pk_live_fixture',
      'sk_test_fixture',
      'rk_test_fixture',
      'pk_test_',
    ]) {
      expect(StripeConfig.isTestKey(value), isFalse);
    }
  });
}
